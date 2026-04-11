# MyOffers Current State Diff Report

Version: 1.0
Date: 2026-04-06
Purpose: Show current state vs required target state derived from workbook and Phase 2 direction.

## 1. Diff Summary

Overall status:
- Foundation and baseline workflows: mostly complete
- Growth and monetization robustness: partially complete
- Full workbook-aligned operating model: not yet complete

Estimated maturity:
- Baseline platform: 75%
- Workbook-aligned commercial + scale model: 40-45%
- Net readiness for target robust state: ~55%

## 2. Capability-Wise Diff Matrix

| Capability Block | Current State | Target State | Gap Level | Priority |
|---|---|---|---|---|
| Role-based core platform | Stable | Stable + performance hardened | Low | Medium |
| Subscription lifecycle | Live | Tier matrix + entitlement automation | Medium | High |
| Category-wise pricing | Partial/manual | Full rule engine by category/segment | High | Critical |
| Banner duration pricing | Mentioned but incomplete | 1/7/30-day automated pricing | High | Critical |
| Campaign estimator | Basic | Channel + audience + duration + geo aware | High | Critical |
| App inbox campaign channel | Live | Live + audited + scalable | Medium | High |
| WhatsApp campaign channel | Partial | Fully operational with retries and metrics | High | Critical |
| Push campaign channel | Not complete | Production ready | High | High |
| Email campaign channel | Not complete | Production ready | High | High |
| Campaign delivery visibility | Partial | End-to-end funnel tracking | High | Critical |
| AI copy assist | Partial | Integrated, multilingual, tone-controlled | Medium | High |
| AI banner assist | Partial | Entitlement-aware and campaign-embedded | Medium | High |
| Risk/churn signaling | Not fully implemented | Proactive alerting and action cues | High | High |
| Query + cache scaling | Planned | Implemented and monitored with SLOs | High | Critical |
| Theme token compliance | In progress | Fully tokenized with role-screen QA | Medium | High |

## 3. Detailed Gap Notes

### 3.1 Monetization Gaps

Observed:
- Strong subscription base exists.
- Tier and entitlement expressions are not fully codified to workbook complexity.
- Category and geo-segment pricing still need full config and governance tooling.

Required:
- Central pricing rule engine.
- Admin UI for pricing matrix maintenance.
- Versioned pricing rules with audit trails.

### 3.2 Campaign and Channel Gaps

Observed:
- In-app campaign baseline exists.
- Omnichannel channels are not all at production readiness.

Required:
- Channel adapter framework for WhatsApp/Push/Email.
- Reliable retry/backoff and failure handling.
- Channel-wise metrics that feed campaign ROI dashboard.

### 3.3 Intelligence and AI Gaps

Observed:
- AI capabilities exist in isolated forms.
- AI is not yet deeply embedded in campaign flow decisions.

Required:
- In-flow AI copy/creative assistant.
- Post-campaign recommendations.
- Explainable AI reason codes for operator trust.

### 3.4 Scale and Reliability Gaps

Observed:
- Phase 2 docs already identify optimization needs.
- Current architecture needs hardening for workbook city-scale assumptions.

Required:
- Query tuning and indexes for campaign analytics.
- Redis caching for read-heavy endpoints.
- Queue isolation for dispatch workloads.
- P95/P99 latency and queue lag monitoring.

## 4. Delivery Delta by Sprint

| Sprint | Key Delta Closed |
|---|---|
| Sprint 1-2 | Pricing rulebook + schema/API freeze + governance baseline |
| Sprint 3-4 | Category and duration pricing engine + estimator upgrade |
| Sprint 5-6 | Omnichannel reliability and channel-level status |
| Sprint 7-8 | Funnel analytics and dashboarding |
| Sprint 9-10 | AI assistant embedding and recommendations |
| Sprint 11-12 | Scale hardening, QA closure, UAT, launch prep |

## 5. Cost Delta View

To close identified gaps from current state to robust workbook-ready state:
- Minimum practical budget: INR 36 lakh
- Recommended budget: INR 42 lakh
- Risk-buffer budget: INR 47 lakh

## 6. Decision Items Blocking Faster Progress

1. Final pricing slabs and tier names.
2. Mandatory channels for day-1 launch.
3. AI scope lock for first release.
4. KPI definitions for campaign ROI and merchant success.

## 7. Final Assessment

Your current product is significantly ahead of an early-stage build and has enough maturity to justify a focused, execution-heavy Phase 2.

The primary gap is no longer foundational engineering; it is productization depth in monetization, omnichannel reliability, analytics intelligence, and scale-readiness.

This diff report should be treated as the implementation baseline for the next commercial proposal and execution kickoff.