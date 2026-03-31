# D-Offers Client Operations Guide

## 1. Executive Snapshot

**D-Offers** is a multi-role hyperlocal commerce platform that connects customers, shopkeepers, field agents, and platform operators in one operating system for local offers, lead conversion, subscriptions, campaigns, rewards, and redemptions.

### Who it serves

| Group | Why they use D-Offers |
|---|---|
| Customers | Discover nearby offers, claim deals, redeem coupons, earn rewards, access loan flow, get AI help |
| Shopkeepers | Onboard, subscribe, publish offers, run campaigns, redeem customer claims, buy AI credits |
| SSA / CSA | Create and manage shop leads, influence onboarding, apply coupon-linked acquisition |
| Subadmin | Run operations, users, analytics, reports, subscriptions, and coupon governance |
| Super Admin | System oversight, shop visibility, audit control, agent creation, coupon activation control |

### Revenue and engagement model

- Shopkeeper subscription plans drive recurring revenue.
- Free starter and trial layers reduce onboarding friction.
- Campaigns create usage-based monetization.
- AI credit packs extend paid value beyond subscription limits.
- Coupon-linked lead onboarding supports agent-driven acquisition.
- Claims, redemption, and coin rewards improve repeat usage.

### Current business value

- One app stack supports 6 operating roles.
- Lead-to-subscription flow is connected, not manual.
- Shopkeeper growth is tracked through agents, coupons, and governance.
- Customer offer discovery is location-first and claim-aware.
- Redemption closes the business loop from offer to sale.
- Rewards add retention for both customer and shopkeeper.
- AI already supports customer help and shopkeeper AI-credit journeys.
- Campaigns are live for in-app inbox delivery and queued expansion.

## 2. Product at a Glance

| Role | Access / Landing | Main screens | Key actions | Business purpose |
|---|---|---|---|---|
| Super Admin | Dedicated super admin flow | Dashboard, shops, users, audit, agent governance | View system metrics, create SSA/CSA, track coupon activations, manage caps | Central control and compliance |
| Subadmin | Admin dashboard | Dashboard, users, analytics, reports, subscription governance, coupon governance | Manage users, approve/reject shops, monitor platform, manage plans | Day-to-day platform operations |
| Company Sales Agent | CSA dashboard | Leads, shops, reports, coupons | Create leads, retry invite OTP, drive onboarding with coupon attribution | Sales-led acquisition |
| SSA | Customer entry with SSA switch | SSA home, shopkeepers, profile | Create leads, share coupon code, retry invites, track conversions | Field onboarding and local expansion |
| Shopkeeper | Onboarding then shop dashboard | Dashboard, offers, campaigns, loans, shop tab | Complete onboarding, subscribe, create offers, run campaigns, redeem coupons, buy AI credits | Merchant growth and monetization |
| Customer | Customer dashboard | Home, offers, claims, loans, favorites, profile, chatbot | Discover offers, like, claim, redeem, earn rewards, apply for loan, become SSA | Demand generation and repeat engagement |

## 3. Basic Technical Foundation

| Layer | Current foundation | Why it matters |
|---|---|---|
| Client | Flutter app | One app experience across roles |
| Backend | Node.js + Express | Central business logic and role routing |
| Database | PostgreSQL + Prisma | Structured role, offer, subscription, campaign, loan, reward, and claim data |
| Identity | OTP login + JWT + role checks | Fast onboarding with controlled access |
| Engines | Subscription, campaign, reward, claim/redemption, loan, AI | Converts discovery into governed business flows |
| Integrations | Gemini AI, Cloudinary uploads, rate limits, coupon governance | Adds support, assets, and operational control |

```mermaid
flowchart LR
  App[Flutter App]
  API[Express API]
  Core[Core Engines]
  DB[(PostgreSQL + Prisma)]
  AI[Gemini AI]
  Media[Upload / Media]

  App --> API
  API --> Core
  Core --> DB
  Core --> AI
  Core --> Media

  Core --> Auth[OTP + JWT + RBAC]
  Core --> Subs[Subscriptions]
  Core --> Offers[Offers + Claims]
  Core --> Camp[Campaigns]
  Core --> Rewards[Coins + Milestones]
  Core --> Loans[Loan Intake]
```

## 4. Unified Login and Role Routing

```mermaid
flowchart TD
  A[Splash / Login] --> B[Phone + OTP]
  B --> C{Existing user?}
  C -->|No| D[Role selection + registration]
  C -->|Yes| E[Verify role + permissions]
  D --> E
  E --> F{Resolved role}
  F --> SA[Super Admin]
  F --> AD[Subadmin]
  F --> CSA[CSA Dashboard]
  F --> SSA[Customer Dashboard with SSA capability]
  F --> SK[Shopkeeper Onboarding / Dashboard]
  F --> CU[Customer Dashboard]
```

