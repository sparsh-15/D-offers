# D-Offers AI Opportunities (App Analysis)

## 1. What Exists Today

Based on current code:

- Customer chatbot is rule-based dummy Q&A in `client/lib/screens/customer/customer_chat_bot_screen.dart`.
- Offer recommendation is rule-based category filtering in `server/src/controllers/subscriptionPlanController.js` (`getRecommendedPlans`).
- Customer offers are currently sorted by recency in `server/src/controllers/customerController.js` (`listOffers`).
- Image uploads are direct to Cloudinary without AI moderation in `server/src/controllers/uploadController.js`.
- Admin analytics are aggregate metrics with no predictive/assistant layer in `server/src/controllers/superAdminController.js` and `server/src/controllers/subscriptionGovernanceController.js`.

## 2. Where To Use AI and Which AI

| Priority | Area | Where in App | AI Use | Recommended AI | Why this choice |
|---|---|---|---|---|---|
| P0 | Customer Help Chatbot | `customer_chat_bot_screen.dart` + new backend `/ai/chat` | Real chatbot with tool-calling (search offers, explain redemption, account help) | **GPT-4.1 mini** (primary), **GPT-4.1** for complex escalations | Low latency + strong instruction following for app support flows |
| P0 | Customer Offer Ranking | `customerController.listOffers` + `OfferLike`/location data | Personalized ranking per user (not just newest offers) | **Two-tower recommender** (LightFM/XGBoost ranker) + optional **LLM rerank** | Uses existing likes, category, pincode signals; high impact on conversion |
| P0 | Offer Content Copilot (Shopkeeper) | `offer_details_screen.dart` | Generate title, description, terms, CTA in Hindi/English | **GPT-4.1 mini** | Fast copy generation with controllable tone/length |
| P0 | Upload Safety & Quality | `uploadController.js` | Detect unsafe/spam images, blurry creatives, text-overload banners | **Vision moderation model** (OpenAI moderation/vision or similar) | Reduces policy risk and poor-quality listings |
| P1 | Semantic Offer Search | customer offers tab/search flow + backend query layer | Understand natural queries: "electronics under 30% off near me" | **Embeddings** (`text-embedding-3-large` or `-small`) + vector search | Better retrieval than keyword matching |
| P1 | Admin Fraud & Abuse Detection | `audit_logs`, `offer_likes`, `offers`, `users` | Flag fake-like rings, suspicious coupon/offer bursts, multi-account abuse | **Anomaly detection** (Isolation Forest/XGBoost) | Structured event data is already available for risk scoring |
| P1 | Subscription Churn Prediction | `subscriptionGovernanceController.js` | Predict likely churn and recommend intervention | **Tabular ML** (XGBoost/CatBoost) | Strong baseline for subscription risk on structured data |
| P2 | Analytics Copilot (NL Insights) | `platform_analytics_screen.dart`, `reports_screen.dart` | "Why did MRR drop this month?" narrative + action suggestions | **GPT-4.1** over curated metrics context | Best for explanation and decision support |
| P2 | Banner/Creative Generation | Shopkeeper offer creation flow | Generate ad creative variants from offer text | **Image generation model** (`gpt-image-1` or equivalent) | Improves campaign readiness and speed |

## 3. Recommended AI Stack for This App

### Fastest to ship (managed AI)

- LLM: `gpt-4.1-mini` for chatbot + offer copy.
- High-reasoning fallback: `gpt-4.1`.
- Embeddings: `text-embedding-3-small` (cost), move to `text-embedding-3-large` if needed.
- Image gen: `gpt-image-1`.
- Moderation: vision + moderation endpoint before final image accept.

### Cost-optimized later (hybrid)

- Keep LLM tasks managed.
- Move ranking/churn/fraud models to in-house Python service (FastAPI + scheduled training).
- Keep Node backend as orchestration layer.

## 4. Suggested Implementation Order

1. Replace dummy chatbot with backend LLM + tool-calling (P0).
2. Add offer content copilot on shopkeeper create/edit screen (P0).
3. Add image moderation/quality checks in upload pipeline (P0).
4. Introduce personalized ranking in customer offer feed (P0).
5. Add semantic search with embeddings (P1).
6. Add admin fraud/churn scoring dashboards (P1).

## 5. Data Already Available for AI

From current schema (`server/prisma/schema.prisma`), you already have strong features:

- `OfferLike` interactions for preference modeling.
- `Offer` metadata (category, discount, validity, status).
- `User` location/profile (pincode/city/state, role, activity flags).
- `Subscription` lifecycle and payment signals for churn modeling.
- `AuditLog` trails for anomaly and abuse detection.

This means AI can be added incrementally without major schema redesign.
