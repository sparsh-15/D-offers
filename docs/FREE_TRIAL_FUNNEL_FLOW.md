# Free + Trial Funnel Flow Diagram

```mermaid
flowchart TD
    A[New or Existing Shopkeeper] --> B{Onboarding Complete?}
    B -- No --> B1[Complete Profile + Accept Terms]
    B1 --> B

    B -- Yes --> C[Fetch Subscription State]
    C --> D{Active Paid Plan?}

    D -- Yes --> P1[Use Existing Silver/Gold/Platinum\nNo pricing logic changes]
    P1 --> P2[Full paid entitlements by current plan]

    D -- No --> E{Trial Already Used\nphone + business fingerprint?}

    E -- No --> T1[Auto-Activate 7-day Trial]
    T1 --> T2[Gold-like access layer\n- Campaign builder\n- Audience targeting\n- WhatsApp with category cap]

    E -- Yes --> F1[Activate/Keep Free Starter]

    T2 --> T3{Trial Expired?}
    T3 -- No --> T4[Continue trial within caps]
    T3 -- Yes --> F1

    F1 --> F2[Free Starter entitlements\n- 1 active offer\n- 1 AI banner/month\n- 20 inbox msgs\n- 0 WhatsApp\n- Basic analytics]

    %% Enforcement points
    T4 --> G[User Action]
    F2 --> G
    P2 --> G

    G --> H{Action Type}

    H -- Create Offer --> O1{Offer limit exceeded?}
    O1 -- No --> O2[Allow]
    O1 -- Yes --> U1[Show upgrade paywall + recommended plans]

    H -- Generate AI Banner --> AI1{AI credits/limit available?}
    AI1 -- Yes --> AI2[Allow]
    AI1 -- No --> U2[Show upgrade nudge on banner limit hit]

    H -- Send Campaign --> C1{Channel/Quota allowed?}
    C1 -- Yes --> C2[Allow pay + launch]
    C1 -- No --> U3[Show paywall\nwith reason + recommended plans]

    H -- View Analytics --> A1{analyticsEnabled?}
    A1 -- Yes --> A2[Show full analytics]
    A1 -- No --> U4[Show analytics lock card + upgrade CTA]

    %% Conversion loop
    U1 --> X[Open Subscription Plans]
    U2 --> X
    U3 --> X
    U4 --> X

    X --> Y{User buys paid plan?}
    Y -- Yes --> P1
    Y -- No --> F2
```

## Notes
- Paid plans remain unchanged; Free and Trial act as acquisition layers.
- Trial is one-time per business using phone + hashed business fingerprint.
- Trial WhatsApp cap is category-wise and configurable via app settings.
- Post-trial fallback is automatic to Free Starter.