### Routing notes

- `customer` lands on customer dashboard.
- `shopkeeper` enters onboarding until profile and subscription state are ready.
- `ssa` can operate in SSA mode and still has customer capability.
- `company_sales_agent` lands on CSA dashboard.
- `subadmin` lands on admin dashboard.
- `super_admin` has higher-order governance flows.

## 5. Role-Wise Flows

### 5.1 Super Admin

**Objective:** full-system control, agent network governance, and coupon oversight.  
**Entry:** privileged admin login.  
**Default landing:** super admin dashboard.

| Area | What the role sees / controls |
|---|---|
| Analytics | users by role, total shops, subscription status mix, MRR, activity |
| Shop oversight | shop list with subscription view, filters by location and category |
| Audit | audit trail visibility |
| Agent governance | create and view SSA / CSA |
| Coupon control | coupon activations, discount distribution, governance settings |
| Policy control | max coupon discount cap at agent level |

```mermaid
flowchart TD
  SA1[Login] --> SA2[Super Admin Dashboard]
  SA2 --> SA3[System Metrics]
  SA2 --> SA4[Users and Shops]
  SA2 --> SA5[Audit Logs]
  SA2 --> SA6[Agent Governance]
  SA6 --> SA7[Create SSA]
  SA6 --> SA8[Create CSA]
  SA6 --> SA9[Coupon Activations]
  SA6 --> SA10[Discount Cap Governance]
```

### 5.2 Subadmin

**Objective:** run platform operations without full super admin scope.  
**Entry:** admin login.  
**Default landing:** admin dashboard.

| Area | What it covers |
|---|---|
| User operations | list users, inspect user detail, filter by role/location/category |
| Shop approval | approve or reject pending shopkeepers |
| Analytics | platform-level dashboards |
| Reports | reporting screens |
| Subscription governance | manage plans, subscriptions, analytics, renewals, cancellations |
| Coupon governance | agent and coupon oversight |

```mermaid
flowchart TD
  AD1[Login] --> AD2[Admin Dashboard]
  AD2 --> AD3[Users]
  AD2 --> AD4[Platform Analytics]
  AD2 --> AD5[Reports]
  AD2 --> AD6[Subscription Governance]
  AD2 --> AD7[Agent and Coupon Governance]
  AD3 --> AD8[Approve / Reject Shops]
  AD3 --> AD9[User Detail]
```

### 5.3 Company Sales Agent

**Objective:** create shopkeeper pipeline and convert leads into active merchants.  
**Entry:** CSA login.  
**Default landing:** CSA dashboard.

| Area | Operational meaning |
|---|---|
| Lead creation | capture shop, owner, phone, location, notes, coupon |
| Invite retry | resend OTP invite when onboarding stalls |
| Coupon influence | coupon can be attached at acquisition stage |
| Pipeline visibility | track open, contacted, converted, or failed invite states |
| Shop tracking | see connected shop base |

```mermaid
flowchart TD
  CSA1[Login] --> CSA2[CSA Dashboard]
  CSA2 --> CSA3[Lead List]
  CSA3 --> CSA4[Create Lead]
  CSA4 --> CSA5[Attach Coupon if needed]
  CSA5 --> CSA6[Send Invite OTP]
  CSA6 --> CSA7[Lead Status Tracking]
  CSA7 --> CSA8[Retry Invite]
  CSA7 --> CSA9[Shopkeeper Converts]
```

### 5.4 SSA

**Objective:** field-led merchant onboarding with dual customer + agent capability.  
**Entry:** customer-to-SSA upgrade or direct SSA login.  
**Default landing:** customer dashboard or SSA dashboard after switch.

| Area | Operational meaning |
|---|---|
| SSA onboarding | customer becomes SSA with pincode and contact details |
| Role switching | can move between customer experience and SSA workflow |
| Lead handling | create leads, track invite status, retry OTP |
| Coupon use | show and share assigned coupon codes |
| Shop tracking | view onboarded shops and lead movement |

```mermaid
flowchart TD
  SSA1[Customer or SSA Login] --> SSA2{SSA mode?}
  SSA2 -->|No| SSA3[Customer Dashboard]
  SSA2 -->|Yes| SSA4[SSA Dashboard]
  SSA4 --> SSA5[Stats + Coupons]
  SSA4 --> SSA6[Leads]
  SSA6 --> SSA7[Create Lead]
  SSA7 --> SSA8[Invite OTP]
  SSA8 --> SSA9[Retry if failed]
  SSA6 --> SSA10[Converted Shopkeeper]
```

### 5.5 Shopkeeper

**Objective:** become an active merchant, publish deals, run campaigns, redeem claims, and grow via subscription.

