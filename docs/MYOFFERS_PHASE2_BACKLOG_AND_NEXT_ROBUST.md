# MyOffers Phase 2 Backlog, Maintenance, and Pricing Template

## 1) Phase 2 Goal

Phase 2 will convert the current stable platform into a measurable growth engine with:

- higher campaign reach
- clearer merchant ROI
- stronger AI-led execution
- tighter operational governance

## 2) What Is Already Stable (Do Not Rebuild)

- role-based auth and OTP login
- core onboarding for customer, shopkeeper, SSA, and CSA
- subscription lifecycle and governance base
- offer creation and redemption loop
- AI packs and AI credit usage rails
- test-data bulk APIs for rapid QA/demo setup

## 3) Remaining Backlog (High Priority)

### Campaign and Growth

- enable channel expansion beyond in-app inbox: WhatsApp, push, email
- campaign details redesign with cleaner operator-friendly layout
- campaign list to campaign detail direct action flow
- city and state targeting flow hardening (state dropdown then city)
- campaign-level and channel-level delivery status visibility

### Shopkeeper and Sales Operations

- loan document attachment completion and validation consistency
- bank fields and penny-drop readiness for onboarding and agent flows
- sales agent profile enhancement (working-hours field and quality scoring)
- shopkeeper performance indicators: coins earned, sales closed, rating

### Monetization and AI Packaging

- plan-tier entitlements fully explicit (silver/gold/platinum feature matrix)
- category-wise banner purchase module with clean pricing slabs
- per-banner and duration-based pricing variants (example: 7-day, 30-day)
- upgrade nudges at trigger points: send attempt, analytics view, limit hit

### Reliability and Product Hygiene

- reduce verbose helper text in heavy forms for better completion rate
- unify contrast and quality defaults for AI-generated banner assets
- complete QR-led shopkeeper onboarding to customer linkage flow

## 4) What We Add Next (Net New)

### A. Omnichannel Dispatch Engine

- unified campaign dispatch abstraction for inbox/WhatsApp/push/email
- channel adapters with retries, failure classification, and dead-letter handling
- merchant-visible per-channel performance summary

### B. Campaign Intelligence Layer

- delivery funnel: sent, delivered, opened, clicked, converted
- campaign performance scoring and underperformance flags
- audience and pincode-level performance breakdown

### C. AI Execution Assistant for Shopkeepers

- one-click AI copy suggestions per offer type
- AI banner generation with entitlement-aware options
- post-campaign AI suggestions: when to relaunch, retarget, or upgrade

### D. Retention and Risk Signals

- subscription churn risk markers
- campaign inactivity and low-ROI warnings
- suspicious claim/redemption pattern alerts for review

## 5) Client-Requested Theme Shift for Current App

### Objective

- update the current app theme based on client feedback
- replace the previous look and feel without breaking existing screens or flows
- standardize the visual system for readability, accessibility, and brand consistency

### Scope

- global theme architecture in the current client app: light, dark, and brand themes
- dynamic tokens for colors, spacing, typography, radius, and elevation
- role-aware theme presets (Admin/SSA/CSA/Shopkeeper/Customer)
- screen-level validation for campaign, onboarding, payments, analytics, and AI flows
- persistent preference storage and fallback to system theme

### Non-Negotiable Rules

- single token source only; no hardcoded colors in feature screens
- minimum contrast validation for key CTAs, alerts, and form states
- all newly added screens must pass light/dark/brand smoke checklist
- AI-generated banner preview must be theme-safe and contrast-safe

### Deliverables

- Theme token map and naming conventions
- Theme migration checklist for existing screens
- Theme QA matrix by role and platform (Android/iOS/Web)
- rollback flags for theme rollout control

## 6) Leftover AI Additions (Must Add)

### AI for Campaign Creation

- multilingual AI copy generation by category and audience type
- AI headline + description + CTA variants with quality scoring
- AI tone controls: formal, local, festive, urgency, premium

### AI for Creative and Optimization

- entitlement-aware AI banner generation with template controls
- AI suggestion engine for best send time and best channel mix
- AI auto-relaunch recommendations for low-performing campaigns

### AI for Risk and Governance

- anomaly detection for suspicious redemption behavior
- churn-risk prediction for inactive or low-ROI merchants
- AI reason-codes attached to alerts for operator actionability

