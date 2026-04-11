# Requirement Documentation From Workbook

Source workbook: [docs/All about the Product (2).xlsx](docs/All%20about%20the%20Product%20(2).xlsx)

This document converts the workbook's `App features` sheet into a requirements view with two sides:
- Client requirement: what the workbook asks for in the `Features` and `Details` columns.
- Current state: what is already implemented, based on the `Remarks (Code Gap)` and `Completion %` columns.

## Summary

The workbook shows a mostly complete customer, shopkeeper, and admin foundation. The strongest gaps are in customer retention, social features, homepreneur-specific workflows, and a few advanced admin controls. Search, onboarding, offers, claims, redemption, subscriptions, and governance are already partially to mostly implemented.

## Requirement Matrix

### Customer

| ID | Requirement | Current State | Completion |
| --- | --- | --- | --- |
| 1 | Login/logout with phone number or email | Implemented end-to-end with OTP, session restore, and logout | 100% |
| 2 | Onboarding with mobile OTP and location auto-detect/manual override | OTP onboarding exists; location flow is partial | 75% |
| 3 | Profile creation with name, address, and shopping preferences | Profile fields exist; preference capture is partial | 70% |
| 4 | List shops in selected location by distance, paid priority, subscription tier, then alphabetically | Offer feed exists; strict shop ordering is partial | 55% |
| 5 | Personalized offer discovery from preferences and browsing behavior | Offer feed and likes exist; deeper personalization is limited | 45% |
| 6 | Nudges via campaign notifications, app events, and pop-ups | Notifications exist; event and pop-up strategy is partial | 60% |
| 7 | Search and filter by category, distance, rating, price band, and trending items | Search/filter exists; rating, price, and trending views are incomplete | 55% |
| 8 | AI intent recognition and recommendations for shopping queries | AI chat/intent routing exists; advanced recommendation depth is partial | 50% |
| 9 | Explore shop profile with offers, catalog, ratings, and reviews | Public shop profile exists; catalog and reviews are incomplete | 45% |
| 10 | Navigation to store with walking vs driving directions | Location features exist; dedicated navigation UX is limited | 30% |
| 11 | Claim an offer using QR for later redemption | Claim and QR/coupon generation are implemented | 90% |
| 12 | Close offer once shopkeeper accepts QR | QR/manual redemption flow is implemented | 95% |
| 13 | View order history | History exists, but consolidated journey is partial | 60% |
| 14 | Earn rewards from onboarding, purchase redemption, referrals, and likes | Coin rewards exist; welcome/referral rules are partial | 55% |
| 15 | Customer retention through Bronze, Silver, and Gold tiers | Dedicated loyalty tiers are not fully implemented | 20% |
| 16 | Customer dashboard showing supported local shops and coins collected | Dashboard and wallet exist; shop-support metric is partial | 50% |
| 17 | Social features: photo reviews, favorite shops, WhatsApp sharing | Deal sharing exists; reviews and follow actions are mostly pending | 25% |

### Shopkeeper

| ID | Requirement | Current State | Completion |
| --- | --- | --- | --- |
| 18 | Login/logout with phone or email | Fully implemented with role-based access | 100% |
| 19 | Self onboarding with mobile OTP and KYC/shop verification | Exists, but onboarding details can be hardened | 85% |
| 20 | Select subscription tier: Basic, Growth, Premium | Subscription plans and entitlements are implemented | 95% |
| 21 | Shop setup with profile, catalog, and visual merchandising | Shop profile and assets exist; catalog is partial | 70% |
| 22 | Create offers with discounts, combo deals, start, expiry, and scheduling | Offer lifecycle is implemented end-to-end | 95% |
| 23 | AI banner creation | AI banner generation and credit usage are implemented | 95% |
| 24 | Campaign management for trending placement, WhatsApp, and followers | Campaign creation exists; trend/follower logic is partial | 70% |
| 25 | Redemption via customer QR scan and redemption history | Redemption flows are implemented | 95% |
| 26 | Insight dashboard for traffic, likes, redemptions, revenue, and visits | Key stats exist; deeper intelligence is partial | 65% |
| 27 | Rewards for referrals and redemptions | Rewards exist; referral automation is partial | 50% |
| 28 | Direct walk-in routing through the app | Manual/QR closure supports walk-ins; referral loop is partial | 40% |

### Homepreneur

| ID | Requirement | Current State | Completion |
| --- | --- | --- | --- |
| 29 | Login/logout with phone or email | Not a separate first-class role yet | 35% |
| 30 | Self onboarding with KYC details | Mostly pending as a separate flow | 30% |
| 31 | Subscription tier selection | Mostly pending as a distinct persona flow | 30% |
| 32 | Business setup with profile, catalog, and merchandising | Mostly pending as a separate module | 30% |
| 33 | QR code for receiving payment | Dedicated payment QR flow is largely pending | 20% |
| 34 | Offer setup with discounts, combo deals, and scheduling | Exists only indirectly via shopkeeper parity | 30% |
| 35 | AI banner creation | Not separated; partial through shopkeeper flow | 30% |
| 36 | Campaign management | Mostly pending as a separate persona module | 25% |
| 37 | Insight dashboard | Mostly pending as a separate persona module | 25% |
| 38 | Rewards for referrals and redemption | Largely pending | 20% |
| 39 | Direct walk-in routing and referral workflow | Largely pending | 20% |

