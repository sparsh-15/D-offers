# MyOffers Workbook to Execution Master Plan

Version: 1.0
Date: 2026-04-06
Prepared For: Product and Business Stakeholders
Prepared From: workbook in docs/pnl.xlsx + current project documentation

## 1. Executive Summary

This document converts the uploaded workbook assumptions into an implementation-grade execution plan for MyOffers, aligned with the current product state.

Current reality:
- Foundation platform is largely live (roughly 70-80% of baseline rails complete).
- Core role system, onboarding, subscriptions, offers, redemptions, and campaign baseline are in place.
- Phase 2 growth modules (omnichannel, advanced analytics, AI productivity, risk signals, and robust monetization controls) are partially done and need structured completion.

Primary outcome required now:
- Move from "working platform" to "measurable growth platform" with predictable campaign ROI, clear packaging, and operational reliability.

## 2. Source Inputs Used

Business/financial assumptions from workbook:
- City expansion over 24 months across Tier1/Tier2/Tier3/Tier4.
- Category-wise subscription and banner pricing for 4 seller segments:
  - Local shops
  - Brands (Pan India)
  - Brands (State)
  - Brands (City)
- Geographic dominance rules by category (Pan India / State / City / Pincode).
- Campaign cost coefficients by audience size and channel (WhatsApp/App inbox).
- Sales and non-sales manpower assumptions.
- Marketing + app/server/LLM/admin cost lines.

Current-system references:
- docs/MYOFFERS_PHASE2_BACKLOG_AND_NEXT_ROBUST.md
- docs/MYOFFERS_PHASE2_IMPLEMENTATION_BRIEF.md
- trackerphaseswise.md
- docs/MYOFFERS_COMPLETE_SYSTEM_DOCUMENTATION.md

## 3. What the Workbook Means in Product Terms

### 3.1 Go-to-Market Expansion Model

Workbook indicates staged expansion from 1 city to 150 cities over 24 months, with weighted tier contribution:
- Tier1 weight: 40%
- Tier2 weight: 30%
- Tier3 weight: 20%
- Tier4 weight: 10%

Product implication:
- Region-targeting and city-state hierarchy must be robust, auditable, and easy for operators.
- Campaign planning and dispatch must support scale without degrading latency.

### 3.2 Monetization Design

Workbook pricing requires:
- Category-level pricing slabs.
- Plan and entitlement logic by seller type and geography scope.
- Banner pricing by duration (1-day, 7-day, 30-day).
- Differentiated pricing for local vs city/state/pan-India brands.

Product implication:
- Pricing engine + entitlement matrix cannot remain manual.
- Need rule-based pricing APIs and plan governance UI.

### 3.3 Campaign Economics Model

Workbook includes audience-size to channel-cost factors (WhatsApp and App inbox). This implies:
- Campaign estimator must calculate price by:
  - channel mix
  - audience count
  - category and seller segment
  - duration and geo scope

Product implication:
- Existing campaign flow should be upgraded from simple dispatch to a full campaign commerce flow.

### 3.4 Operating Model

Workbook adds manpower productivity and salary assumptions.

Product implication:
- Need role-level productivity dashboards and intervention tooling.
- Need process automation for repetitive campaign/approval tasks.

## 4. Current Product Situation (Ground Truth)

### 4.1 Strongly Implemented (Keep and Extend)

- Multi-role auth and role-aware dashboards.
- Core onboarding rails for shopkeeper/customer/agents.
- Offer lifecycle and redemption loop.
- Subscription and trial rails.
- Campaign draft, estimate, payment, queue, and in-app dispatch baseline.
- AI credit-pack rail and early AI support features.
- Agent governance and coupon governance (with admin actions and forms).

### 4.2 Partially Implemented / Incomplete

- Omnichannel dispatch is not fully production-complete.
- Campaign analytics depth is limited for business operators.
- AI execution assistant is present in pieces but not fully embedded into campaign workflow.
- Theme unification and token compliance are in progress.
- Pricing slab engine and category-wise banner commerce still need hard implementation.

### 4.3 Not Yet Productized to Workbook Standard

- Full entitlement-aware pricing matrix automation.
- Per-channel and per-stage campaign funnel analytics (delivered/opened/clicked/converted).
- Risk layer (abuse, churn, underperformance flags) with actionability.
- Robust query optimization and cache-backed scale posture for high growth.

## 5. Target Scope to Reach Workbook Readiness

### Stream A: Monetization and Pricing Engine
- Subscription tiers: Silver/Gold/Platinum with explicit entitlement matrix.
- Category + segment-based pricing configuration.
- Banner pricing by 1-day, 7-day, 30-day durations.
- Pricing simulator in campaign builder.
- Governance controls and audit logs for pricing changes.

### Stream B: Omnichannel Campaign Execution
- Production dispatch adapters for App inbox, WhatsApp, Push, Email.
- Retry logic, failure taxonomy, DLQ (dead-letter queue) strategy.
- Per-channel delivery and engagement tracking.

### Stream C: Campaign Intelligence and Operator Layer
- Funnel metrics and campaign score.
- Role-wise dashboards for Admin/SSA/CSA/Shopkeeper.
- Location/category performance breakdown.
- Alerts for underperformance and intervention recommendations.