| Area | Operational meaning |
|---|---|
| Registration | direct signup or lead-linked invite |
| Onboarding | profile completion, terms, business details |
| Free/trial funnel | auto-trial where eligible, free starter fallback, paid upgrade path |
| Subscription | plan quote, coupon application, payment, plan activation |
| Offer management | create, edit, view, delete offers |
| Campaign usage | audience targeting, cost estimation, draft, pay, queue, launch |
| Redemption | verify and redeem customer claims via QR or manual flow |
| AI credits | use plan allowance and buy extra credit packs |
| Rewards | earn shopkeeper coins and redeem milestones |
| Loans | capital-loan tab available in shop flow |

```mermaid
flowchart TD
  SK1[Signup or Lead Invite OTP] --> SK2[Onboarding]
  SK2 --> SK3[Business Profile Complete]
  SK3 --> SK4[Subscription State Check]
  SK4 --> SK5{Paid / Trial / Free}
  SK5 --> SK6[Shop Dashboard]
  SK6 --> SK7[Offers]
  SK6 --> SK8[Campaigns]
  SK6 --> SK9[Capital Loan]
  SK6 --> SK10[Shop Profile]
  SK7 --> SK11[Create / Edit Offer]
  SK8 --> SK12[Target Audience + Cost]
  SK8 --> SK13[Pay and Launch]
  SK10 --> SK14[AI Credits / Rewards / Subscription Detail]
  SK6 --> SK15[Redeem Customer Coupons]
```

### 5.6 Customer

**Objective:** discover local value, claim deals, redeem them in-store, and stay engaged.

| Area | Operational meaning |
|---|---|
| Home and offers | location-first feed, categories, likes, featured paths |
| Claims | active claimed deals with QR payload and coupon code |
| Favorites | liked offers and saved discovery |
| Redemption outcome | redeemed claims update state and trigger reward flow |
| Wallet visibility | reward balance and history screens |
| AI help | chatbot for offers, coupons, savings, and support |
| Loans | submit and track loan applications |
| SSA path | become SSA from customer journey |

```mermaid
flowchart TD
  CU1[Login] --> CU2[Customer Dashboard]
  CU2 --> CU3[Home]
  CU2 --> CU4[Offers]
  CU2 --> CU5[Claims]
  CU2 --> CU6[Loans]
  CU2 --> CU7[Favorites]
  CU2 --> CU8[Profile]
  CU2 --> CU9[AI Chat]
  CU4 --> CU10[Like]
  CU4 --> CU11[Claim Offer]
  CU11 --> CU5
  CU5 --> CU12[Show QR / Coupon]
  CU8 --> CU13[Become SSA]
```

## 6. Cross-Role Business Journeys

### 6.1 Lead to Shopkeeper Onboarding

```mermaid
sequenceDiagram
  participant Agent as SSA / CSA
  participant API as Platform
  participant Shop as Shopkeeper

  Agent->>API: Create lead with shop details
  Agent->>API: Attach coupon code if applicable
  API->>API: Create or link lead record
  API->>Shop: Send invite OTP
  Shop->>API: Verify OTP and enter as shopkeeper
  Shop->>API: Complete profile
  Shop->>API: Reach subscription stage
```

### 6.2 Coupon Capture to Subscription Payment

```mermaid
sequenceDiagram
  participant Lead as Lead / Signup
  participant App as Shopkeeper App
  participant API as Subscription Engine

  Lead->>App: Enter signup coupon or receive lead-linked coupon
  App->>API: Request plan quote
  API->>API: Validate coupon and attribution
  API-->>App: Show price, discount, agent attribution
  App->>API: Confirm payment
  API-->>App: Activate plan / trial / free layer
```

### 6.3 Offer Publish to Customer Claim

```mermaid
flowchart LR
  SK[Shopkeeper creates offer] --> Feed[Offer appears in customer feed]
  Feed --> Like[Customer can like / save]
  Feed --> Claim[Customer claims offer]
  Claim --> Coupon[Claim coupon generated]
  Coupon --> Claims[Claims tab updated]
```

### 6.4 Claim to Redemption to Coin Rewards

```mermaid
sequenceDiagram
  participant Customer
  participant Shop as Shopkeeper / Authorized role
  participant API as Redemption Engine
  participant Reward as Reward Engine

  Customer->>Shop: Show QR or coupon code
  Shop->>API: Verify coupon
  Shop->>API: Redeem coupon
  API->>API: Mark redemption and claim state
  API->>Reward: Award shopkeeper sale_closed coins
  API->>Reward: Award customer purchase_success coins
  Reward-->>Customer: Wallet updated
  Reward-->>Shop: Wallet / milestone updated
```

### 6.5 Campaign Lifecycle

