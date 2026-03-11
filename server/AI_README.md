## MyOffers AI Assistant – Overview

### What this AI does
- **Customer in‑app assistant** exposed via `POST /ai/chat` (see `aiController.js`).
- Helps users **discover offers**, **find nearby shops**, **view coupons**, and **like/unlike offers** using natural language.
- Returns both a **short, friendly reply** and **structured UI actions/items** that the Flutter app can act on.

### Architecture
- **Model**: Google Gemini `gemini-2.5-flash` (configured with `GEMINI_API_KEY`).
- **Intent router** (`ai/intentRouter.js`):
  - Classifies each message into one of:
    - `search_offers`
    - `search_shops_nearby`
    - `list_user_coupons`
    - `best_coupons_for_plan`
    - `like_offer`
    - `unlike_offer`
  - Calls the corresponding tool and wraps the result as:
    - `toolResult`: raw data from the tool.
    - `actions`: suggested UI actions (e.g. `open_offer`, `open_offers_tab`, `open_coupons_tab`).
    - `items`: normalized lists (`offers`, `shops`, `coupons`) for the client to render.
- **Answer generation** (`aiController.customerHelpChat`):
  - Builds a prompt that includes:
    - User message.
    - Intent + `toolResult` JSON.
  - Asks Gemini to produce a **1–3 sentence answer** in the user’s language (English/Hindi), grounded in the tool data.

### Tools (server-side)
- **Offer tools** (`ai/tools/offerTools.js`)
  - `searchOffers`: Prisma query over active offers, filtered by query, category, location, and minimum discount.
  - `likeOffer` / `unlikeOffer`: toggle likes via `offerRepository`, updating `likesCount`.
- **Coupon tools** (`ai/tools/couponTools.js`)
  - `getUserCoupons`: latest active, non‑expired coupons with agent metadata and remaining incentive.
  - `getBestCouponsForPlan`: top percentage coupons by discount for a plan‑style question.
- **Shop tools** (`ai/tools/shopTools.js`)
  - `searchShopsNearby`: finds approved shopkeepers around a pincode/city/state and joins basic shop profile info.

### Mobile app integration (Flutter)
- **Service**: `ChatAssistantService` (`client/lib/services/chat_assistant_service.dart`)
  - Sends the user’s message to `/ai/chat` with auth token.
  - Parses `reply`, `actions`, and `items` into `ChatAssistantResult`.
- **UI**: `CustomerChatBotScreen` (`client/lib/screens/customer/customer_chat_bot_screen.dart`)
  - Chat UI that:
    - Streams user/bot messages.
    - Renders AI **actions as chips** (e.g. “Browse nearby offers”).
    - On action tap, navigates back to the main dashboard (offers/coupons) for now.
  - Falls back to a small local FAQ if the AI endpoint fails, so help is always available.

### Configuration & limits
- Requires `GEMINI_API_KEY` in `server/.env`.
- All AI calls are **read‑only**: tools only read Prisma data or toggle likes; no destructive operations depend on model output.
- Logging:
  - Requests and reply lengths are logged under `[AI]` and `[CUSTOMER_OFFERS]` prefixes for debugging.

### Next steps (roadmap)
- **Deep links from chat**: open specific offer / shop / coupons screens directly from AI action chips instead of just returning to the dashboard.
- **Richer intent set**: support FAQs about onboarding, subscriptions, and shop activation, plus basic support flows (e.g. “contact support”, “report an issue”).
- **Personalization**: bias `search_offers` and `search_shops_nearby` results using the user’s favorites, location history, and subscription status.
- **Guardrails & analytics**: add rate‑limiting, better error telemetry, and simple feedback signals (thumbs‑up/down) on AI replies.

