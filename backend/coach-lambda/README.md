# AI Lighting Coach — Bedrock proxy (Lambda)

A tiny AWS Lambda that the iOS app calls so the app never holds a cloud key.
It forwards the snapshot + readings to Amazon Bedrock and returns the advice.

**Contract** (matches `RemoteLightingCoachService` in the app):

```
POST  { "image_base64": <jpeg base64 | null>, "lux": <number>,
        "kelvin": <number>, "language": "en" | "ko" | "fr",
        "mode": "room" | "selfie" }
200   { "vibe": <string>, "emoji": <string>, "headline": <string>,
        "tips": [<string>, ...], "score": <int 0–100, selfie mode only> }
```

`vibe` + `emoji` power the shareable Light Vibe card; `headline` + `tips` are the
advice. `mode:"selfie"` switches the system prompt to a content-creator rating
and adds `score` (lighting-for-selfies, 0–100).

## Deploy (one-time, ~15 min)

1. **Enable model access** in the Bedrock console (your region) for **Amazon
   Nova 2 Lite** (or a Claude model). Copy its exact *inference-profile* model
   id (e.g. `us.amazon.nova-2-lite-v1:0`).
2. **Create the Lambda** (Python 3.12, `handler.handler`), paste `handler.py`.
   `boto3` is already in the Lambda runtime — no dependencies to package.
   - Memory 512 MB, timeout 30 s.
   - Env vars: `BEDROCK_MODEL_ID` = the id from step 1; `BEDROCK_REGION` =
     your Bedrock region (if different from the Lambda's).
3. **IAM**: add `bedrock:InvokeModel` to the function's execution role, scoped to
   that model ARN.
4. **Expose it**: enable a **Lambda Function URL** (Auth: NONE for a quick
   start, or IAM/JWT for production) → copy the `https://….lambda-url.…` URL.
5. **Point the app at it**: set the `lm_coach_endpoint` UserDefault to that URL
   (add a field in `RegularSettingsSheet`, or for a quick test:
   `xcrun simctl spawn <udid> defaults write com.lightmeter.LightMeter lm_coach_endpoint <url>`).
   With it set, the app uses `RemoteLightingCoachService` automatically; unset,
   it falls back to the offline stub.

## Cost (on-demand, no idle fee)

At ~100 calls/day (~3k/month, ~2.5k in + ~500 out tokens each) Nova 2 Lite is
≈ **$6–7/month**; the Lambda itself is within the AWS free tier. See the in-chat
estimate for the scale table.

## Switching models / hardening

- **Nova ↔ Claude**: only change `BEDROCK_MODEL_ID` (same Converse API).
- **Production**: lock the Function URL down (IAM/JWT or put API Gateway +
  throttling in front), add per-user rate limiting, and consider prompt caching
  for the system prompt.

> Reference implementation — validate on first deploy (model id, region, model
> access). Not deployed/tested from this repo.

---

## Go-live plan (end to end)

**Phase 0 — in-app (DONE, shipping):** backend-agnostic `LightingCoachService`,
offline stub fallback, `RemoteLightingCoachService` → `lm_coach_endpoint`, and a
**Settings → AI Coach endpoint** field to paste the URL. Nothing here holds a key.

**Phase 1 — deploy the proxy (your AWS, ~15 min):** steps 1–4 above (enable
Nova 2 Lite access → Lambda with `handler.py` → IAM `bedrock:InvokeModel` →
Function URL).

**Phase 2 — connect + test:**
- Paste the Function URL into Settings → AI Coach endpoint.
- Test on a **real device** (sim has no camera): capture → Coach, try **Room**
  and **Selfie**. Confirm the JSON parses (`vibe/emoji/headline/tips/score`) and
  the advice/scoring quality. Tune the system prompt in `handler.py` if needed
  (redeploy = paste).

**Phase 3 — pick the model (compare on real output):** Nova 2 Lite (~$7/mo at
100 DAU) vs Claude Sonnet (best quality) — swap `BEDROCK_MODEL_ID` only. Cost is
negligible at this scale, so choose on quality.

**Phase 4 — harden before public launch:**
- Lock the Function URL (IAM/JWT or API Gateway + throttling) — an open URL is
  callable (and billable) by anyone.
- Per-device rate limiting; the app already caps the image at 1024px.
- Prompt caching for the system prompt (cuts cost).
- Graceful fallback: the app already shows a retry on error — consider
  auto-falling back to the offline stub.
- CloudWatch logs + a cost/error alarm.

**⚠️ Privacy (App Store):** in live mode the room/selfie photo is sent to AWS
Bedrock. Disclose this (privacy policy + `PrivacyInfo.xcprivacy`) and/or gate it
behind explicit consent before shipping the live model to the App Store. The
offline stub sends nothing off-device.
