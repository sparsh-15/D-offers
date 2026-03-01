# D'Offer – AI Phasing & Opportunities

This document describes **where AI is used today** and **where AI will be used** across the app, by phase. It is the single reference for AI rollout planning.

**Current AI model in use:** Google **Gemini 2.5 Flash**.

---

## 1. What Exists Today

| Area | Status | Notes |
|------|--------|--------|
| **Customer help chatbot** | ✅ Live | Real LLM (Gemini 2.5 Flash) with intent classification and tool-calling: search offers, find shops nearby, list coupons, best coupons for plan, like/unlike offers. Replies in English/Hindi. See `customer_chat_bot_screen.dart` + `/ai/chat`. |
| **Shopkeeper AI credits & banners** | ✅ Live | Monthly AI banner allowance from subscription; extra credits via purchasable packs (tiered silver/gold/platinum). One credit deducted per “use AI banner” action. Wallet, packs, and use endpoints are implemented. |
| **Offer ranking (customer feed)** | Rule-based | Tier (plan) + likes count + recency. No ML personalization yet. `customerController.listOffers`. |
| **Subscription plan recommendation** | Rule-based | Category filter + sort/price. `getRecommendedPlans`. |
| **Image uploads** | No AI | Direct to Cloudinary; no moderation or quality checks. `uploadController.js`. |
| **Admin / super-admin analytics** | No AI | Aggregate metrics only; no predictive or narrative layer. |

---

## 2. Where We Will Use AI – Full Map by Phase

| Phase | Area | Where in app | AI use | Recommended AI | Why |
|-------|------|---------------|--------|----------------|-----|
| **0 (Done)** | Customer help chatbot | Customer chat screen, dashboard, offer card | Intent + tools + reply generation | **Gemini 2.5 Flash** (in use) | Low latency, good instruction following. |
| **0 (Done)** | Shopkeeper AI credits & banner use | Shop dashboard, AI Credit Packs screen, offer/upload flow | Credit allowance + pack purchase + deduct on “use AI banner” | N/A (business logic) | Monetization and fairness; no model needed for counting. |
| **1** | Offer content copilot (shopkeeper) | `offer_details_screen.dart` – create/edit offer | Generate title, description, terms, CTA in Hindi/English | LLM (e.g. Gemini or GPT-4.1 mini) | Fast, controllable copy for listing quality. |
| **1** | Upload safety & quality | `uploadController.js` (before final accept) | Detect unsafe/spam, blurry creatives, text-overload banners | Vision + moderation API | Policy and quality without blocking all uploads. |
| **1** | Customer offer ranking | `customerController.listOffers` + OfferLike/location | Personalized ranking per user (not only tier/likes/recency) | Two-tower or XGBoost ranker + optional LLM rerank | Uses likes, category, pincode; high impact on engagement. |
| **1** | Semantic offer search | Customer offers tab / search + backend | Natural queries: “electronics under 30% off near me” | Embeddings + vector search | Better retrieval than keyword-only. |
| **1** | Help & Support → AI | `help_support_page.dart` | “Chat with AI” entry so users can get help without leaving support | Existing chatbot (Gemini 2.5 Flash) | Reuse current assistant; no new model. |
| **2** | Admin fraud & abuse detection | Audit logs, offer likes, offers, users | Flag fake-like rings, suspicious bursts, multi-account abuse | Anomaly detection (e.g. Isolation Forest / XGBoost) | Structured event data already available. |
| **2** | Subscription churn prediction | Subscription governance, dashboards | Predict likely churn; recommend intervention | Tabular ML (e.g. XGBoost / CatBoost) | Strong baseline on subscription/payment signals. |
| **2** | Banner/creative generation | Shopkeeper offer creation (when “use AI banner” is triggered) | Generate ad creative variants from offer text; consume 1 AI credit | Image generation model (e.g. GPT-image or equivalent) | Fits existing credit flow; improves campaign readiness. |
| **2** | Analytics copilot (NL insights) | `platform_analytics_screen.dart`, `reports_screen.dart` | “Why did MRR drop this month?” narrative + action suggestions | LLM over curated metrics context | Explanation and decision support for admins. |
| **3** | Onboarding assist | `onboarding_flow.dart`, shop profile | Suggest business category or shop name from free text | LLM (optional) | Smoother onboarding; lower drop-off. |
| **3** | Coupon creation assist | `create_coupon_screen.dart` (admin) | Suggest coupon copy, discount bands, or validation hints | LLM (optional) | Faster, consistent coupon creation. |
| **3** | CSA next-best-action | `csa_dashboard.dart` | Suggest which shops to visit or next action | LLM or small ranker over shop/agent data | Better field productivity. |
| **3** | Notification copy personalization | Push / in-app notifications | Personalize message per user/offer | LLM (short copy) | Higher open/click rates. |
| **3** | Chat deep links | Customer chat actions | Open specific offer/shop/coupons screen from AI chips | N/A (app navigation) | Better UX; uses existing chatbot. |

---

## 3. Implementation Order (Phased)

- **Phase 0 (Done)**  
  - Customer chatbot with Gemini 2.5 Flash.  
  - Shopkeeper AI wallet, credit packs, and “use AI banner” credit deduction.

- **Phase 1 (Next)**  
  1. Offer content copilot on shopkeeper create/edit offer screen.  
  2. Image moderation/quality checks in upload pipeline.  
  3. Personalized ranking in customer offer feed.  
  4. Semantic search with embeddings for offers.  
  5. “Chat with AI” from Help & Support page (link to existing chatbot).

- **Phase 2**  
  6. Admin fraud/churn scoring dashboards.  
  7. Banner/creative generation (when shopkeeper uses AI banner; consume 1 credit).  
  8. Analytics copilot (NL insights) for platform/reports.

- **Phase 3**  
  9. Onboarding and coupon-creation assist (optional).  
  10. CSA next-best-action (optional).  
  11. Notification copy personalization (optional).  
  12. Deep links from chat actions to offer/shop/coupon screens.

---

## 4. Data Already Available for AI

From the current schema and flows, these are available for future AI:

- **OfferLike** – preference and engagement signals for ranking.  
- **Offer** – category, discount, validity, status, photos.  
- **User** – location (pincode/city/state), role, activity.  
- **Subscription** – lifecycle and payment for churn modeling.  
- **AuditLog** – trails for anomaly and abuse detection.  
- **AI wallet / AiCreditPurchase** – usage for capacity and product decisions.

No major schema redesign is required to add the planned AI features.

---

## 5. Summary

- **Live today:** Customer chatbot (Gemini 2.5 Flash) and shopkeeper AI credits/banner use.  
- **Next:** Offer copilot, image moderation, personalized ranking, semantic search, and Help → AI entry.  
- **Later:** Fraud/churn, banner generation, analytics copilot, onboarding/coupon/CSA/notification assists, and chat deep links.

Use this doc as the single source for “where we use AI” and “where we will use AI” across the app.
