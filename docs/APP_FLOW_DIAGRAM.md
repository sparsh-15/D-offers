# MyOffers App — Flow Diagram (All 6 Roles)

This document describes the end-to-end app flow **role-wise** so you can see how each role enters the app, what they can do, and how flows connect (e.g. leads → shopkeeper registration → payment with coupons).

---

## 1. Roles Overview

| Role | Description | Post-login default screen |
|------|-------------|---------------------------|
| **Super Admin** | System-wide control: users, shops, audit, agent & coupon governance | Super Admin Dashboard (separate entry) |
| **Subadmin** | Platform admin: users, analytics, reports, subscription & coupon governance | Admin Dashboard |
| **Company Sales Agent (CSA)** | Company-level sales: leads, coupons, shops, reports | CSA Dashboard |
| **SSA** (Store Sales Agent) | Field agent: leads/shopkeepers, can also use app as customer | Customer Dashboard (toggle to SSA Dashboard) |
| **Shopkeeper** | Shop owner: profile, subscription, offers, leads | Onboarding → Shop Dashboard |
| **Customer** | End user: browse offers, favorites, profile, become SSA | Customer Dashboard |

---

## 2. App Entry & Auth (All Roles)

```mermaid
flowchart LR
  subgraph Entry
    A[Splash] --> B[Login]
    B --> C[Enter Phone]
    C --> D[Send OTP]
    D --> E[OTP Screen]
  end

  subgraph NewUser
    B -.-> F[Role Selection]
    F --> G[Register Screen]
    G --> H[Name, Phone, Optional Coupon]
    H --> E
  end

  E --> R{Verify OTP}
  R -->|Success| Dest[Role-based Destination]
```

- **Login**: Phone → Send OTP → Enter OTP → Verify → Navigate by role.
- **New user**: Login screen → “Sign up” → Role Selection → Register (name, phone; **shopkeeper** can enter coupon) → OTP → Verify → Navigate by role.
- **Post-OTP destinations** (from code):
  - **customer** → Customer Dashboard  
  - **shopkeeper** → Shop Dashboard (may show Onboarding first)  
  - **admin** (super_admin / subadmin) → Admin Dashboard  
  - **ssa** → Customer Dashboard (with option to switch to SSA view)  
  - **company_sales_agent** → CSA Dashboard  

---

## 3. Role-wise Flows

### 3.1 Super Admin

```mermaid
flowchart TB
  subgraph SuperAdmin["Super Admin"]
    SA_Entry[Login as super_admin] --> SA_Dash[Super Admin Dashboard]
    SA_Dash --> SA_Analytics[System Overview: users, shops, MRR, activity]
    SA_Dash --> SA_Users[Users Management]
    SA_Dash --> SA_Shops[Shops Management]
    SA_Dash --> SA_Audit[Audit Logs]
    SA_Dash --> SA_Gov[Agent Governance]
    SA_Gov --> SA_SSA[SSA List / Create SSA]
    SA_Gov --> SA_CSA[Company Sales Agents List / Create CSA]
    SA_Gov --> SA_Coupons[Coupon List & Activations]
    SA_Gov --> SA_Cap[Coupon Cap Settings]
  end
```

- **APIs**: `/super-admin/*` (analytics, users, shops, audit), `/agent-governance/*` (SSA, CSA, coupons, settings).
- **Note**: In the client, super_admin and subadmin both map to `UserRole.admin`; Super Admin Dashboard is a separate screen (e.g. reached when backend returns `super_admin` or via dedicated entry).

---

### 3.2 Subadmin (Admin)

```mermaid
flowchart TB
  subgraph Subadmin["Subadmin (Admin)"]
    AD_Entry[Login as subadmin] --> AD_Dash[Admin Dashboard]
    AD_Dash --> AD_Home[Dashboard Tab: stats, quick actions]
    AD_Dash --> AD_Users[Users Tab: list, filter, suspend/delete]
    AD_Dash --> AD_Profile[Admin Profile Tab]
    AD_Home --> AD_Analytics[Platform Analytics]
    AD_Home --> AD_Reports[Reports]
    AD_Home --> AD_SubGov[Subscription Governance]
    AD_Home --> AD_CouponGov[Agent Coupon Governance]
    AD_Users --> AD_UserDetails[User Details Screen]
  end
```

- **APIs**: `/admin/*`, `/subscription-governance/*`, agent coupon governance (if exposed for subadmin).
- **Admin Dashboard**: Bottom nav = Dashboard, Users, Admin (profile).

---

### 3.3 Company Sales Agent (CSA)