```mermaid
flowchart TD
  C1[Shopkeeper selects offer] --> C2[Choose location and audience]
  C2 --> C3[Select live channels]
  C3 --> C4[Estimate audience and cost]
  C4 --> C5[Save draft]
  C5 --> C6[Pay campaign]
  C6 --> C7{Scheduled?}
  C7 -->|Yes| C8[Queue campaign]
  C7 -->|No| C9[Launch now]
  C8 --> C10[Inbox delivery / campaign analytics]
  C9 --> C10
```

### 6.6 Customer Loan Inquiry Flow

```mermaid
flowchart TD
  L1[Customer opens Loans tab] --> L2[Enter personal and financial details]
  L2 --> L3[Upload bank statement]
  L3 --> L4[Give CIBIL consent]
  L4 --> L5[Submit application]
  L5 --> L6[Application stored with pending status]
  L6 --> L7[Customer can review status]
```

### 6.7 AI-Assisted Journey

```mermaid
flowchart LR
  User[Customer question] --> Chat[AI Chat]
  Chat --> Intent[Intent routing]
  Intent --> Tools[Internal app tools]
  Tools --> Reply[Concise grounded response]

  Shopkeeper[Shopkeeper AI usage] --> Wallet[AI credit wallet]
  Wallet --> Packs[Pack purchase / allowance]
```

### 6.8 Free / Trial to Paid Conversion

```mermaid
flowchart TD
  F1[Shopkeeper completes onboarding] --> F2[Check active paid plan]
  F2 -->|Yes| F3[Use paid entitlements]
  F2 -->|No| F4{Trial eligible?}
  F4 -->|Yes| F5[Auto-activate trial]
  F4 -->|No| F6[Free starter]
  F5 --> F7[Feature usage within trial caps]
  F6 --> F8[Feature usage within free caps]
  F7 --> U[Upgrade prompt]
  F8 --> U
  U --> P[Paid plan activation]
```

## 7. Module Snapshot

| Module | Purpose | Main users | Status |
|---|---|---|---|
| Auth | OTP login, role routing, access control | All roles | `Live` |
| Onboarding | shopkeeper profile completion and readiness | Shopkeeper, agents | `Live` |
| Offers | create, browse, like, manage offers | Shopkeeper, customer | `Live` |
| Subscriptions | quote, coupon apply, trial/free/paid access | Shopkeeper, admin | `Live` |
| Campaigns | draft, audience estimate, payment, launch, inbox | Shopkeeper | `Live` |
| Rewards / Coins | wallet, ledger, milestones, config | Customer, shopkeeper, admin | `Live` |
| Coupon governance | coupon assignment, activations, discount caps | Super Admin, subadmin, agents | `Live` |
| Claims / Redemptions | claim generation, QR/manual verify, redeem | Customer, shopkeeper, SSA, CSA | `Live` |
| Loans | customer loan intake and tracking | Customer, shopkeeper | `Live` |
| AI chatbot | customer help and app guidance | Customer | `Live` |
| AI credits / packs | merchant AI allowance and top-up | Shopkeeper | `Live` |
| Admin governance | users, reports, analytics, plan control | Subadmin, super admin | `Live` |
| WhatsApp campaign delivery | multi-channel campaign expansion | Shopkeeper | `In rollout` |
| Email / push campaign delivery | additional outbound channels | Shopkeeper | `Announced` |

## 8. Current State and Business Readiness

### Live today

- OTP-based role entry and role-specific dashboards.
- Lead creation with invite retry and coupon-linked acquisition.
- Shopkeeper onboarding with trial / free / paid subscription paths.
- Offer publishing, customer like/favorite behavior, and claim creation.
- Coupon verification and redemption with reward payout.
- Coin wallet, ledger, milestone, and admin reward controls.
- Customer AI chatbot using Gemini.
- Shopkeeper AI credit wallet and extra pack purchase flow.
- Campaign drafting, audience estimation, payment, queueing, and in-app inbox delivery.
- Loan application intake with statement upload and consent capture.

### Recently added / stabilizing

- Campaign analytics gated by plan entitlements.
- Rewards operations and maintenance workflows.
- Claims, QR payload, and redemption-linked payout consistency.
- AI-credit monetization alignment with subscription tiers.
- Trial and free-funnel enforcement across merchant features.

### Reserved for next phase

- Fully live omnichannel campaign delivery beyond in-app inbox.
- Push-notification device pipeline and delivery orchestration.
- Stronger AI content generation and operational copilots.
- Deeper predictive analytics for churn, fraud, and performance actions.
- Better navigation handoffs from AI into exact app actions.

## 9. Operations Notes

- Campaign channels are not equal today: `app_inbox` is live, while broader outbound expansion is still phased.
- Shopkeeper access is feature-gated by subscription status.
- Customer claim and redemption are now part of the core closed-loop commerce flow.
- SSA and CSA are acquisition roles; shopkeeper value starts when onboarding converts into active subscription and offer usage.
- Older documents that describe campaigns, AI, or rewards as "planned" are no longer the correct baseline for client communication.
