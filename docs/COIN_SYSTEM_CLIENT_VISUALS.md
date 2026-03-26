# Coin System: Client Visual Guide (Frontend Only)

This document is made for client walkthroughs.
It explains what users see in the app and how coin actions look from UI perspective.

## 1) Frontend Coin Flow (All Roles)

```mermaid
flowchart TD
    A[User Opens App] --> B{Role}
    B -->|Customer| C1[Home: Offers Feed]
    B -->|Shopkeeper| S1[Dashboard]
    B -->|Admin| A1[Admin Panel]

    C1 --> C2[Like Offer]
    C1 --> C3[Unlock Deal]
    C2 --> C4[Coins Added]
    C3 --> C4
    C4 --> C5[Wallet Screen]
    C5 --> C6[History + Expiry Summary]

    S1 --> S2[Sale Closed]
    S1 --> S3[Install Verified]
    S2 --> S4[Coins Added]
    S3 --> S4
    S4 --> S5[Rewards & Milestones Screen]
    S5 --> S6[Redeem Milestone]

    A1 --> A2[Reward Config Screen]
    A1 --> A3[Coin Metrics]
    A2 --> A4[Rules Updated]
    A4 --> C1
    A4 --> S1
```

## 2) Screen Journey (Frontend Visuals)

```mermaid
flowchart LR
    subgraph Customer App
      C1[Customer Home]
      C2[Offer Detail]
      C3[Wallet]
      C4[Ledger History]
      C1 --> C2 --> C3 --> C4
    end

    subgraph Shopkeeper App
      S1[Shop Dashboard]
      S2[Create/Run Campaign]
      S3[Rewards & Milestones]
      S4[Redeem Request]
      S1 --> S2 --> S3 --> S4
    end

    subgraph Admin App
      A1[Admin Dashboard]
      A2[Reward Config]
      A3[Reports: Coin Metrics]
      A1 --> A2
      A1 --> A3
    end
```

## 3) What Client Will See in UI

### Customer
- Like offer or unlock deal and coins are credited.
- Wallet screen shows current balance.
- History shows credits/debits and expiry summary.

### Shopkeeper
- Coins are credited on sale closed and install verified events.
- Rewards & Milestones screen shows progress.
- Milestone redeem request can be submitted from UI.

### Admin
- Reward config page to adjust rules and limits.
- Metrics view to monitor coin economy.

## 4) Demo Script (2-Minute Walkthrough)

1. Login as customer.
2. Like one offer, then open wallet and show coin increase.
3. Login as shopkeeper.
4. Trigger sale/install flow and open rewards page.
5. Login as admin and show reward config + coin metrics.

## 5) Note for Internal Team

Backend connection errors do not change the frontend explanation above.
For client demos, use seeded data or staging server with healthy DB connectivity.
