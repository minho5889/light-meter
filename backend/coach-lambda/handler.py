"""
AI Lighting Coach proxy — AWS Lambda (Python 3.12+).

Holds the cloud credentials (via the Lambda's IAM role) and calls Amazon
Bedrock so the iOS app never ships a key. Contract matches the app's
`RemoteLightingCoachService`:

  POST  { "image_base64": <jpeg b64 | null>, "lux": <number>,
          "kelvin": <number>, "language": "en" | "ko" | "fr" }
  200   { "headline": <string>, "tips": [<string>, ...] }

Model is chosen by the BEDROCK_MODEL_ID env var. Because this uses the
model-agnostic Converse API, switching Nova <-> Claude is just changing that id:
  - Amazon Nova 2 Lite : "us.amazon.nova-2-lite-v1:0"   (confirm the exact
    inference-profile id in your region's Bedrock console)
  - Claude (quality)   : e.g. "us.anthropic.claude-sonnet-4-..." (your enabled id)

Deploy: see README.md. NOTE: written as reference; validate on first deploy
(model id + region + that model access is enabled in Bedrock).
"""

import base64
import json
import os
import re

import boto3

REGION = os.environ.get("BEDROCK_REGION", os.environ.get("AWS_REGION", "us-east-1"))
MODEL_ID = os.environ.get("BEDROCK_MODEL_ID", "us.amazon.nova-2-lite-v1:0")

_bedrock = boto3.client("bedrock-runtime", region_name=REGION)

_LANG = {"en": "English", "ko": "Korean", "fr": "French"}

# Lambda Function URLs cap the request body at ~6 MB; the app sends a 1024px
# JPEG (tens of KB). Reject anything far larger as likely abuse before paying
# the base64 decode + Bedrock inference cost.
_MAX_IMAGE_B64 = 3_000_000  # base64 characters (~2.25 MB decoded)


def _num(value, lo, hi):
    """Coerce a client-supplied value into a number clamped to [lo, hi].

    Returns 0.0 for missing / non-numeric / NaN input so a malformed request
    can never crash the handler or reach the model as garbage.
    """
    try:
        n = float(value)
    except (TypeError, ValueError):
        return 0.0
    if n != n:  # NaN
        return 0.0
    return max(lo, min(hi, n))

_SYSTEM_ROOM = (
    "You are an expert lighting consultant inside a phone light-meter app. "
    "You are given a photo of a room plus precise measurements. Give brief, "
    "practical, friendly advice about the lighting for everyday activities "
    "(reading, working, relaxing, dining, winding down for sleep). Reason about "
    "brightness in lux, color temperature in Kelvin (lower = warmer), and what "
    "you can actually see in the photo. "
    "Respond with STRICT JSON only: "
    '{"vibe": string, "emoji": string, "headline": string, "tips": [string, ...]}. '
    'vibe = a short, trendy aesthetic name for the light in English (e.g. '
    '"Golden Hour Glow", "Clean Girl Daylight", "Cozy Cabincore", "Moody Midnight", '
    '"Main Character Energy"). emoji = one emoji matching the vibe. '
    "headline = one short verdict (max ~8 words). tips = 1-3 short, specific, "
    "actionable suggestions. No markdown, no prose outside the JSON."
)

_SYSTEM_SELFIE = (
    "You are an expert lighting coach for selfies, OOTD photos and video content. "
    "You are given a photo plus precise measurements. Rate how flattering the "
    "light is for the person/scene on camera and how to improve it. Flattering "
    "light is soft, fairly bright (~200–1000 lux) and neutral-to-warm "
    "(~2700–5500K); harsh, dim or very blue light scores lower. "
    "Respond with STRICT JSON only: "
    '{"vibe": string, "emoji": string, "score": integer, "headline": string, "tips": [string, ...]}. '
    "score = 0–100 lighting-for-content rating. vibe = a short trendy aesthetic "
    "name in English. emoji = one matching emoji. headline = short verdict "
    "(max ~8 words). tips = 1-3 creator-focused suggestions (e.g. face a window, "
    "add a ring light, warm it up, diffuse the source). No markdown, JSON only."
)


def _response(status, body):
    return {
        "statusCode": status,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body),
    }


def handler(event, _context):
    # Lambda Function URL / API Gateway both deliver the JSON in event["body"].
    try:
        raw = event.get("body") or "{}"
        if event.get("isBase64Encoded"):
            raw = base64.b64decode(raw).decode("utf-8")
        req = json.loads(raw)
    except Exception:
        return _response(400, {"error": "invalid request body"})

    lux = _num(req.get("lux"), lo=0, hi=200_000)
    kelvin = _num(req.get("kelvin"), lo=0, hi=20_000)
    language = _LANG.get(req.get("language", "en"), "English")
    image_b64 = req.get("image_base64")
    mode = req.get("mode", "room")
    system_prompt = _SYSTEM_SELFIE if mode == "selfie" else _SYSTEM_ROOM

    content = []
    if isinstance(image_b64, str) and image_b64:
        if len(image_b64) > _MAX_IMAGE_B64:
            print(f"image rejected: {len(image_b64)} base64 chars exceeds cap")
        else:
            try:
                content.append(
                    {"image": {"format": "jpeg", "source": {"bytes": base64.b64decode(image_b64)}}}
                )
            except Exception:
                pass  # advise from numbers alone if the image is unusable
    content.append(
        {
            "text": (
                f"Measurements: {round(lux)} lux, {round(kelvin)}K. "
                f"Write the headline and tips in {language}. Return the JSON now."
            )
        }
    )

    try:
        out = _bedrock.converse(
            modelId=MODEL_ID,
            system=[{"text": system_prompt}],
            messages=[{"role": "user", "content": content}],
            inferenceConfig={"maxTokens": 400, "temperature": 0.4},
        )
        text = out["output"]["message"]["content"][0]["text"]
    except Exception as exc:  # noqa: BLE001
        # Log the real error to CloudWatch; return a generic message so we don't
        # leak Bedrock internals (model id, region, throttle state) to clients.
        print(f"bedrock converse failed: {exc}")
        return _response(502, {"error": "lighting service unavailable"})

    # Be lenient: pull the first {...} block in case the model adds stray text.
    match = re.search(r"\{.*\}", text, re.S)
    try:
        parsed = json.loads(match.group(0) if match else text)
        vibe = str(parsed.get("vibe", "Your Light")).strip()[:40]
        emoji = str(parsed.get("emoji", "✨")).strip()[:8]
        headline = str(parsed.get("headline", "")).strip()[:120]
        tips = [str(t).strip() for t in parsed.get("tips", []) if str(t).strip()][:4]
        score = parsed.get("score")
        score = int(score) if isinstance(score, (int, float)) else None
    except Exception:
        vibe, emoji, headline, tips, score = "Your Light", "✨", text.strip()[:120], [], None

    result = {"vibe": vibe, "emoji": emoji, "headline": headline, "tips": tips}
    if score is not None:
        result["score"] = max(0, min(100, score))
    return _response(200, result)