### Sales

| ID | Requirement | Current State | Completion |
| --- | --- | --- | --- |
| 40 | Sales login/self onboarding with profile details | Exists through sales-agent roles and governance | 75% |
| 41 | Onboard shopkeeper or homepreneur with subscription | Lead onboarding services exist | 80% |
| 42 | Subscription and payment with a 12-month mandate | Partial; mandate workflow is not explicit | 35% |
| 43 | Analytics by pincode, including attribution to the logged-in sales person | Partial sales analytics and attribution exist | 70% |
| 44 | Incentive data | Partial support through rewards and metrics | 40% |

### Analytics and Admin

| ID | Requirement | Current State | Completion |
| --- | --- | --- | --- |
| 45 | Analytics dashboard showing shops, homepreneurs, and customers by city and pincode | User/shop counts exist; analytics UI is partial | 70% |
| 46 | Shop approval | Implemented | 100% |
| 47 | Banner approval | Mostly pending | 25% |
| 48 | Campaign approval | Partial | 35% |
| 49 | Coupon monitoring | Implemented | 100% |
| 50 | Regional dashboard | Partially available | 65% |
| 51 | Payment monitoring | Partial | 60% |
| 52 | Pricing engine | Largely implemented | 80% |
| 53 | Premium filter setup | Mostly pending | 30% |
| 54 | Channel multiplier | Partial | 65% |
| 55 | Subscription fee | Largely implemented | 90% |
| 56 | Coupon creation | Implemented | 100% |
| 57 | Agent management | Implemented | 100% |
| 58 | Revenue dashboard | Exists; deeper finance analytics can improve | 70% |
| 59 | Customer analytics | Partial | 60% |
| 60 | Fraud detection | Partial | 50% |
| 61 | Notification system | Exists; richer push/event orchestration is partial | 70% |

### Additional Customer and Shopkeeper Items

| ID | Requirement | Current State | Completion |
| --- | --- | --- | --- |
| 62 | Customer banner interaction analytics | Banner display exists; interaction analytics is partial | 55% |
| 63 | Customer notifications inbox with unread/read states | Implemented | 90% |
| 64 | Shopkeeper pricing preview | Implemented | 80% |
| 65 | Shopkeeper payment | Implemented | 90% |
| 66 | Shopkeeper coupon issue | Implemented | 90% |
| 67 | Shopkeeper performance tracking | Partial | 75% |
| 68 | Shopkeeper unique code for coupons/redemption | Implemented | 85% |
| 69 | Shopkeeper shop referral | Partial | 60% |
| 70 | Shopkeeper incentive earning | Partial | 70% |

## Gaps To Prioritize

1. Customer retention and loyalty tiers.
2. Homepreneur as a first-class persona with full onboarding, subscription, campaign, dashboard, and rewards flows.
3. Customer social features, especially photo reviews and favorite-shop following.
4. Search, ranking, and personalization improvements for offers and shops.
5. Admin approval workflows for banners and campaigns.
6. Stronger analytics and fraud controls across customer, shopkeeper, and sales journeys.

## Delivery Timeline Estimate

Assumption: this estimate is for completing the remaining client-facing requirements in the workbook with an active product/design/dev workflow and no major scope expansion.

### Overall Estimate

- Final delivery timeline is fixed at 45 days from the planned start date (April 8, 2026).
- The phase split below divides the 45 days across feature delivery, hardening, and stabilization.

### Suggested Phases

| Phase | Focus | Estimated Time | Calendar Range |
| --- | --- | --- | --- |
| Phase 1 | Customer gap closure: retention tiers, social features, stronger search/filtering, shop profile completion | 12 days | First 12 days |
| Phase 2 | Homepreneur as a first-class persona: onboarding, subscription, business setup, QR payment, offers, campaigns, dashboard | 15 days | Next 15 days |
| Phase 3 | Admin and analytics hardening: banner/campaign approval, fraud detection, premium filters, reporting improvements | 10 days | Next 10 days |
| Phase 4 | QA, bug fixing, regression testing, and release stabilization | 8 days | Final 8 days |

### Practical Delivery View

- Target completion window (45-day plan): end of Day 45 from project kickoff.
- If scope increases during execution, phase boundaries should be re-baselined but the current plan assumes strict scope control.

## Notes

- Some workbook rows describe aspirations rather than finished tickets, so the completion percentage is the best indicator of implementation state.
- A few entries use wording like "shop" while the product flow uses "offers"; those should be normalized in the final product spec before implementation planning.
- The workbook mixes implemented functionality with roadmap ideas, so this document should be treated as a requirements baseline, not a release plan.