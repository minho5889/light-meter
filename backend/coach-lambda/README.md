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