```mermaid
flowchart TB
  subgraph CSA["Company Sales Agent"]
    CSA_Entry[Login] --> CSA_Dash[CSA Dashboard]
    CSA_Dash --> CSA_Stats[Stats]
    CSA_Dash --> CSA_Shops[My Shops]
    CSA_Dash --> CSA_Reports[Reports]
    CSA_Dash --> CSA_Coupons[My Coupons]
    CSA_Dash --> CSA_Leads[Leads]
    CSA_Leads --> CSA_CreateLead[Create Lead]
    CSA_Leads --> CSA_RetryInvite[Retry OTP Invite]
    CSA_CreateLead --> CreateLeadForm[Shared Create Lead Form]
  end
```

- **APIs**: `/company-sales/*` (stats, shops, reports, coupons, leads, create lead, retry-invite).
- **Create Lead**: Same shared form as SSA; backend creates/links user (first-lead-wins), sends invite OTP; UI shows success/conflict/invite status.

---

### 3.4 SSA (Store Sales Agent)

```mermaid
flowchart TB
  subgraph SSA["SSA"]
    SSA_Entry[Login] --> SSA_Default[Customer Dashboard]
    SSA_Default --> SSA_Switch[Switch to SSA View]
    SSA_Switch --> SSA_Dash[SSA Dashboard]
    SSA_Dash --> SSA_Home[Home Tab]
    SSA_Dash --> SSA_Shopkeepers[Shopkeepers Tab: leads list]
    SSA_Dash --> SSA_Profile[Profile Tab]
    SSA_Shopkeepers --> SSA_CreateLead[Create Lead]
    SSA_Shopkeepers --> SSA_RetryInvite[Retry OTP Invite]
    SSA_CreateLead --> CreateLeadForm[Shared Create Lead Form]
  end
```

- **APIs**: `/ssa/*` (stats, leads, create lead, retry-invite).
- **SSA** lands on Customer Dashboard; profile shows “Customer view” toggle → switch to SSA Dashboard. **Customer** can “Become SSA” from profile → onboarding → SSA Dashboard.

---

### 3.5 Shopkeeper

```mermaid
flowchart TB
  subgraph Shopkeeper["Shopkeeper"]
    SK_Entry[Login / Post lead-invite OTP] --> SK_Onboard{Onboarding done?}
    SK_Onboard -->|No| SK_Profile[Complete Profile: shop name, pincode, city]
    SK_Profile --> SK_Sub[Subscription required]
    SK_Sub --> SK_Plans[Subscription Plans Screen]
    SK_Plans --> SK_Pay[Payment Screen]
    SK_Pay --> SK_Coupon[Optional: Apply coupon / use signup coupon]
    SK_Pay --> SK_Success[Payment Success]
    SK_Onboard -->|Yes| SK_Dash[Shop Dashboard]
    SK_Success --> SK_Dash
    SK_Dash --> SK_Home[Home Tab]
    SK_Dash --> SK_Offers[Offers Tab: list, add, edit]
    SK_Dash --> SK_Leads[Leads Tab]
    SK_Dash --> SK_Shop[Shop Profile Tab]
    SK_Shop --> SK_SubGov[Subscription / AI credits etc.]
  end
```

- **APIs**: `/shopkeeper/*`, `/subscription/*` (plans, quote, create subscription), `/onboarding/*`.
- **Coupon**: Can be captured at **registration** (shopkeeper signup or when created via lead). **Payment screen** prefills signup coupon, user can Apply; quote API returns discount and attribution (e.g. “Referral discount from Agent X”).

---

### 3.6 Customer

```mermaid
flowchart TB
  subgraph Customer["Customer"]
    CU_Entry[Login] --> CU_Dash[Customer Dashboard]
    CU_Dash --> CU_Home[Home Tab]
    CU_Dash --> CU_Offers[Offers Tab]
    CU_Dash --> CU_Fav[Favorites Tab]
    CU_Dash --> CU_Profile[Profile Tab]
    CU_Profile --> CU_BecomeSSA[Become SSA]
    CU_BecomeSSA --> CU_SSAOnboard[SSA Onboarding]
    CU_SSAOnboard --> SSA_Dash[SSA Dashboard]
    CU_Dash --> CU_Chat[Help Chat Bot]
  end
```

- **APIs**: `/customer/*`, `/offers/*`, `/ai/chat`, auth for role upgrade to SSA.

---

## 4. Cross-Role Flows (Leads & Coupons)

### 4.1 Lead → Shopkeeper Registration & Payment