### AI for Operator Productivity

- assistant prompts for SSA/CSA next-best action guidance
- auto-summary of weekly campaign performance and interventions
- explainable AI notes in campaign details for trust and audit

## 7) Query Optimization, Scalability, and Caching Module

### Database Query Optimization

- optimize campaign list/detail queries for high-cardinality filters
- add composite indexes for role, city, state, category, and status lookups
- optimize pagination using cursor strategy for heavy traffic datasets
- prevent N+1 query patterns in campaign analytics and delivery stats

### Scalability Architecture

- split read-heavy analytics paths from write-heavy transaction paths
- enforce async processing for dispatch retries, delivery updates, and AI jobs
- add queue-based workload isolation for campaign dispatch by channel
- introduce rate-limit and backpressure controls for burst campaign loads

### Caching Strategy

- Redis caching for campaign detail, plan entitlements, and category metadata
- cache invalidation hooks on campaign update, entitlement change, and redemption
- short TTL for volatile delivery counters; longer TTL for reference masters
- API response caching for high-frequency dashboard widgets

### Reliability and Observability

- P95/P99 latency targets for campaign and analytics endpoints
- query performance dashboard: slow query log, hit ratio, cache miss ratio
- load test scenarios for city/state segmented campaigns and omnichannel sends
- fallback behavior defined for cache outage and queue lag

## 8) Timelines and Milestones (Execution Plan)

### Sprint 1 (Week 1-2)

- finish omnichannel baseline and campaign detail UX hardening
- implement theme tokenization foundation and theme toggle persistence
- start query audit and identify top slow endpoints

### Sprint 2 (Week 3-4)

- ship role-wise theme presets and migrate high-traffic screens
- release first AI copy and banner assistant capabilities
- deploy first-stage Redis caching for read-heavy endpoints

### Sprint 3 (Week 5-6)

- launch campaign intelligence scoring and underperformance flags
- complete queue-based dispatch retries and failure classification
- optimize analytics queries and introduce cursor pagination

### Sprint 4 (Week 7-8)

- release churn-risk and suspicious pattern alerts
- finalize AI recommendation loop (relaunch/retarget/upgrade)
- complete load testing, SLO review, and runbook finalization

## 9) Updated Phase 2 Done Criteria

- merchant can execute and measure omnichannel campaigns with reliable delivery visibility
- full theme system is production-ready across key roles and key screens
- pending AI capabilities are live with measurable time-to-launch improvement
- backend supports scalable load with optimized queries and cache-backed reads
- dispatch, analytics, and AI flows have observability, auditability, and rollback safety

## 10) Maintenance and Monthly Pricing

This section can be used as the base service template for ongoing support after Phase 2 rollout.

### Maintenance Scope (What We Do)

- production support and issue resolution for live campaigns, analytics, AI, and payments
- production monitoring for campaign, analytics, AI, and payment flows
- bug fixing for reported issues with priority-based turnaround
- minor enhancements for forms, dashboards, and operator usability
- API and database health checks, query optimization, and cache tuning
- periodic index review and slow-query cleanup for high-traffic endpoints
- pagination and filter optimization for campaign and analytics screens
- queue and dispatch reliability checks including retry and failure handling
- proactive error handling hardening (API, validation, and async job failures)
- log review and alert tuning to reduce repeat production incidents
- security patching, dependency updates, and access/audit review
- release support for hotfixes and scheduled updates
- controlled rollout support with rollback checks for risky deployments
- small feature additions and low-complexity change requests as part of monthly maintenance cycle
- monthly performance and stability report with action items

### Maintenance Notes

- maintenance covers routine support, fixes, and small improvements only
- new modules, large redesigns, and major feature builds are handled as separate estimates
- priority and turnaround can be aligned with the operational severity of the issue

### Commercial

- combined monthly pricing for both implementation support and maintenance: INR 60,000 per month
- pricing includes routine maintenance, bug fixes, monitoring, performance tuning, and minor feature additions
- payment terms: monthly billing, invoiced at the start of each month
- pricing basis: one combined support plan for implementation assistance plus maintenance coverage
- exclusions: major new modules, large feature rebuilds, and scope-heavy changes are estimated separately
