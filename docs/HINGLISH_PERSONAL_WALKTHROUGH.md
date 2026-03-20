# D-OFFERS Personal Walkthrough (Hinglish, Casual)

Purpose: Ye doc personal understanding ke liye hai. Isme app ka full flow simple Hinglish mein explain hai: user kya karta hai, next screen kya hoti hai, aur kis role ke paas kya powers hain.

## Quick 5-Minute Samajh

- App 6 roles handle karta hai: Customer, Shopkeeper, SSA, CSA, Subadmin, Super Admin.
- Entry sabka same: phone -> OTP -> role based landing.
- Customer offers dekhta hai (location based bhi), favorite karta hai.
- Shopkeeper onboarding + subscription payment ke baad offers create karta hai.
- SSA/CSA leads banate hain, coupon flow chalate hain, shopkeeper onboarding push karte hain.
- Admin/Super Admin governance, users, coupon, analytics aur audit dekhte hain.

## Role Cheat Sheet

- Customer: Offers browse, filter, favorite, profile, Become SSA option.
- Shopkeeper: Shop profile, subscription plans, payment, offers manage.
- SSA: Field leads, invite OTP retry, customer view se SSA view toggle.
- CSA: Company-level lead and shop pipeline, coupon usage.
- Subadmin: Dashboard, users, reports, subscription governance.
- Super Admin: Sabka top control, agent governance, audit, coupon cap settings.

## End-to-End Entry Flow (Sabke liye)

1. Splash screen open hota hai.
2. Login screen pe phone number enter.
3. OTP send hota hai.
4. OTP verify hota hai.
5. Agar new user hai to signup + role selection flow lagta hai.
6. OTP success ke baad role ke hisab se dashboard open.

Common confusion:
- Same phone se alag role login expect mat karo unless backend role mapping allow kare.
- OTP fail ho to resend ka wait timer follow karo.

## New User vs Existing User

### Existing user

- Phone enter -> OTP -> verify -> direct dashboard.

### New user

- Sign up -> role select -> basic details fill -> OTP -> verify -> role destination.
- Shopkeeper ke case mein coupon code capture ho sakta hai signup time pe.

## Customer Journey (Simple)

### Home and offers

1. Customer dashboard pe land.
2. Offers tab open karo.
3. Search, sort, filter lagao.
4. Offer details dekho, like/favorite karo.

### Location based offers

1. Use Current Location button/chip tap karo.
2. Permission allow karo.
3. App city + pincode detect karta hai.
4. Offers auto-refresh ho jate based on current location.

Tips:
- Location off hai to app profile location ya manual filters pe fallback karega.
- Filter clear karke raw feed check karna easy debugging trick hai.

## Shopkeeper Journey (Most Important Business Flow)

### First-time shopkeeper

1. Login/OTP ke baad onboarding check hota hai.
2. Agar onboarding incomplete hai to profile details fill karni hoti hain:
- shop name
- pincode
- city/state
3. Subscription plan select karna mandatory hota hai (app configuration ke hisab se).
4. Payment flow complete karo.
5. Success ke baad Shop Dashboard unlock.

### Shop dashboard actions

- Home: quick summary.
- Offers tab: add/edit/manage offers.
- Leads tab: incoming lead context.
- Profile tab: subscription status and other controls.

## Subscription and Payment Flow (As-is)

1. Plan select (example tiers: Basic/Premium/Enterprise; project notes me platinum/gold/silver ideas bhi mention hain).
2. Payment screen open.
3. Method choose:
- UPI
- Card
- Net Banking
4. Form validation pass karo.
5. Process payment click.
6. Simulated processing hoti hai.
7. Success dialog aata hai.
8. Callback se previous flow continue and subscription active state reflect hoti hai.

Personal note:
- Ye abhi dummy/simulated gateway pattern lag raha hai, but UI and validation flow real gateway jaisa structured hai.

## Coupon and Lead Flow (SSA/CSA -> Shopkeeper)

1. SSA/CSA lead create karta hai (phone + name + optional coupon).
2. Backend first-lead-wins logic use karta hai.
3. Invite OTP send ho sakta hai.
4. Shopkeeper OTP verify karke app me aata hai.
5. Signup coupon/subscription quote pe discount apply ho sakta hai.
6. Payment successful -> shopkeeper active.

Why important:
- Ye revenue + acquisition dono flow ka center hai.

## SSA Journey

1. SSA login ke baad customer dashboard pe land kar sakta hai.
2. Profile/toggle se SSA dashboard switch.
3. Shopkeepers/leads tab me:
- Create lead
- Retry invite OTP
- Lead status track

## CSA Journey

1. CSA dashboard open hota with stats.
2. Leads, my shops, reports and coupons handle karta.
3. Lead creation shared form pattern follow karta (SSA jaisa core behavior).

## Admin and Super Admin Walkthrough

### Subadmin

- Dashboard metrics
- Users management
- Reports
- Subscription governance
- Agent & coupon governance screens

### Super Admin

- System-level analytics
- User and shop control
- Audit logs
- SSA/CSA creation governance
- Coupon activations and cap settings

## Current Implementation Snapshot (based on tracker notes)

- Agent and coupon governance screens completed.
- Create SSA and create CSA forms completed.
- Pincode-based autofill integration completed in relevant forms.
- Payment integration UI flow completed (simulated processing).
- Customer location flow completed (GPS + reverse geocoding + pincode/city usage).

## Real-Life Use Cases (Easy Memory)

- Use case 1: Customer nearby offers chahata hai -> location on -> city/pincode offers.
- Use case 2: Shopkeeper lead se app me aya -> OTP -> onboarding -> plan pay -> offers publish.
- Use case 3: Admin ko governance karni hai -> users/coupons/agents/report dashboard.

## Troubleshooting (Non-technical language)

- OTP nahi aa raha:
- phone format check karo
- resend timer wait karo
- network/SMS issues check karo

- Location detect nahi ho rahi:
- GPS on karo
- app permission allow karo
- settings se location permission manually enable karo

- Payment button kaam nahi kar raha:
- required field blank ho sakti hai
- selected method ke validation rules pass karo

- Role mismatch aa raha:
- backend me role assignment check karna padega

## Short Glossary

- OTP: One Time Password for login verify.
- Lead: Potential shopkeeper/user entry created by SSA/CSA.
- Onboarding: Initial profile setup steps.
- Governance: Admin controls for users/coupons/agents.
- Subscription Quote: Plan + coupon ke baad final payable amount.

## Practical Remember Formula

- Entry same, destination role-based.
- Customer value = discover offers fast.
- Shopkeeper value = onboard + subscribe + publish offers.
- SSA/CSA value = leads and conversion.
- Admin value = governance and visibility.

---

If you revise product tiers (jaise platinum/gold/silver, per-banner pricing, 7-day/30-day category pack), is doc ke subscription section me ek dedicated "Pricing Model v2" add karke maintain karna best rahega.