```mermaid
sequenceDiagram
  participant SSAorCSA as SSA / CSA
  participant API as Backend
  participant SK as Shopkeeper (user)

  SSAorCSA->>API: Create Lead (phone, name, ... optional coupon)
  API->>API: First-lead-wins: create or link User, link ShopLead
  API->>API: Auto send invite OTP
  API-->>SSAorCSA: Success / Conflict / Invite status

  Note over SK: Shopkeeper receives OTP
  SK->>API: Login / Verify OTP (same phone)
  API-->>SK: Session, role shopkeeper
  SK->>SK: Onboarding: profile → subscription → Payment
  SK->>API: Quote (plan + signup coupon if present)
  API-->>SK: Discount, agent attribution
  SK->>API: Create subscription (payment)
  API-->>SK: Subscription active → Shop Dashboard
```

- **First-lead-wins**: One lead per phone; if phone already has a user/lead, API returns conflict.
- **Invite OTP**: After lead create, backend sends OTP; lead list shows invite status and “Retry OTP” if needed.
- **Coupon**: Stored at signup/lead; payment screen uses it in quote and shows “Referral discount from X”.

### 4.2 Coupon Flow (Unified)

```mermaid
flowchart LR
  subgraph Capture["Coupon capture"]
    C1[SSA/CSA create lead with coupon]
    C2[Shopkeeper registration with coupon]
  end

  subgraph Store["Storage"]
    U[User.signupCouponCode]
    L[ShopLead / attribution]
  end

  subgraph Use["Use at payment"]
    P[Payment Screen]
    Q[Quote API with coupon]
    A[Apply → discount + agent name]
  end

  C1 --> L
  C2 --> U
  U --> P
  P --> Q --> A
```

- **Governance**: Super Admin uses Agent Governance to manage coupons (list, activations, cap). Subadmin has Agent Coupon Governance screen. CSA/SSA get assigned coupons and use them in lead creation or shopkeeper sees them at registration/payment.

---

## 5. Single-Page Overview (All Roles)

```mermaid
flowchart TB
  subgraph Auth["Auth (all roles)"]
    Splash[Splash] --> Login[Login]
    Login --> OTP[OTP]
    Reg[Role Select → Register] --> OTP
  end

  OTP --> SuperAdmin[Super Admin Dashboard]
  OTP --> Admin[Admin Dashboard]
  OTP --> CSA[CSA Dashboard]
  OTP --> CustomerDash[Customer Dashboard]
  OTP --> ShopDash[Shop Dashboard]
  OTP --> Onboarding[Onboarding Flow]

  CustomerDash --> SSA_Dash[SSA Dashboard]
  CustomerDash --> CustomerTabs[Home | Offers | Favorites | Profile]
  ShopDash --> ShopTabs[Home | Offers | Leads | Shop]
  Onboarding --> ShopDash

  subgraph SuperAdminScreens["Super Admin"]
    SuperAdmin --> Users[Users] --> Shops[Shops] --> Audit[Audit] --> AgentGov[Agent Governance]
  end

  subgraph AdminScreens["Subadmin"]
    Admin --> UsersM[Users] --> Analytics[Analytics] --> Reports[Reports] --> SubGov[Subscription Gov] --> CouponGov[Coupon Gov]
  end

  subgraph CSAScreens["CSA"]
    CSA --> Leads[Leads] --> CreateLead[Create Lead] --> RetryInvite[Retry Invite]
    CSA --> Coupons[Coupons] --> ShopsM[Shops] --> ReportsM[Reports]
  end

  subgraph SSAScreens["SSA"]
    SSA_Dash --> SSA_Leads[Leads] --> SSA_CreateLead[Create Lead] --> SSA_Retry[Retry Invite]
  end

  subgraph ShopkeeperScreens["Shopkeeper"]
    ShopDash --> Payment[Payment + Coupon] --> OffersM[Offers] --> ProfileM[Profile]
  end

  subgraph CustomerScreens["Customer"]
    CustomerTabs --> BecomeSSA[Become SSA] --> SSA_Dash
  end
```

---

## 6. Quick Reference: Screens by Role

| Role | Main screens / actions |
|------|------------------------|
| **Super Admin** | Super Admin Dashboard, Users, Shops, Audit Logs, Agent Governance (SSA/CSA, Coupons, Cap) |
| **Subadmin** | Admin Dashboard (Home, Users, Profile), Platform Analytics, Reports, Subscription Governance, Agent Coupon Governance, User Details |
| **CSA** | CSA Dashboard, Stats, Shops, Reports, Coupons, Leads (create, retry invite) |
| **SSA** | Customer Dashboard ↔ SSA Dashboard (Home, Shopkeepers/Leads, Profile), Create Lead, Retry invite |
| **Shopkeeper** | Onboarding (profile + subscription) → Payment (coupon) → Shop Dashboard (Home, Offers, Leads, Shop) |
| **Customer** | Customer Dashboard (Home, Offers, Favorites, Profile), Become SSA, Help Chat |

---

*Generated from the current codebase (auth, routes, dashboards, lead onboarding, unified coupon flow).*