### Stream D: AI Execution Assistant
- AI copy generation with tone controls and multilingual support.
- AI creative generation tied to plan entitlements and AI credits.
- AI suggestions: best send time, relaunch, retarget, upgrade prompts.

### Stream E: Reliability and Scale
- Query optimization and index strategy for campaign/analytics.
- Redis cache strategy for read-heavy APIs.
- Async job orchestration for dispatch/AI/analytics tasks.
- Observability SLO dashboards and runbooks.

### Stream F: Theme and Product UX Hardening
- Tokenized theme system (no hardcoded colors).
- Light/dark/brand parity checks across key role journeys.
- Campaign and onboarding UX simplification for conversion.

## 6. Detailed Delivery Plan and Timeline

Assumption: single focused execution track with parallel squads where feasible.

### Phase 0: Planning and Architecture Freeze (Week 1-2)
- Final requirement sign-off from workbook and stakeholder notes.
- Pricing rulebook finalization.
- Data model and API contract freeze for monetization + campaign analytics.
- Delivery governance setup (scope baseline, demo cadence, risk board).

Deliverables:
- Signed PRD + Technical Design Pack
- Epic backlog with acceptance criteria
- Baseline effort and release plan

### Phase 1: Core Monetization + Campaign Commerce (Week 3-6)
- Implement category/segment pricing engine.
- Add duration-based banner pricing and plan matrix.
- Upgrade campaign estimator and checkout calculations.
- Admin pricing governance screens.

Deliverables:
- Monetization APIs v2
- Pricing governance module
- Campaign estimate v2 (audience x channel x duration)

### Phase 2: Omnichannel + Tracking (Week 7-10)
- Complete WhatsApp/Push/Email channel adapters.
- Add dispatch reliability (retry/backoff/failure classification).
- Build channel-wise status and campaign-level timeline.

Deliverables:
- Omnichannel dispatch service
- Delivery status APIs
- Channel observability board

### Phase 3: Analytics + AI Assistant (Week 11-15)
- Campaign funnel analytics and scoring.
- AI copy + AI creative integration in campaign flow.
- Role-wise action recommendations.

Deliverables:
- Campaign intelligence dashboard
- AI assistant widgets in campaign setup and post-campaign view
- Alerting for low-ROI / churn risk signals

### Phase 4: Performance, QA, UAT, and Launch (Week 16-18)
- Query and cache optimization.
- Load/performance testing and failover drills.
- Security, regression, and UAT closure.
- Production rollout with rollback controls.

Deliverables:
- Performance baseline and SLO sign-off
- Release readiness report
- Production go-live and hypercare plan

Total timeline:
- 18 weeks (approximately 4.5 months)

## 7. Team Plan (Recommended)

Core team:
- 1 Delivery Manager / Product Owner
- 1 Solution Architect / Tech Lead
- 2 Backend Engineers
- 2 Flutter Engineers
- 1 QA Automation + Manual
- 1 DevOps/Platform Engineer (part-time)
- 1 Data/AI Engineer (part-time)

## 8. Commercial Estimate (Project Price)

### 8.1 Build Cost Estimate (Engineering)

For the 18-week scope above:
- Conservative estimate: INR 36,00,000
- Most likely estimate: INR 41,00,000
- Buffer-inclusive estimate: INR 47,00,000

Recommended quote to client:
- INR 42,00,000 + taxes

### 8.2 Payment Milestone Suggestion

- 20% on kickoff and architecture freeze
- 25% after monetization + campaign commerce milestone
- 25% after omnichannel dispatch milestone
- 20% after analytics + AI milestone
- 10% on UAT sign-off and production launch

### 8.3 Optional Post-Launch AMC (monthly)

- INR 2,50,000 to INR 4,00,000 per month based on SLA and enhancement bandwidth.

## 9. Risk Register (Top Risks and Mitigation)

1. Scope inflation during implementation.
Mitigation: strict change request process and frozen baseline after Week 2.

2. Third-party channel reliability (WhatsApp/Email/Push providers).
Mitigation: adapter abstraction + retry policy + fallback + monitoring.

3. Data quality for campaign analytics.
Mitigation: event schema governance + analytics QA + reconciliation jobs.

4. Performance under city-scale expansion.
Mitigation: phased load tests, indexing plan, queue isolation, Redis caching.

5. AI output quality and cost control.
Mitigation: prompt templates, guardrails, model fallback, token/cost budget caps.

## 10. Recommended Next Decision Pack (Jabalpur Brainstorm Ready)

Before kickoff, align these 6 decisions:
1. Final pricing slabs and tier names to lock in code.
2. First-wave channels for production launch (mandatory vs optional).
3. AI scope for V1 launch vs V1.1.
4. Reporting KPIs that define merchant ROI.
5. Non-negotiable UAT scenarios by role.
6. Commercial model (fixed-scope fixed-price vs phase-wise billing).

## 11. Practical Conclusion

The platform is not starting from zero; foundation maturity is already strong. This plan focuses on converting the existing 70-80% implementation into a robust, monetization-ready, and scale-ready product.

With disciplined scope control, a production-grade release is achievable in 18 weeks with an estimated project price of approximately INR 42 lakh (+ taxes).