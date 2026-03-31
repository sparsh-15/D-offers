# MyOffers - Complete System Documentation

**Version:** 1.0.0  
**Last Updated:** February 20, 2026  
**Platform:** Multi-role Digital Offers Marketplace

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [System Architecture](#system-architecture)
3. [Technology Stack](#technology-stack)
4. [User Roles & Permissions](#user-roles--permissions)
5. [API Documentation](#api-documentation)
6. [Frontend Architecture](#frontend-architecture)
7. [Backend Architecture](#backend-architecture)
8. [Database Schema](#database-schema)
9. [External Services](#external-services)
10. [AI Integration](#ai-integration)
11. [Security & Authentication](#security--authentication)
12. [Subscription & Monetization](#subscription--monetization)
13. [Workflow Diagrams](#workflow-diagrams)
14. [Development Phases](#development-phases)
15. [Color Theme & Design System](#color-theme--design-system)
16. [Deployment & DevOps](#deployment--devops)

---

## Executive Summary

MyOffers is a comprehensive digital marketplace platform connecting shopkeepers with customers through location-based offer discovery. The platform implements a sophisticated 6-role RBAC system, subscription-based monetization for shopkeepers, and a complete onboarding workflow.

### Key Features
- **Multi-role Access Control**: 6 distinct user roles with granular permissions
- **Subscription Management**: Freemium model with trial and paid plans
- **Offer Management**: Create, publish, and manage promotional offers
- **Location-based Discovery**: Pincode-based offer filtering
- **Audit Logging**: Complete activity tracking for compliance
- **AI Integration**: Personalized recommendations and chatbot (in development)
- **Real-time Analytics**: Dashboard insights for all roles

### Business Model
- Freemium subscription for shopkeepers
- 7-day free trial
- Monthly plans: Basic (₹499), Premium (₹999), Enterprise (₹2499)
- Revenue from shopkeeper subscriptions

---


## System Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        CLIENT LAYER                              │
│  Flutter/Dart Mobile App (Android, iOS, Web)                    │
│  ┌──────────┬──────────┬──────────┬──────────┬──────────┐      │
│  │ Customer │Shopkeeper│  Admin   │Super Admin│   SSA    │      │
│  │Dashboard │Dashboard │Dashboard │ Dashboard │Dashboard │      │
│  └──────────┴──────────┴──────────┴──────────┴──────────┘      │
└─────────────────────────────────────────────────────────────────┘
                              ↓ HTTPS/REST API
┌─────────────────────────────────────────────────────────────────┐
│                      API GATEWAY LAYER                           │
│  Express.js Server (Node.js)                                     │
│  ┌──────────────┬──────────────┬──────────────┐                │
│  │ Rate Limiter │ Auth Middleware│ Role Check  │                │
│  └──────────────┴──────────────┴──────────────┘                │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                   BUSINESS LOGIC LAYER                           │
│  Controllers & Services                                          │
│  ┌────────┬────────┬────────┬────────┬────────┬────────┐       │
│  │  Auth  │ Offer  │  Sub   │Onboard │ Admin  │ Upload │       │
│  └────────┴────────┴────────┴────────┴────────┴────────┘       │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                        DATA LAYER                                │
│  MongoDB (Mongoose ODM)                                          │
│  ┌────────┬────────┬────────┬────────┬────────┬────────┐       │
│  │ Users  │ Offers │  Subs  │Onboard │ Audit  │ Plans  │       │
│  └────────┴────────┴────────┴────────┴────────┴────────┘       │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                    EXTERNAL SERVICES                             │
│  ┌──────────┬──────────┬──────────┬──────────┐                 │
│  │Cloudinary│  Twilio  │   JWT    │ Pincode  │                 │
│  │ (Images) │  (SMS)   │  (Auth)  │ Service  │                 │
│  └──────────┴──────────┴──────────┴──────────┘                 │
└─────────────────────────────────────────────────────────────────┘
```

### Request Flow

1. **Client Request** → Mobile app sends HTTPS request
2. **Rate Limiting** → Prevents abuse (20 req/15min regular, 50 req/15min admin)
3. **Authentication** → JWT token validation
4. **Role Authorization** → Role-based access control
5. **Subscription Check** → Validates active subscription (shopkeepers only)
6. **Business Logic** → Controller processes request
7. **Data Access** → Mongoose ODM interacts with MongoDB
8. **Response** → JSON response returned to client

---


## Technology Stack

### Frontend (Client)

| Technology | Version | Purpose |
|------------|---------|---------|
| **Flutter** | 3.5.0+ | Cross-platform mobile framework |
| **Dart** | 3.5.0+ | Programming language |
| **Provider** | 6.1.1 | State management |
| **HTTP** | 1.1.0 | API communication |
| **Google Fonts** | 6.1.0 | Typography (Poppins) |
| **Shared Preferences** | 2.2.2 | Local storage |
| **Image Picker** | 1.0.7 | Image selection |
| **Cached Network Image** | 3.3.1 | Image caching |
| **Intl** | 0.19.0 | Internationalization |
| **Animate Do** | 3.1.2 | Animations |
| **Flutter SVG** | 2.0.9 | SVG rendering |

### Backend (Server)

| Technology | Version | Purpose |
|------------|---------|---------|
| **Node.js** | 18+ | Runtime environment |
| **Express.js** | 5.2.1 | Web framework |
| **MongoDB** | 9.2.0 | NoSQL database |
| **Mongoose** | 9.2.0 | MongoDB ODM |
| **JWT** | 9.0.3 | Authentication tokens |
| **Cloudinary** | 2.0.0 | Image storage & CDN |
| **Multer** | 1.4.5 | File upload handling |
| **Express Rate Limit** | 8.2.1 | Rate limiting |
| **Dotenv** | 17.2.4 | Environment variables |
| **CORS** | 2.8.6 | Cross-origin requests |
| **Nodemon** | 3.1.11 | Development auto-reload |

### External Services

| Service | Purpose | Status |
|---------|---------|--------|
| **Cloudinary** | Image upload, storage, transformation | ✅ Active |
| **Twilio** | SMS OTP delivery | ⚙️ Configured |
| **MongoDB Atlas** | Cloud database hosting | ✅ Active |
| **Render.com** | Backend deployment | ✅ Active |

### Development Tools

- **Git** - Version control
- **VS Code** - IDE
- **Postman** - API testing
- **Android Studio** - Android development
- **Xcode** - iOS development

---


## User Roles & Permissions

### Role Hierarchy

```
┌─────────────────────────────────────────────────────────────┐
│                      SUPER ADMIN                             │
│  • Full system access                                        │
│  • User management (all roles)                               │
│  • Subscription plan management                              │
│  • Revenue analytics                                         │
│  • Audit log access                                          │
│  • System configuration                                      │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                       SUBADMIN                               │
│  • Limited admin access                                      │
│  • User management (customers, shopkeepers)                  │
│  • Offer moderation                                          │
│  • Basic analytics                                           │
│  • Cannot manage other admins                                │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────┬──────────────────────────────────────┐
│  COMPANY SALES AGENT │         SSA (Sales Service Agent)    │
│  • Sales analytics   │  • Shopkeeper relationship mgmt      │
│  • Revenue reports   │  • Onboarding assistance             │
│  • Lead management   │  • Support ticket handling           │
│  • Commission track  │  • Performance monitoring            │
└──────────────────────┴──────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                      SHOPKEEPER                              │
│  • Requires subscription                                     │
│  • 3-step onboarding process                                 │
│  • Offer CRUD operations                                     │
│  • Shop profile management                                   │
│  • Analytics dashboard                                       │
│  • Subscription management                                   │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                       CUSTOMER                               │
│  • Browse offers (location-based)                            │
│  • Like/save offers                                          │
│  • View offer details                                        │
│  • No subscription required                                  │
└─────────────────────────────────────────────────────────────┘
```

### Permission Matrix

| Feature | Super Admin | Subadmin | Sales Agent | SSA | Shopkeeper | Customer |
|---------|-------------|----------|-------------|-----|------------|----------|
| View All Users | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Manage Admins | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Approve Shopkeepers | ✅ | ✅ | ❌ | ✅ | ❌ | ❌ |
| Create Subscription Plans | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| View Revenue Analytics | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ |
| Manage Own Offers | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ |
| Browse Offers | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Access Audit Logs | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Manage Subscriptions | ✅ | ❌ | ❌ | ❌ | ✅ (own) | ❌ |

---


## API Documentation

### Base URL

- **Production**: `https://MyOffers.onrender.com/api`
- **Development**: `http://localhost:3000/api`
- **Android Emulator**: `http://10.0.2.2:3000/api`

### Authentication

All protected endpoints require JWT token in header:
```
Authorization: Bearer <jwt_token>
```

### API Endpoints

#### 1. Authentication (`/api/auth`)

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/send-otp` | ❌ | Send OTP to phone number |
| POST | `/verify-otp` | ❌ | Verify OTP and get JWT token |
| GET | `/me` | ✅ | Get current user profile |
| PUT | `/me` | ✅ | Update current user profile |
| POST | `/signup` | ❌ | Register new user |
| GET | `/dev/last-otp` | ❌ | Get last OTP (dev only) |

**Send OTP Request:**
```json
POST /api/auth/send-otp
{
  "phone": "9876543210",
  "role": "customer"
}
```

**Verify OTP Request:**
```json
POST /api/auth/verify-otp
{
  "phone": "9876543210",
  "otp": "123456",
  "role": "customer"
}
```

**Response:**
```json
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "507f1f77bcf86cd799439011",
    "phone": "9876543210",
    "role": "customer",
    "name": "John Doe"
  }
}
```

#### 2. Shopkeeper (`/api/shopkeeper`)

| Method | Endpoint | Auth | Subscription | Description |
|--------|----------|------|--------------|-------------|
| GET | `/profile` | ✅ | ❌ | Get shop profile |
| PUT | `/profile` | ✅ | ❌ | Update shop profile |
| GET | `/dashboard` | ✅ | ⚠️ | Get dashboard (checks status) |
| GET | `/plans` | ✅ | ❌ | View subscription plans |
| GET | `/plans/recommend` | ✅ | ❌ | Get recommended plans |
| POST | `/offers` | ✅ | ✅ | Create new offer |
| GET | `/offers` | ✅ | ✅ | List all offers |
| GET | `/offers/:id` | ✅ | ✅ | Get offer details |
| PUT | `/offers/:id` | ✅ | ✅ | Update offer |
| DELETE | `/offers/:id` | ✅ | ✅ | Delete offer |

**Create Offer Request:**
```json
POST /api/shopkeeper/offers
{
  "title": "50% Off on Electronics",
  "description": "Limited time offer on all electronics",
  "discount": "50",
  "validFrom": "2026-02-20T00:00:00Z",
  "validUntil": "2026-03-20T00:00:00Z",
  "category": "electronics",
  "imageUrl": "https://res.cloudinary.com/..."
}
```

#### 3. Customer (`/api/customer`)

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/offers` | ✅ | Browse offers (with filters) |
| GET | `/offers/:id` | ✅ | View offer details |
| POST | `/offers/:id/like` | ✅ | Like/unlike offer |
| GET | `/offers/liked` | ✅ | Get likeMyOffers |

**Browse Offers Request:**
```
GET /api/customer/offers?pincode=110001&category=electronics&page=1&limit=10
```

#### 4. Onboarding (`/api/onboarding`)

| Method | Endpoint | Auth | Role | Description |
|--------|----------|------|------|-------------|
| GET | `/status` | ✅ | Shopkeeper | Get onboarding status |
| POST | `/accept-terms` | ✅ | Shopkeeper | Accept T&C |
| POST | `/complete-profile` | ✅ | Shopkeeper | Mark profile complete |
| POST | `/complete` | ✅ | Shopkeeper | Complete onboarding |

**Onboarding Status Response:**
```json
{
  "success": true,
  "onboarding": {
    "userId": "507f1f77bcf86cd799439011",
    "businessProfileComplete": true,
    "termsAccepted": true,
    "termsAcceptedAt": "2026-02-20T10:00:00Z",
    "subscriptionActive": false,
    "currentStep": 3,
    "isComplete": false
  }
}
```

#### 5. Subscription (`/api/subscription`)

| Method | Endpoint | Auth | Role | Description |
|--------|----------|------|------|-------------|
| GET | `/` | ✅ | Shopkeeper | Get subscription status |
| GET | `/plans` | ✅ | Shopkeeper | List available plans |
| POST | `/trial` | ✅ | Shopkeeper | Activate 7-day trial |
| POST | `/activate` | ✅ | Shopkeeper | Activate paid plan |
| POST | `/cancel` | ✅ | Shopkeeper | Cancel subscription |

**Activate Trial Request:**
```json
POST /api/subscription/trial
{
  "planType": "trial"
}
```

**Activate Paid Plan Request:**
```json
POST /api/subscription/activate
{
  "planType": "basic",
  "paymentMethod": "razorpay",
  "transactionId": "pay_abc123xyz"
}
```

#### 6. Super Admin (`/api/super-admin`)

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/analytics` | ✅ | Dashboard analytics |
| GET | `/users` | ✅ | List all users |
| GET | `/users/:userId` | ✅ | Get user details |
| PATCH | `/users/:userId/status` | ✅ | Toggle user active status |
| PATCH | `/users/:userId/approval` | ✅ | Approve/reject user |
| GET | `/shops` | ✅ | List all shops |
| GET | `/audit-logs` | ✅ | View audit logs |

#### 7. Subscription Governance (`/api/subscription-governance`)

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/plans` | ✅ | Create subscription plan |
| GET | `/plans` | ✅ | List all plans |
| GET | `/plans/:id` | ✅ | Get plan details |
| PUT | `/plans/:id` | ✅ | Update plan |
| PATCH | `/plans/:id/toggle` | ✅ | Enable/disable plan |
| GET | `/subscriptions` | ✅ | List all subscriptions |
| GET | `/subscriptions/expiring` | ✅ | Get expiring subscriptions |
| GET | `/revenue/analytics` | ✅ | Revenue analytics |

#### 8. Admin (`/api/admin`)

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/stats` | ✅ | Platform statistics |
| GET | `/users` | ✅ | List users |
| GET | `/shopkeepers` | ✅ | List shopkeepers |
| PATCH | `/shopkeepers/:id/approve` | ✅ | Approve shopkeeper |
| PATCH | `/shopkeepers/:id/reject` | ✅ | Reject shopkeeper |

#### 9. Upload (`/api/upload`)

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/image` | ✅ | Upload image to Cloudinary |

**Upload Image Request:**
```
POST /api/upload/image
Content-Type: multipart/form-data

image: <file>
```

#### 10. Meta (`/api/meta`)

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/categories` | ❌ | Get shop categories |
| GET | `/pincode/:pincode` | ❌ | Get pincode details |

### Error Codes

| Code | Message | Description |
|------|---------|-------------|
| `AUTH_REQUIRED` | Authentication required | No JWT token provided |
| `INVALID_TOKEN` | Invalid or expired token | JWT validation failed |
| `INSUFFICIENT_PERMISSIONS` | Insufficient permissions | Wrong role for endpoint |
| `ONBOARDING_INCOMPLETE` | Onboarding not complete | Shopkeeper needs to complete steps |
| `SUBSCRIPTION_INACTIVE` | Subscription inactive | No active subscription |
| `SUBSCRIPTION_EXPIRED` | Subscription expired | Subscription has expired |
| `OFFER_LIMIT_REACHED` | Offer limit reached | Plan offer limit exceeded |
| `RATE_LIMIT_EXCEEDED` | Too many requests | Rate limit hit |

---


## Frontend Architecture

### Project Structure

```
client/
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart          # Color palette
│   │   │   └── app_constants.dart       # App-wide constants
│   │   ├── theme/
│   │   │   └── app_theme.dart           # Light/Dark themes
│   │   └── utils/
│   │       └── validators.dart          # Input validators
│   ├── models/
│   │   ├── user_model.dart              # User data model
│   │   ├── offer_model.dart             # Offer data model
│   │   ├── shopkeeper_profile_model.dart
│   │   └── role_enum.dart               # Role enumeration
│   ├── providers/
│   │   ├── auth_provider.dart           # Auth state management
│   │   ├── theme_provider.dart          # Theme state
│   │   └── offer_provider.dart          # Offer state
│   ├── screens/
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   ├── otp_screen.dart
│   │   │   └── role_selection_screen.dart
│   │   ├── customer/
│   │   │   ├── customer_home_screen.dart
│   │   │   ├── offer_list_screen.dart
│   │   │   └── liked_offers_screen.dart
│   │   ├── shopkeeper/
│   │   │   ├── shopkeeper_dashboard.dart
│   │   │   ├── create_offer_screen.dart
│   │   │   ├── offer_list_screen.dart
│   │   │   ├── profile_screen.dart
│   │   │   ├── onboarding/
│   │   │   │   ├── business_profile_screen.dart
│   │   │   │   ├── terms_screen.dart
│   │   │   │   └── subscription_screen.dart
│   │   │   └── subscription/
│   │   │       ├── subscription_status_screen.dart
│   │   │       └── plan_selection_screen.dart
│   │   ├── admin/
│   │   │   ├── admin_dashboard.dart
│   │   │   ├── user_management_screen.dart
│   │   │   └── shopkeeper_approval_screen.dart
│   │   ├── super_admin/
│   │   │   ├── super_admin_dashboard.dart
│   │   │   ├── analytics_screen.dart
│   │   │   ├── subscription_governance_screen.dart
│   │   │   └── audit_logs_screen.dart
│   │   ├── common/
│   │   │   ├── offer_detail_screen.dart
│   │   │   └── profile_screen.dart
│   │   └── splash/
│   │       └── splash_screen.dart
│   ├── services/
│   │   ├── api_config.dart              # API base URLs
│   │   ├── auth_service.dart            # Auth API calls
│   │   ├── auth_store.dart              # Token storage
│   │   ├── offer_service.dart           # Offer API calls
│   │   ├── upload_service.dart          # Image upload
│   │   └── super_admin_service.dart     # Admin API calls
│   ├── widgets/
│   │   ├── custom_button.dart
│   │   ├── custom_text_field.dart
│   │   ├── offer_card.dart
│   │   ├── gradient_card.dart
│   │   ├── theme_toggle.dart
│   │   └── profile_option_tile.dart
│   └── main.dart                        # App entry point
├── assets/
│   └── Dofferlogo.png                   # App logo
├── pubspec.yaml                         # Dependencies
└── analysis_options.yaml                # Linter rules
```

### State Management

**Provider Pattern** is used for state management:

```dart
// Example: Auth Provider
class AuthProvider extends ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoading = false;

  User? get user => _user;
  bool get isAuthenticated => _token != null;
  
  Future<void> login(String phone, String otp) async {
    _isLoading = true;
    notifyListeners();
    
    // API call
    final response = await authService.verifyOtp(phone, otp);
    
    _user = response.user;
    _token = response.token;
    await authStore.saveToken(_token!);
    
    _isLoading = false;
    notifyListeners();
  }
}
```

### Navigation Flow

```
SplashScreen
    ↓
[Check Token]
    ↓
    ├─ No Token → RoleSelectionScreen → LoginScreen → OTPScreen
    │                                                      ↓
    └─ Has Token → [Check Role] ─────────────────────────┘
                        ↓
        ┌───────────────┼───────────────┬───────────────┐
        ↓               ↓               ↓               ↓
   CustomerHome   ShopkeeperDash   AdminDash    SuperAdminDash
                        ↓
                [Check Onboarding]
                        ↓
        ┌───────────────┼───────────────┐
        ↓               ↓               ↓
   ProfileScreen   TermsScreen   SubscriptionScreen
```

### API Service Pattern

```dart
class OfferService {
  final String baseUrl = ApiConfig.baseUrl;
  
  Future<List<Offer>> getOffers({
    String? pincode,
    String? category,
    int page = 1,
  }) async {
    final token = await AuthStore.getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/customer/offers')
          .replace(queryParameters: {
        'pincode': pincode,
        'category': category,
        'page': page.toString(),
      }),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['offers'] as List)
          .map((json) => Offer.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to loaMyOffers');
    }
  }
}
```

---


## Backend Architecture

### Project Structure

```
server/
├── src/
│   ├── config/
│   │   ├── index.js                     # App configuration
│   │   └── cloudinary.js                # Cloudinary setup
│   ├── controllers/
│   │   ├── authController.js            # Auth logic
│   │   ├── offerController.js           # Offer CRUD
│   │   ├── shopkeeperProfileController.js
│   │   ├── customerController.js
│   │   ├── adminController.js
│   │   ├── superAdminController.js
│   │   ├── onboardingController.js
│   │   ├── subscriptionController.js
│   │   ├── subscriptionPlanController.js
│   │   ├── subscriptionGovernanceController.js
│   │   ├── uploadController.js
│   │   └── metaController.js
│   ├── middleware/
│   │   ├── auth.js                      # JWT verification
│   │   ├── roleAuth.js                  # Role-based auth
│   │   ├── roleCheck.js                 # Role validation
│   │   ├── subscriptionCheck.js         # Subscription validation
│   │   ├── upload.js                    # Multer config
│   │   └── errorHandler.js              # Global error handler
│   ├── models/
│   │   ├── User.js                      # User schema
│   │   ├── Offer.js                     # Offer schema
│   │   ├── ShopkeeperProfile.js         # Shop profile schema
│   │   ├── Subscription.js              # Subscription schema
│   │   ├── SubscriptionPlan.js          # Plan schema
│   │   ├── OnboardingStatus.js          # Onboarding schema
│   │   ├── AuditLog.js                  # Audit log schema
│   │   └── Otp.js                       # OTP schema
│   ├── routes/
│   │   ├── index.js                     # Route aggregator
│   │   ├── authRoutes.js
│   │   ├── shopkeeperRoutes.js
│   │   ├── customerRoutes.js
│   │   ├── adminRoutes.js
│   │   ├── superAdminRoutes.js
│   │   ├── onboardingRoutes.js
│   │   ├── subscriptionRoutes.js
│   │   ├── subscriptionGovernanceRoutes.js
│   │   ├── offerRoutes.js
│   │   ├── uploadRoutes.js
│   │   ├── metaRoutes.js
│   │   ├── ssaRoutes.js
│   │   ├── companySalesRoutes.js
│   │   └── subadminRoutes.js
│   ├── services/
│   │   ├── otpService.js                # OTP generation/validation
│   │   └── pincodeService.js            # Pincode lookup
│   ├── jobs/
│   │   └── subscriptionExpiry.js        # Cron job for expiry
│   └── app.js                           # Express app setup
├── scripts/
│   ├── seedAdmin.js                     # Create admin user
│   ├── migrate-phase1.js                # Database migration
│   ├── create-super-admin.js            # Create super admin
│   ├── test-super-admin.js              # Test super admin
│   └── seed-subscription-plans.js       # Seed plans
├── .env                                 # Environment variables
├── index.js                             # Server entry point
└── package.json                         # Dependencies
```

### Middleware Stack

```javascript
// Request flow through middleware
app.use(cors());                         // 1. CORS
app.use(express.json());                 // 2. JSON parser
app.use(rateLimiter);                    // 3. Rate limiting
app.use('/api', routes);                 // 4. Routes
    ↓
router.use(authMiddleware);              // 5. JWT verification
router.use(requireRole('shopkeeper'));   // 6. Role check
router.use(requireActiveSubscription);   // 7. Subscription check
    ↓
controller.method();                     // 8. Business logic
```

### Controller Pattern

```javascript
// Example: Offer Controller
const offerController = {
  async create(req, res) {
    try {
      const { title, description, discount, validFrom, validUntil } = req.body;
      const userId = req.user.userId;
      
      // Get shopkeeper profile
      const profile = await ShopkeeperProfile.findOne({ userId });
      if (!profile) {
        return res.status(404).json({
          success: false,
          message: 'Shop profile not found'
        });
      }
      
      // Create offer
      const offer = await Offer.create({
        shopkeeperId: userId,
        shopName: profile.shopName,
        title,
        description,
        discount,
        validFrom,
        validUntil,
        pincode: profile.pincode,
        category: profile.category,
      });
      
      // Log action
      await AuditLog.create({
        userId,
        action: 'CREATE_OFFER',
        resourceType: 'Offer',
        resourceId: offer._id,
      });
      
      res.status(201).json({
        success: true,
        offer,
      });
    } catch (error) {
      console.error('Create offer error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to create offer',
      });
    }
  },
};
```

### Database Connection

```javascript
// MongoDB connection with Mongoose
const mongoose = require('mongoose');
const config = require('./config');

mongoose.connect(config.mongodbUri, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
.then(() => console.log('✅ MongoDB connected'))
.catch(err => console.error('❌ MongoDB connection error:', err));
```

### Environment Variables

```bash
# Server
PORT=3000

# MongoDB
MONGODB_URI=mongodb+srv://user:pass@cluster.mongodb.net/MyOffers

# JWT
JWT_SECRET=your-secret-key-change-in-production
JWT_EXPIRY=7d

# OTP
MASTER_OTP=999999
OTP_EXPIRY_MINUTES=10
SEND_OTP_VIA_SMS=false

# SMS (Twilio)
SMS_PROVIDER=twilio
TWILIO_ACCOUNT_SID=
TWILIO_AUTH_TOKEN=
TWILIO_PHONE_NUMBER=

# Cloudinary
CLOUDINARY_CLOUD_NAME=drlhpylut
CLOUDINARY_API_KEY=492165161531146
CLOUDINARY_API_SECRET=KEhBXvr3pFUMwV6WtPCCsWs9znI

# Environment
NODE_ENV=development
```

---


## Database Schema

### Collections Overview

```
MongoDB Database: MyOffers
├── users                    # User accounts
├── shopkeeperprofiles       # Shop details
├── offers                   # Promotional offers
├── subscriptions            # Subscription records
├── subscriptionplans        # Available plans
├── onboardingstatuses       # Onboarding progress
├── auditlogs                # Activity logs
└── otps                     # OTP records
```

### User Schema

```javascript
{
  _id: ObjectId,
  phone: String (unique, required),
  name: String,
  role: String (enum: ['super_admin', 'subadmin', 'company_sales_agent', 
                       'ssa', 'shopkeeper', 'customer']),
  pincode: String,
  address: String,
  isActive: Boolean (default: true),
  isApproved: Boolean (default: false),
  permissions: [String],
  createdAt: Date,
  updatedAt: Date
}
```

### ShopkeeperProfile Schema

```javascript
{
  _id: ObjectId,
  userId: ObjectId (ref: 'User', unique),
  shopName: String (required),
  category: String (required),
  description: String,
  address: String,
  pincode: String (required),
  city: String,
  state: String,
  phone: String,
  email: String,
  gstNumber: String,
  businessLicense: String,
  logoUrl: String,
  bannerUrl: String,
  isVerified: Boolean (default: false),
  rating: Number (default: 0),
  totalOffers: Number (default: 0),
  createdAt: Date,
  updatedAt: Date
}
```

### Offer Schema

```javascript
{
  _id: ObjectId,
  shopkeeperId: ObjectId (ref: 'User', required),
  shopName: String (required),
  title: String (required),
  description: String (required),
  discount: String (required),
  category: String (required),
  imageUrl: String,
  validFrom: Date (required),
  validUntil: Date (required),
  pincode: String (required),
  city: String,
  isActive: Boolean (default: true),
  views: Number (default: 0),
  likes: Number (default: 0),
  likedBy: [ObjectId] (ref: 'User'),
  createdAt: Date,
  updatedAt: Date
}
```

### Subscription Schema

```javascript
{
  _id: ObjectId,
  userId: ObjectId (ref: 'User', required, unique),
  planType: String (enum: ['trial', 'basic', 'premium', 'enterprise'], required),
  status: String (enum: ['active', 'inactive', 'expired', 'cancelled'], default: 'active'),
  startDate: Date (required),
  endDate: Date (required),
  autoRenew: Boolean (default: false),
  paymentHistory: [{
    amount: Number,
    transactionId: String,
    paymentMethod: String,
    paidAt: Date,
    status: String
  }],
  features: {
    maxOffers: Number,
    analyticsAccess: Boolean,
    prioritySupport: Boolean,
    apiAccess: Boolean
  },
  createdAt: Date,
  updatedAt: Date,
  
  // Methods
  isActive(): Boolean,
  isExpired(): Boolean
}
```

### SubscriptionPlan Schema

```javascript
{
  _id: ObjectId,
  name: String (required, unique),
  displayName: String (required),
  planType: String (enum: ['trial', 'basic', 'premium', 'enterprise'], required),
  price: Number (required),
  duration: Number (required, in days),
  category: String,
  features: {
    maxOffers: Number,
    analyticsAccess: Boolean,
    prioritySupport: Boolean,
    apiAccess: Boolean,
    customIntegrations: Boolean
  },
  description: String,
  isActive: Boolean (default: true),
  sortOrder: Number (default: 0),
  createdAt: Date,
  updatedAt: Date
}
```

### OnboardingStatus Schema

```javascript
{
  _id: ObjectId,
  userId: ObjectId (ref: 'User', required, unique),
  businessProfileComplete: Boolean (default: false),
  termsAccepted: Boolean (default: false),
  termsAcceptedAt: Date,
  subscriptionActive: Boolean (default: false),
  currentStep: Number (default: 1),
  completedAt: Date,
  createdAt: Date,
  updatedAt: Date,
  
  // Methods
  isComplete(): Boolean,
  getNextStep(): Number
}
```

### AuditLog Schema

```javascript
{
  _id: ObjectId,
  userId: ObjectId (ref: 'User', required),
  action: String (required),
  resourceType: String,
  resourceId: ObjectId,
  details: Object,
  ipAddress: String,
  userAgent: String,
  timestamp: Date (default: Date.now),
  createdAt: Date
}
```

### OTP Schema

```javascript
{
  _id: ObjectId,
  phone: String (required),
  otp: String (required),
  role: String (required),
  expiresAt: Date (required),
  verified: Boolean (default: false),
  createdAt: Date
}
```

### Indexes

```javascript
// User
users.createIndex({ phone: 1 }, { unique: true });
users.createIndex({ role: 1 });

// Offer
offers.createIndex({ shopkeeperId: 1 });
offers.createIndex({ pincode: 1, category: 1 });
offers.createIndex({ validUntil: 1 });
offers.createIndex({ isActive: 1 });

// Subscription
subscriptions.createIndex({ userId: 1 }, { unique: true });
subscriptions.createIndex({ status: 1 });
subscriptions.createIndex({ endDate: 1 });

// AuditLog
auditlogs.createIndex({ userId: 1 });
auditlogs.createIndex({ timestamp: -1 });
auditlogs.createIndex({ action: 1 });

// OTP
otps.createIndex({ phone: 1 });
otps.createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 });
```

---


## External Services

### 1. Cloudinary (Image Management)

**Purpose**: Image upload, storage, transformation, and CDN delivery

**Configuration**:
```javascript
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET
});
```

**Usage**:
- Offer banner images
- Shop logos
- Shop banner images
- Profile pictures

**Features Used**:
- Automatic format optimization
- Responsive image delivery
- CDN distribution
- Image transformation (resize, crop, quality)

**Upload Flow**:
```
Client → Multer (memory storage) → Cloudinary API → CDN URL → Database
```

### 2. Twilio (SMS Service)

**Purpose**: OTP delivery via SMS

**Configuration**:
```javascript
const twilio = require('twilio');
const client = twilio(
  process.env.TWILIO_ACCOUNT_SID,
  process.env.TWILIO_AUTH_TOKEN
);
```

**Usage**:
- Send OTP for authentication
- Send subscription reminders (planned)
- Send offer notifications (planned)

**Current Status**: Configured but using master OTP (999999) in development

### 3. MongoDB Atlas

**Purpose**: Cloud database hosting

**Features**:
- Automatic backups
- Replica sets for high availability
- Performance monitoring
- Security features (encryption at rest)

**Connection String**:
```
mongodb+srv://user:pass@cluster.mongodb.net/MyOffers?retryWrites=true&w=majority
```

### 4. Pincode Service

**Purpose**: Location data lookup

**Usage**:
- Validate pincodes
- Get city/state from pincode
- Location-based offer filtering

**API Endpoint**: `/api/meta/pincode/:pincode`

---

## AI Integration

### Current Status: In Development

### Planned AI Features

#### 1. Personalized Offer Recommendations

**Technology**: Machine Learning (TensorFlow/PyTorch)

**Approach**:
- Collaborative filtering based on user behavior
- Content-based filtering using offer categories
- Hybrid recommendation system

**Data Points**:
- User likeMyOffers
- User browsing history
- Location preferences
- Category preferences
- Time-based patterns

**Implementation Plan**:
```python
# Recommendation Engine (Python microservice)
class OfferRecommender:
    def __init__(self):
        self.model = load_model('offer_recommender.h5')
    
    def get_recommendations(self, user_id, location, limit=10):
        # Get user features
        user_features = self.get_user_features(user_id)
        
        # Get available offers
        offers = self.get_offers_by_location(location)
        
        # Score offers
        scores = self.model.predict(user_features, offers)
        
        # Return top N
        return self.rank_offers(offers, scores, limit)
```

**API Integration**:
```
GET /api/ai/recommendations?userId=xxx&pincode=110001&limit=10
```

#### 2. AI Chatbot

**Technology**: Natural Language Processing (NLP)

**Framework**: Dialogflow / Rasa / Custom GPT

**Capabilities**:
- Answer FAQs
- Help with onboarding
- Subscription assistance
- Offer search assistance
- Customer support

**Conversation Flow**:
```
User: "Show me electronics offers near me"
Bot: "I found 15 electronics offers in your area. 
      Would you like to see the top deals?"
User: "Yes"
Bot: [Shows top 5 offers with images and details]
```

**Implementation**:
```javascript
// Chatbot API endpoint
POST /api/ai/chat
{
  "userId": "507f1f77bcf86cd799439011",
  "message": "Show me electronics offers",
  "context": {
    "pincode": "110001",
    "previousMessages": []
  }
}
```

#### 3. Offer Performance Prediction

**Purpose**: Predict offer success rate

**Features**:
- Predict views based on category, discount, timing
- Suggest optimal pricing
- Recommend best posting times

**Model**:
```python
class OfferPerformancePredictor:
    def predict_views(self, offer_data):
        features = [
            offer_data['discount'],
            offer_data['category_score'],
            offer_data['time_score'],
            offer_data['location_score']
        ]
        return self.model.predict([features])[0]
```

#### 4. Fraud Detection

**Purpose**: Detect suspicious activities

**Signals**:
- Unusual offer creation patterns
- Fake reviews/likes
- Subscription abuse
- Multiple accounts from same device

**Implementation**:
```python
class FraudDetector:
    def check_offer(self, offer, user):
        risk_score = 0
        
        # Check offer creation rate
        if self.get_offer_count_today(user) > 50:
            risk_score += 30
        
        # Check discount validity
        if offer['discount'] > 90:
            risk_score += 20
        
        # Check image authenticity
        if not self.verify_image(offer['imageUrl']):
            risk_score += 40
        
        return {
            'risk_score': risk_score,
            'is_suspicious': risk_score > 50
        }
```

### AI Infrastructure

**Microservice Architecture**:
```
┌─────────────────────────────────────────────────────────┐
│                   Main Backend (Node.js)                 │
│                   Port: 3000                             │
└─────────────────────────────────────────────────────────┘
                          ↓ HTTP/gRPC
┌─────────────────────────────────────────────────────────┐
│                AI Service (Python/FastAPI)               │
│                   Port: 8000                             │
│  ┌──────────────┬──────────────┬──────────────┐        │
│  │Recommendation│   Chatbot    │    Fraud     │        │
│  │   Engine     │   Service    │  Detection   │        │
│  └──────────────┴──────────────┴──────────────┘        │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│              Model Storage (S3/Cloud Storage)            │
│  • Trained models                                        │
│  • Training data                                         │
│  • Model versions                                        │
└─────────────────────────────────────────────────────────┘
```

### AI Data Flow

```
User Action → Event Tracking → Data Pipeline → Feature Engineering
                                                      ↓
                                              Model Training
                                                      ↓
                                              Model Deployment
                                                      ↓
                                              Real-time Inference
                                                      ↓
                                              User Experience
```

### AI Models in Use (Planned)

| Model | Purpose | Framework | Status |
|-------|---------|-----------|--------|
| Collaborative Filtering | Offer recommendations | TensorFlow | 🔄 In Progress |
| NLP Intent Classifier | Chatbot understanding | Rasa | 📋 Planned |
| Image Classifier | Offer image validation | PyTorch | 📋 Planned |
| Anomaly Detection | Fraud detection | Scikit-learn | 📋 Planned |
| Time Series | Demand forecasting | Prophet | 📋 Planned |

---


## Security & Authentication

### Authentication Flow

```
┌─────────────────────────────────────────────────────────┐
│                    1. Send OTP                           │
│  POST /api/auth/send-otp                                 │
│  { phone: "9876543210", role: "customer" }              │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                    2. Generate OTP                       │
│  • Generate 6-digit OTP                                  │
│  • Store in database with expiry (10 min)               │
│  • Send via SMS (or use master OTP in dev)              │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                    3. Verify OTP                         │
│  POST /api/auth/verify-otp                               │
│  { phone: "9876543210", otp: "123456", role: "..." }   │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                    4. Generate JWT                       │
│  • Create user if not exists                             │
│  • Generate JWT token (7 days expiry)                    │
│  • Return token + user data                              │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                    5. Store Token                        │
│  • Client stores token in SharedPreferences              │
│  • Include in Authorization header for all requests      │
└─────────────────────────────────────────────────────────┘
```

### JWT Token Structure

```javascript
{
  "userId": "507f1f77bcf86cd799439011",
  "phone": "9876543210",
  "role": "shopkeeper",
  "iat": 1708416000,
  "exp": 1709020800
}
```

### Security Measures

#### 1. Rate Limiting

```javascript
// Regular users: 20 requests per 15 minutes
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  message: 'Too many attempts, please try again later'
});

// Admin users: 50 requests per 15 minutes
const adminAuthLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 50
});
```

#### 2. Role-Based Access Control (RBAC)

```javascript
// Middleware checks
const requireRole = (...roles) => {
  return (req, res, next) => {
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        code: 'INSUFFICIENT_PERMISSIONS',
        message: 'You do not have permission to access this resource'
      });
    }
    next();
  };
};
```

#### 3. Subscription Validation

```javascript
const requireActiveSubscription = async (req, res, next) => {
  if (req.user.role !== 'shopkeeper') {
    return next();
  }
  
  const subscription = await Subscription.findOne({ 
    userId: req.user.userId 
  });
  
  if (!subscription || !subscription.isActive()) {
    return res.status(403).json({
      success: false,
      code: 'SUBSCRIPTION_INACTIVE',
      message: 'Active subscription required',
      redirectTo: '/subscription'
    });
  }
  
  next();
};
```

#### 4. Input Validation

```javascript
// Example: Offer creation validation
const validateOffer = (req, res, next) => {
  const { title, description, discount, validFrom, validUntil } = req.body;
  
  if (!title || title.length < 5) {
    return res.status(400).json({
      success: false,
      message: 'Title must be at least 5 characters'
    });
  }
  
  if (!discount || isNaN(discount) || discount < 0 || discount > 100) {
    return res.status(400).json({
      success: false,
      message: 'Discount must be between 0 and 100'
    });
  }
  
  // Validate dates
  const from = new Date(validFrom);
  const until = new Date(validUntil);
  
  if (from >= until) {
    return res.status(400).json({
      success: false,
      message: 'Valid until must be after valid from'
    });
  }
  
  next();
};
```

#### 5. CORS Configuration

```javascript
const cors = require('cors');

app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || '*',
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
```

#### 6. Environment Variables

- Never commit `.env` file
- Use different secrets for dev/prod
- Rotate JWT secrets periodically
- Use strong, random secrets (min 32 characters)

#### 7. Password Hashing (Future)

When implementing password auth:
```javascript
const bcrypt = require('bcrypt');

// Hash password
const hashedPassword = await bcrypt.hash(password, 10);

// Verify password
const isValid = await bcrypt.compare(password, hashedPassword);
```

#### 8. Audit Logging

All sensitive actions are logged:
```javascript
await AuditLog.create({
  userId: req.user.userId,
  action: 'CREATE_OFFER',
  resourceType: 'Offer',
  resourceId: offer._id,
  ipAddress: req.ip,
  userAgent: req.headers['user-agent'],
  details: { title: offer.title }
});
```

### Security Best Practices

✅ **Implemented**:
- JWT authentication
- Role-based access control
- Rate limiting
- Input validation
- CORS protection
- Audit logging
- Environment variable protection

📋 **Planned**:
- Two-factor authentication (2FA)
- IP whitelisting for admin
- Encryption at rest
- API key management
- OAuth integration
- Security headers (Helmet.js)
- SQL injection prevention (using Mongoose)
- XSS protection

---


## Subscription & Monetization

### Subscription Plans

| Plan | Price | Duration | Max Offers | Analytics | Support | API Access |
|------|-------|----------|------------|-----------|---------|------------|
| **Trial** | Free | 7 days | 5 | Basic | Email | ❌ |
| **Basic** | ₹499 | 30 days | Unlimited | Basic | Email | ❌ |
| **Premium** | ₹999 | 30 days | Unlimited | Advanced | Priority | ❌ |
| **Enterprise** | ₹2,499 | 30 days | Unlimited | Advanced | Dedicated | ✅ |

### Shopkeeper Onboarding Flow

```
┌─────────────────────────────────────────────────────────┐
│              Step 1: Business Profile                    │
│  • Shop name (required)                                  │
│  • Category (required)                                   │
│  • Address, pincode, city                                │
│  • Description                                           │
│  • Contact details                                       │
│  API: PUT /api/shopkeeper/profile                        │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│              Step 2: Terms & Conditions                  │
│  • Display platform terms                                │
│  • User must accept                                      │
│  • Timestamp recorded                                    │
│  API: POST /api/onboarding/accept-terms                  │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│              Step 3: Subscription                        │
│  • Choose plan (Trial/Basic/Premium/Enterprise)          │
│  • Payment processing (if paid plan)                     │
│  • Activate subscription                                 │
│  API: POST /api/subscription/trial or /activate          │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│              Dashboard Access Granted                    │
│  • Can create offers                                     │
│  • Access analytics                                      │
│  • Manage profile                                        │
└─────────────────────────────────────────────────────────┘
```

### Subscription Lifecycle

```
┌─────────────┐
│   INACTIVE  │ ← Initial state
└─────────────┘
       ↓ Activate trial/paid plan
┌─────────────┐
│   ACTIVE    │ ← Can use all features
└─────────────┘
       ↓ End date reached
┌─────────────┐
│   EXPIRED   │ ← Grace period (3 days)
└─────────────┘
       ↓ No renewal
┌─────────────┐
│  CANCELLED  │ ← Access revoked
└─────────────┘
```

### Subscription Enforcement

**Middleware Check**:
```javascript
const requireActiveSubscription = async (req, res, next) => {
  // Only check for shopkeepers
  if (req.user.role !== 'shopkeeper') {
    return next();
  }
  
  const subscription = await Subscription.findOne({ 
    userId: req.user.userId 
  });
  
  // No subscription found
  if (!subscription) {
    return res.status(403).json({
      success: false,
      code: 'SUBSCRIPTION_INACTIVE',
      message: 'Please activate a subscription to continue',
      redirectTo: '/subscription'
    });
  }
  
  // Check if expired
  if (subscription.isExpired()) {
    return res.status(403).json({
      success: false,
      code: 'SUBSCRIPTION_EXPIRED',
      message: 'Your subscription has expired',
      redirectTo: '/subscription',
      subscription: {
        endDate: subscription.endDate,
        planType: subscription.planType
      }
    });
  }
  
  // Check if active
  if (!subscription.isActive()) {
    return res.status(403).json({
      success: false,
      code: 'SUBSCRIPTION_INACTIVE',
      message: 'Your subscription is not active',
      redirectTo: '/subscription'
    });
  }
  
  // All good, proceed
  req.subscription = subscription;
  next();
};
```

**Protected Routes**:
- `POST /api/shopkeeper/offers` - Create offer
- `GET /api/shopkeeper/offers` - List offers
- `PUT /api/shopkeeper/offers/:id` - Update offer
- `DELETE /api/shopkeeper/offers/:id` - Delete offer

**Unprotected Routes** (for onboarding):
- `GET /api/shopkeeper/profile` - View profile
- `PUT /api/shopkeeper/profile` - Update profile
- `GET /api/shopkeeper/plans` - View plans

### Revenue Model

**Monthly Recurring Revenue (MRR)**:
```
MRR = (Basic subscribers × ₹499) + 
      (Premium subscribers × ₹999) + 
      (Enterprise subscribers × ₹2,499)
```

**Example Calculation**:
- 100 Basic subscribers: 100 × ₹499 = ₹49,900
- 50 Premium subscribers: 50 × ₹999 = ₹49,950
- 10 Enterprise subscribers: 10 × ₹2,499 = ₹24,990
- **Total MRR**: ₹1,24,840

### Payment Integration (Planned)

**Razorpay Integration**:
```javascript
const Razorpay = require('razorpay');

const razorpay = new Razorpay({
  key_id: process.env.RAZORPAY_KEY_ID,
  key_secret: process.env.RAZORPAY_KEY_SECRET
});

// Create order
const order = await razorpay.orders.create({
  amount: 49900, // ₹499 in paise
  currency: 'INR',
  receipt: `sub_${userId}_${Date.now()}`,
  notes: {
    userId,
    planType: 'basic'
  }
});

// Verify payment
const isValid = razorpay.validateWebhookSignature(
  req.body,
  req.headers['x-razorpay-signature'],
  process.env.RAZORPAY_WEBHOOK_SECRET
);
```

### Subscription Analytics

**Super Admin Dashboard**:
- Total active subscriptions
- MRR (Monthly Recurring Revenue)
- Churn rate
- Trial conversion rate
- Revenue by plan type
- Expiring subscriptions (next 7 days)
- Subscription growth trend

**API Endpoint**:
```
GET /api/subscription-governance/revenue/analytics
```

**Response**:
```json
{
  "success": true,
  "analytics": {
    "totalSubscriptions": 160,
    "activeSubscriptions": 150,
    "mrr": 124840,
    "churnRate": 5.2,
    "trialConversionRate": 35.5,
    "byPlan": {
      "trial": 10,
      "basic": 100,
      "premium": 50,
      "enterprise": 10
    },
    "expiringIn7Days": 15,
    "growthTrend": [
      { "month": "Jan", "subscriptions": 120, "revenue": 98000 },
      { "month": "Feb", "subscriptions": 150, "revenue": 124840 }
    ]
  }
}
```

---


## Workflow Diagrams

### Customer Workflow

```
┌─────────────┐
│  Open App   │
└─────────────┘
       ↓
┌─────────────┐
│Select Role: │
│  Customer   │
└─────────────┘
       ↓
┌─────────────┐
│ Enter Phone │
└─────────────┘
       ↓
┌─────────────┐
│ Verify OTP  │
└─────────────┘
       ↓
┌─────────────────────────────────────┐
│        Customer Dashboard            │
│  ┌────────────────────────────────┐ │
│  │  Browse Offers                 │ │
│  │  • Filter by location          │ │
│  │  • Filter by category          │ │
│  │  • Search offers               │ │
│  └────────────────────────────────┘ │
│  ┌────────────────────────────────┐ │
│  │  View Offer Details            │ │
│  │  • Like/Unlike                 │ │
│  │  • Share                       │ │
│  │  • Get directions              │ │
│  └────────────────────────────────┘ │
│  ┌────────────────────────────────┐ │
│  │  LikeMyOffers                  │ │
│  │  • View saveMyOffers           │ │
│  │  • Remove from liked           │ │
│  └────────────────────────────────┘ │
└─────────────────────────────────────┘
```

### Shopkeeper Workflow

```
┌─────────────┐
│  Open App   │
└─────────────┘
       ↓
┌─────────────┐
│Select Role: │
│ Shopkeeper  │
└─────────────┘
       ↓
┌─────────────┐
│ Enter Phone │
└─────────────┘
       ↓
┌─────────────┐
│ Verify OTP  │
└─────────────┘
       ↓
┌─────────────────────────────────────┐
│      Onboarding Check                │
└─────────────────────────────────────┘
       ↓
   [Complete?]
       ↓ No
┌─────────────────────────────────────┐
│      Step 1: Business Profile        │
│  • Shop name                         │
│  • Category                          │
│  • Address, pincode                  │
│  • Description                       │
└─────────────────────────────────────┘
       ↓
┌─────────────────────────────────────┐
│      Step 2: Terms & Conditions      │
│  • Read terms                        │
│  • Accept checkbox                   │
└─────────────────────────────────────┘
       ↓
┌─────────────────────────────────────┐
│      Step 3: Subscription            │
│  • View plans                        │
│  • Select plan                       │
│  • Payment (if paid)                 │
│  • Activate                          │
└─────────────────────────────────────┘
       ↓ Yes
┌─────────────────────────────────────┐
│      Shopkeeper Dashboard            │
│  ┌────────────────────────────────┐ │
│  │  Create Offer                  │ │
│  │  • Title, description          │ │
│  │  • Discount percentage         │ │
│  │  • Valid dates                 │ │
│  │  • Upload image                │ │
│  └────────────────────────────────┘ │
│  ┌────────────────────────────────┐ │
│  │  Manage Offers                 │ │
│  │  • View all offers             │ │
│  │  • Edit offer                  │ │
│  │  • Delete offer                │ │
│  │  • Toggle active/inactive      │ │
│  └────────────────────────────────┘ │
│  ┌────────────────────────────────┐ │
│  │  Analytics                     │ │
│  │  • Total views                 │ │
│  │  • Total likes                 │ │
│  │  • Offer performance           │ │
│  └────────────────────────────────┘ │
│  ┌────────────────────────────────┐ │
│  │  Subscription                  │ │
│  │  • View current plan           │ │
│  │  • Upgrade/downgrade           │ │
│  │  • Payment history             │ │
│  └────────────────────────────────┘ │
└─────────────────────────────────────┘
```

### Super Admin Workflow

```
┌─────────────┐
│  Open App   │
└─────────────┘
       ↓
┌─────────────┐
│Select Role: │
│ Super Admin │
└─────────────┘
       ↓
┌─────────────┐
│ Enter Phone │
└─────────────┘
       ↓
┌─────────────┐
│ Verify OTP  │
└─────────────┘
       ↓
┌─────────────────────────────────────┐
│      Super Admin Dashboard           │
│  ┌────────────────────────────────┐ │
│  │  Analytics Overview            │ │
│  │  • Total users                 │ │
│  │  • Total offers                │ │
│  │  • Active subscriptions        │ │
│  │  • MRR                         │ │
│  │  • Growth trends               │ │
│  └────────────────────────────────┘ │
│  ┌────────────────────────────────┐ │
│  │  User Management               │ │
│  │  • View all users              │ │
│  │  • Filter by role              │ │
│  │  • Approve/reject              │ │
│  │  • Toggle active status        │ │
│  └────────────────────────────────┘ │
│  ┌────────────────────────────────┐ │
│  │  Subscription Governance       │ │
│  │  • Create plans                │ │
│  │  • Edit pricing                │ │
│  │  • Enable/disable plans        │ │
│  │  • View all subscriptions      │ │
│  │  • Expiring subscriptions      │ │
│  └────────────────────────────────┘ │
│  ┌────────────────────────────────┐ │
│  │  Revenue Analytics             │ │
│  │  • MRR tracking                │ │
│  │  • Revenue by plan             │ │
│  │  • Churn rate                  │ │
│  │  • Conversion rate             │ │
│  └────────────────────────────────┘ │
│  ┌────────────────────────────────┐ │
│  │  Audit Logs                    │ │
│  │  • View all actions            │ │
│  │  • Filter by user/action       │ │
│  │  • Export logs                 │ │
│  └────────────────────────────────┘ │
└─────────────────────────────────────┘
```

### Data Flow Diagram

```
┌──────────────────────────────────────────────────────────┐
│                    CLIENT LAYER                           │
│  User Action (Create Offer, Browse, Like, etc.)          │
└──────────────────────────────────────────────────────────┘
                          ↓ HTTP Request
┌──────────────────────────────────────────────────────────┐
│                    API GATEWAY                            │
│  1. Rate Limiter → 2. CORS → 3. JSON Parser              │
└──────────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────────┐
│                 AUTHENTICATION                            │
│  JWT Token Verification                                   │
│  Extract: userId, phone, role                             │
└──────────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────────┐
│                 AUTHORIZATION                             │
│  1. Role Check → 2. Subscription Check                    │
└──────────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────────┐
│                 BUSINESS LOGIC                            │
│  Controller processes request                             │
│  • Validate input                                         │
│  • Apply business rules                                   │
│  • Call services                                          │
└──────────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────────┐
│                 DATA ACCESS                               │
│  Mongoose ODM                                             │
│  • Query database                                         │
│  • Create/Update/Delete                                   │
│  • Populate references                                    │
└──────────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────────┐
│                 DATABASE                                  │
│  MongoDB                                                  │
│  • Store data                                             │
│  • Execute queries                                        │
│  • Return results                                         │
└──────────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────────┐
│                 AUDIT LOGGING                             │
│  Log action to AuditLog collection                        │
└──────────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────────┐
│                 RESPONSE                                  │
│  JSON response sent back to client                        │
└──────────────────────────────────────────────────────────┘
```

---


## Development Phases

### Phase 1: Foundation & Core Features ✅ COMPLETED

**Duration**: Weeks 1-2

**Deliverables**:
- ✅ 6-role RBAC system
- ✅ Authentication (OTP-based)
- ✅ User management
- ✅ Basic offer CRUD
- ✅ Shopkeeper profile management
- ✅ Subscription system
- ✅ Onboarding workflow
- ✅ Database models
- ✅ API endpoints
- ✅ Middleware (auth, role, subscription)

**Roles Implemented**:
- ✅ Super Admin
- ✅ Subadmin
- ✅ Company Sales Agent
- ✅ SSA (Sales Service Agent)
- ✅ Shopkeeper
- ✅ Customer

---

### Phase 2: Customer Experience (Current Phase)

**Duration**: Weeks 3-4

**Customer Role Features**:
- 🔄 Browse offers by location
- 🔄 Filter by category
- 🔄 Search functionality
- 🔄 Like/unlike offers
- 🔄 View likeMyOffers
- 🔄 Offer detail view
- 🔄 Share offers
- 📋 Get directions to shop

**Timeline**:
- Week 3: Browse, filter, search
- Week 4: Like, share, directions

---

### Phase 3: Shopkeeper Dashboard Enhancement

**Duration**: Weeks 5-6

**Shopkeeper Role Features**:
- 📋 Enhanced offer creation UI
- 📋 Offer analytics dashboard
  - Views per offer
  - Likes per offer
  - Performance trends
- 📋 Bulk offer management
- 📋 Offer scheduling
- 📋 Image gallery
- 📋 Subscription management UI
  - View current plan
  - Upgrade/downgrade
  - Payment history
  - Renewal reminders

**Timeline**:
- Week 5: Analytics & bulk management
- Week 6: Subscription UI & scheduling

---

### Phase 4: Admin & Governance

**Duration**: Weeks 7-8

**Super Admin Features**:
- 📋 Subscription governance dashboard
  - Create/edit plans
  - Dynamic pricing
  - Enable/disable plans
  - Category mapping
- 📋 Revenue analytics
  - MRR tracking
  - Growth trends
  - Churn analysis
  - Conversion rates
- 📋 Subscription monitoring
  - Active subscriptions
  - Expiring subscriptions (7-day alert)
  - Renewal tracking
- 📋 User approval workflow
- 📋 Audit log viewer

**Subadmin Features**:
- 📋 User management (limited)
- 📋 Offer moderation
- 📋 Basic analytics

**SSA Features**:
- 📋 Shopkeeper relationship management
- 📋 Onboarding assistance
- 📋 Performance monitoring

**Company Sales Agent Features**:
- 📋 Sales analytics
- 📋 Revenue reports
- 📋 Lead management

**Timeline**:
- Week 7: Super admin governance
- Week 8: Other admin roles

---

### Phase 5: Payment Integration

**Duration**: Weeks 9-10

**Features**:
- 📋 Razorpay integration
- 📋 Payment gateway UI
- 📋 Order creation
- 📋 Payment verification
- 📋 Webhook handling
- 📋 Payment history
- 📋 Invoice generation
- 📋 Refund handling
- 📋 Auto-renewal logic

**Timeline**:
- Week 9: Razorpay setup & testing
- Week 10: Auto-renewal & invoices

---

### Phase 6: AI Integration - Recommendations

**Duration**: Weeks 11-12

**Features**:
- 📋 AI microservice setup (Python/FastAPI)
- 📋 User behavior tracking
- 📋 Collaborative filtering model
- 📋 Content-based filtering
- 📋 Hybrid recommendation engine
- 📋 Personalized offer feed
- 📋 Model training pipeline
- 📋 A/B testing framework

**Data Collection**:
- User views
- User likes
- Location preferences
- Category preferences
- Time-based patterns

**Timeline**:
- Week 11: Microservice & data collection
- Week 12: Model training & integration

---

### Phase 7: AI Integration - Chatbot

**Duration**: Weeks 13-14

**Features**:
- 📋 NLP intent classification
- 📋 Dialogflow/Rasa integration
- 📋 Conversation flow design
- 📋 FAQ handling
- 📋 Onboarding assistance
- 📋 Offer search via chat
- 📋 Subscription help
- 📋 Multi-language support (planned)

**Use Cases**:
- "Show me electronics offers near me"
- "How do I upgrade my subscription?"
- "What are the payment options?"
- "Help me complete onboarding"

**Timeline**:
- Week 13: Chatbot setup & training
- Week 14: Integration & testing

---

### Phase 8: Advanced Analytics & AI

**Duration**: Weeks 15-16

**Features**:
- 📋 Offer performance prediction
- 📋 Fraud detection system
- 📋 Demand forecasting
- 📋 Optimal pricing suggestions
- 📋 Best posting time recommendations
- 📋 Image authenticity verification
- 📋 Anomaly detection

**Timeline**:
- Week 15: Performance prediction & fraud detection
- Week 16: Forecasting & optimization

---

### Phase 9: Notifications & Engagement

**Duration**: Weeks 17-18

**Features**:
- 📋 Push notifications (Firebase)
- 📋 Email notifications
- 📋 SMS notifications
- 📋 Notification preferences
- 📋 Subscription reminders
- 📋 Offer expiry alerts
- 📋 New offer notifications
- 📋 Promotional campaigns

**Timeline**:
- Week 17: Push & email setup
- Week 18: SMS & preferences

---

### Phase 10: Performance & Optimization

**Duration**: Weeks 19-20

**Features**:
- 📋 Database indexing optimization
- 📋 Query optimization
- 📋 Caching layer (Redis)
- 📋 CDN optimization
- 📋 Image lazy loading
- 📋 API response compression
- 📋 Load testing
- 📋 Performance monitoring

**Timeline**:
- Week 19: Backend optimization
- Week 20: Frontend optimization

---

### Phase 11: Testing & QA

**Duration**: Weeks 21-22

**Features**:
- 📋 Unit tests (Jest)
- 📋 Integration tests
- 📋 E2E tests (Cypress)
- 📋 API tests (Postman/Newman)
- 📋 Load testing (Artillery)
- 📋 Security testing
- 📋 Accessibility testing
- 📋 Cross-browser testing
- 📋 Mobile device testing

**Timeline**:
- Week 21: Backend testing
- Week 22: Frontend testing

---

### Phase 12: Deployment & Launch

**Duration**: Weeks 23-24

**Features**:
- 📋 Production environment setup
- 📋 CI/CD pipeline (GitHub Actions)
- 📋 Database migration
- 📋 SSL certificate setup
- 📋 Domain configuration
- 📋 Monitoring setup (Sentry, LogRocket)
- 📋 Backup strategy
- 📋 Disaster recovery plan
- 📋 Documentation finalization
- 📋 User training materials

**Timeline**:
- Week 23: Infrastructure & deployment
- Week 24: Launch & monitoring

---

### Summary Timeline

| Phase | Duration | Status | Focus Area |
|-------|----------|--------|------------|
| Phase 1 | Weeks 1-2 | ✅ Complete | Foundation & RBAC |
| Phase 2 | Weeks 3-4 | 🔄 Current | Customer Experience |
| Phase 3 | Weeks 5-6 | 📋 Planned | Shopkeeper Dashboard |
| Phase 4 | Weeks 7-8 | 📋 Planned | Admin & Governance |
| Phase 5 | Weeks 9-10 | 📋 Planned | Payment Integration |
| Phase 6 | Weeks 11-12 | 📋 Planned | AI Recommendations |
| Phase 7 | Weeks 13-14 | 📋 Planned | AI Chatbot |
| Phase 8 | Weeks 15-16 | 📋 Planned | Advanced AI |
| Phase 9 | Weeks 17-18 | 📋 Planned | Notifications |
| Phase 10 | Weeks 19-20 | 📋 Planned | Optimization |
| Phase 11 | Weeks 21-22 | 📋 Planned | Testing & QA |
| Phase 12 | Weeks 23-24 | 📋 Planned | Deployment |

**Total Duration**: 24 weeks (6 months)

---


## Color Theme & Design System

### Color Palette

#### Primary Colors
```dart
Primary Orange:     #FFA726  // Main brand color
Primary Dark:       #F57C00  // Hover states, emphasis
Primary Light:      #FFB74D  // Backgrounds, subtle highlights
```

#### Accent Colors
```dart
Accent Cyan:        #26C6DA  // Secondary actions, links
Accent Dark:        #00ACC1  // Hover states for accent
```

#### Dark Theme
```dart
Background:         #0A0E21  // Main background (Dark Blue)
Surface:            #1D1E33  // Cards, elevated surfaces
Card Background:    #262A41  // Card containers

Text Primary:       #FFFFFF  // Main text
Text Secondary:     #B0B3C1  // Secondary text
Text Hint:          #6C6F7F  // Placeholder, disabled text
```

#### Light Theme
```dart
Background:         #F5F7FA  // Main background (Light Gray)
Surface:            #FFFFFF  // Cards, elevated surfaces
Card Background:    #FFFFFF  // Card containers

Text Primary:       #1A1D2E  // Main text
Text Secondary:     #6C6F7F  // Secondary text
Text Hint:          #9E9E9E  // Placeholder, disabled text
```

#### Status Colors
```dart
Success:            #4CAF50  // Green
Error:              #EF5350  // Red
Warning:            #FF9800  // Orange
Info:               #2196F3  // Blue
```

### Typography

**Font Family**: Poppins (Google Fonts)

**Text Styles**:
```dart
Display Large:      32px, Bold, Primary Text
Display Medium:     28px, Bold, Primary Text
Display Small:      24px, SemiBold, Primary Text
Headline Medium:    20px, SemiBold, Primary Text
Title Large:        18px, SemiBold, Primary Text
Title Medium:       16px, Medium, Primary Text
Body Large:         16px, Regular, Primary Text
Body Medium:        14px, Regular, Secondary Text
Body Small:         12px, Regular, Hint Text
```

### Component Styles

#### Buttons

**Elevated Button**:
```dart
Background:         Primary Orange (#FFA726)
Text:               White
Padding:            32px horizontal, 16px vertical
Border Radius:      12px
Elevation:          2
Font:               Poppins, 16px, SemiBold
```

**Outlined Button**:
```dart
Border:             Primary Orange, 2px
Text:               Primary Orange
Padding:            32px horizontal, 16px vertical
Border Radius:      12px
Font:               Poppins, 16px, SemiBold
```

#### Cards

```dart
Background:         Card Background
Border Radius:      16px
Elevation:          4 (dark), 2 (light)
Margin:             16px horizontal, 8px vertical
Padding:            16px
```

#### Input Fields

```dart
Background:         Surface
Border:             None (filled style)
Border Radius:      12px
Padding:            20px horizontal, 16px vertical
Focus Border:       Primary Orange, 2px
Error Border:       Error Red, 2px
Font:               Poppins, 16px
```

#### App Bar

```dart
Background:         Surface
Elevation:          0
Title Font:         Poppins, 20px, SemiBold
Icon Color:         Primary Orange
Center Title:       true
```

### Spacing System

```dart
Extra Small:        4px
Small:              8px
Medium:             16px
Large:              24px
Extra Large:        32px
```

### Border Radius

```dart
Small:              8px
Medium:             12px
Large:              16px
Extra Large:        24px
Circle:             50%
```

### Elevation

```dart
Level 0:            0dp (flat)
Level 1:            2dp (cards in light theme)
Level 2:            4dp (cards in dark theme, FAB)
Level 3:            8dp (bottom nav, dialogs)
Level 4:            16dp (modals)
```

### Icons

**Icon Theme**:
```dart
Color:              Primary Orange
Size:               24px
```

**Common Icons**:
- Home: `Icons.home`
- Offers: `Icons.local_offer`
- Profile: `Icons.person`
- Add: `Icons.add`
- Edit: `Icons.edit`
- Delete: `Icons.delete`
- Like: `Icons.favorite`
- Share: `Icons.share`
- Location: `Icons.location_on`
- Category: `Icons.category`

### Gradients

**Primary Gradient**:
```dart
LinearGradient(
  colors: [#FFA726, #F57C00],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight
)
```

**Accent Gradient**:
```dart
LinearGradient(
  colors: [#26C6DA, #00ACC1],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight
)
```

**Background Gradient (Dark)**:
```dart
LinearGradient(
  colors: [#0A0E21, #1D1E33],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter
)
```

### Animations

**Duration**:
```dart
Fast:               200ms
Normal:             300ms
Slow:               500ms
```

**Curves**:
```dart
Standard:           Curves.easeInOut
Emphasized:         Curves.easeOutCubic
Decelerate:         Curves.easeOut
```

### Responsive Breakpoints

```dart
Mobile:             < 600px
Tablet:             600px - 1024px
Desktop:            > 1024px
```

### Accessibility

**Minimum Touch Target**: 48x48 dp  
**Minimum Text Size**: 12px  
**Contrast Ratio**: 4.5:1 (normal text), 3:1 (large text)

---


## Deployment & DevOps

### Current Deployment

#### Backend (Server)

**Platform**: Render.com  
**URL**: https://MyOffers.onrender.com  
**Environment**: Production  
**Region**: Auto (closest to users)

**Configuration**:
```yaml
# render.yaml
services:
  - type: web
    name: MyOffers-api
    env: node
    buildCommand: npm install
    startCommand: npm start
    envVars:
      - key: NODE_ENV
        value: production
      - key: PORT
        value: 3000
      - key: MONGODB_URI
        sync: false
      - key: JWT_SECRET
        sync: false
      - key: CLOUDINARY_CLOUD_NAME
        sync: false
      - key: CLOUDINARY_API_KEY
        sync: false
      - key: CLOUDINARY_API_SECRET
        sync: false
```

**Auto-Deploy**: Enabled (on git push to main)

#### Database

**Platform**: MongoDB Atlas  
**Cluster**: Cluster0  
**Region**: AWS - Mumbai (ap-south-1)  
**Tier**: M0 (Free)  
**Connection**: mongodb+srv://...

**Features**:
- Automatic backups
- Point-in-time recovery
- Performance monitoring
- Security: IP whitelist, encryption at rest

#### Frontend (Client)

**Platform**: Not yet deployed  
**Planned**: Firebase Hosting / Vercel / Netlify

---

### Deployment Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    USERS                                 │
│  Mobile App (Android/iOS) + Web App                      │
└─────────────────────────────────────────────────────────┘
                          ↓ HTTPS
┌─────────────────────────────────────────────────────────┐
│                    CDN (Cloudinary)                      │
│  Static Assets (Images, Videos)                          │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                    LOAD BALANCER                         │
│  Render.com (Auto-scaling)                               │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                    API SERVERS                           │
│  Node.js/Express (Multiple instances)                    │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                    DATABASE                              │
│  MongoDB Atlas (Replica Set)                             │
└─────────────────────────────────────────────────────────┘
```

---

### Environment Variables

#### Development (.env)
```bash
NODE_ENV=development
PORT=3000
MONGODB_URI=mongodb://localhost:27017/MyOffers
JWT_SECRET=dev-secret-change-in-production
MASTER_OTP=999999
SEND_OTP_VIA_SMS=false
```

#### Production (Render.com)
```bash
NODE_ENV=production
PORT=3000
MONGODB_URI=mongodb+srv://...
JWT_SECRET=<strong-random-secret>
MASTER_OTP=<disabled>
SEND_OTP_VIA_SMS=true
TWILIO_ACCOUNT_SID=<twilio-sid>
TWILIO_AUTH_TOKEN=<twilio-token>
TWILIO_PHONE_NUMBER=<twilio-number>
CLOUDINARY_CLOUD_NAME=drlhpylut
CLOUDINARY_API_KEY=492165161531146
CLOUDINARY_API_SECRET=<secret>
```

---

### CI/CD Pipeline (Planned)

#### GitHub Actions Workflow

```yaml
# .github/workflows/deploy.yml
name: Deploy to Production

on:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Setup Node.js
        uses: actions/setup-node@v2
        with:
          node-version: '18'
      - name: Install dependencies
        run: npm install
      - name: Run tests
        run: npm test
      - name: Run linter
        run: npm run lint

  deploy:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Deploy to Render
        run: |
          curl -X POST ${{ secrets.RENDER_DEPLOY_HOOK }}
```

---

### Monitoring & Logging

#### Application Monitoring (Planned)

**Sentry** - Error tracking
```javascript
const Sentry = require('@sentry/node');

Sentry.init({
  dsn: process.env.SENTRY_DSN,
  environment: process.env.NODE_ENV,
  tracesSampleRate: 1.0,
});
```

**LogRocket** - Session replay
```javascript
LogRocket.init('app-id');
```

#### Performance Monitoring

**New Relic** or **Datadog** (Planned)
- API response times
- Database query performance
- Error rates
- Memory usage
- CPU usage

#### Logging

**Winston** - Structured logging
```javascript
const winston = require('winston');

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  transports: [
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' }),
  ],
});
```

---

### Backup Strategy

#### Database Backups

**Automated** (MongoDB Atlas):
- Continuous backups
- Point-in-time recovery (last 24 hours)
- Snapshot frequency: Every 6 hours
- Retention: 7 days

**Manual Backups**:
```bash
# Export database
mongodump --uri="mongodb+srv://..." --out=./backup

# Import database
mongorestore --uri="mongodb+srv://..." ./backup
```

#### Code Backups

- Git repository (GitHub)
- Multiple branches (main, develop, feature/*)
- Protected main branch
- Pull request reviews required

---

### Scaling Strategy

#### Horizontal Scaling

**API Servers**:
- Auto-scaling on Render.com
- Scale based on CPU/memory usage
- Min instances: 1
- Max instances: 10

**Database**:
- MongoDB Atlas auto-scaling
- Vertical scaling (upgrade tier)
- Sharding (for large datasets)

#### Caching (Planned)

**Redis** - In-memory cache
```javascript
const redis = require('redis');
const client = redis.createClient({
  url: process.env.REDIS_URL
});

// Cache offer list
await client.setEx('offers:110001', 300, JSON.stringify(offers));
```

**Cache Strategy**:
- Offer lists: 5 minutes
- User profiles: 10 minutes
- Subscription status: 1 minute
- Static data (categories): 1 hour

---

### Security Measures

#### SSL/TLS
- Automatic SSL certificate (Render.com)
- HTTPS enforced
- TLS 1.2+ only

#### Firewall
- MongoDB Atlas IP whitelist
- Rate limiting (Express Rate Limit)
- DDoS protection (Cloudflare - planned)

#### Secrets Management
- Environment variables (never in code)
- Render.com secret management
- Rotate secrets quarterly

#### Security Headers (Planned)
```javascript
const helmet = require('helmet');
app.use(helmet());
```

---

### Disaster Recovery

#### Recovery Time Objective (RTO)
- Target: 1 hour
- Maximum acceptable downtime

#### Recovery Point Objective (RPO)
- Target: 15 minutes
- Maximum acceptable data loss

#### Recovery Plan
1. Detect issue (monitoring alerts)
2. Assess impact
3. Restore from backup (if needed)
4. Verify data integrity
5. Resume operations
6. Post-mortem analysis

---

### Performance Optimization

#### Backend
- Database indexing
- Query optimization
- Connection pooling
- Compression (gzip)
- Caching layer

#### Frontend
- Image optimization (Cloudinary)
- Lazy loading
- Code splitting
- Minification
- CDN delivery

#### Database
- Proper indexes
- Query optimization
- Connection pooling
- Read replicas (planned)

---

### Cost Estimation

#### Current Costs (Monthly)

| Service | Tier | Cost |
|---------|------|------|
| Render.com | Free | $0 |
| MongoDB Atlas | M0 (Free) | $0 |
| Cloudinary | Free | $0 |
| **Total** | | **$0** |

#### Projected Costs (Production)

| Service | Tier | Cost |
|---------|------|------|
| Render.com | Standard | $25 |
| MongoDB Atlas | M10 | $57 |
| Cloudinary | Plus | $89 |
| Redis | Basic | $15 |
| Sentry | Team | $26 |
| **Total** | | **$212/month** |

---


## Appendix

### A. Folder Structure (Complete)

#### Server Structure
```
server/
├── src/
│   ├── config/
│   │   ├── index.js                     # App configuration
│   │   └── cloudinary.js                # Cloudinary setup
│   ├── controllers/
│   │   ├── authController.js
│   │   ├── offerController.js
│   │   ├── shopkeeperProfileController.js
│   │   ├── customerController.js
│   │   ├── adminController.js
│   │   ├── superAdminController.js
│   │   ├── onboardingController.js
│   │   ├── subscriptionController.js
│   │   ├── subscriptionPlanController.js
│   │   ├── subscriptionGovernanceController.js
│   │   ├── uploadController.js
│   │   └── metaController.js
│   ├── middleware/
│   │   ├── auth.js
│   │   ├── roleAuth.js
│   │   ├── roleCheck.js
│   │   ├── subscriptionCheck.js
│   │   ├── upload.js
│   │   └── errorHandler.js
│   ├── models/
│   │   ├── User.js
│   │   ├── Offer.js
│   │   ├── ShopkeeperProfile.js
│   │   ├── Subscription.js
│   │   ├── SubscriptionPlan.js
│   │   ├── OnboardingStatus.js
│   │   ├── AuditLog.js
│   │   └── Otp.js
│   ├── routes/
│   │   ├── index.js
│   │   ├── authRoutes.js
│   │   ├── shopkeeperRoutes.js
│   │   ├── customerRoutes.js
│   │   ├── adminRoutes.js
│   │   ├── superAdminRoutes.js
│   │   ├── onboardingRoutes.js
│   │   ├── subscriptionRoutes.js
│   │   ├── subscriptionGovernanceRoutes.js
│   │   ├── offerRoutes.js
│   │   ├── uploadRoutes.js
│   │   ├── metaRoutes.js
│   │   ├── ssaRoutes.js
│   │   ├── companySalesRoutes.js
│   │   └── subadminRoutes.js
│   ├── services/
│   │   ├── otpService.js
│   │   └── pincodeService.js
│   ├── jobs/
│   │   └── subscriptionExpiry.js
│   └── app.js
├── scripts/
│   ├── seedAdmin.js
│   ├── migrate-phase1.js
│   ├── create-super-admin.js
│   ├── test-super-admin.js
│   └── seed-subscription-plans.js
├── .env
├── .gitignore
├── index.js
├── package.json
└── README.md
```

#### Client Structure
```
client/
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart
│   │   │   └── app_constants.dart
│   │   ├── theme/
│   │   │   └── app_theme.dart
│   │   └── utils/
│   │       └── validators.dart
│   ├── models/
│   │   ├── user_model.dart
│   │   ├── offer_model.dart
│   │   ├── shopkeeper_profile_model.dart
│   │   └── role_enum.dart
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   ├── theme_provider.dart
│   │   └── offer_provider.dart
│   ├── screens/
│   │   ├── auth/
│   │   ├── customer/
│   │   ├── shopkeeper/
│   │   ├── admin/
│   │   ├── super_admin/
│   │   ├── common/
│   │   └── splash/
│   ├── services/
│   │   ├── api_config.dart
│   │   ├── auth_service.dart
│   │   ├── auth_store.dart
│   │   ├── offer_service.dart
│   │   ├── upload_service.dart
│   │   └── super_admin_service.dart
│   ├── widgets/
│   │   ├── custom_button.dart
│   │   ├── custom_text_field.dart
│   │   ├── offer_card.dart
│   │   ├── gradient_card.dart
│   │   ├── theme_toggle.dart
│   │   └── profile_option_tile.dart
│   └── main.dart
├── assets/
│   └── Dofferlogo.png
├── android/
├── ios/
├── web/
├── pubspec.yaml
├── analysis_options.yaml
└── README.md
```

---

### B. API Quick Reference

#### Authentication
```
POST   /api/auth/send-otp          Send OTP
POST   /api/auth/verify-otp        Verify OTP & login
GET    /api/auth/me                Get current user
PUT    /api/auth/me                Update current user
```

#### Shopkeeper
```
GET    /api/shopkeeper/profile     Get profile
PUT    /api/shopkeeper/profile     Update profile
GET    /api/shopkeeper/dashboard   Get dashboard
POST   /api/shopkeeper/offers      Create offer
GET    /api/shopkeeper/offers      List offers
PUT    /api/shopkeeper/offers/:id  Update offer
DELETE /api/shopkeeper/offers/:id  Delete offer
```

#### Customer
```
GET    /api/customer/offers        Browse offers
GET    /api/customer/offers/:id    View offer
POST   /api/customer/offers/:id/like  Like/unlike
GET    /api/customer/offers/liked  LikeMyOffers
```

#### Onboarding
```
GET    /api/onboarding/status      Get status
POST   /api/onboarding/accept-terms  Accept T&C
POST   /api/onboarding/complete-profile  Complete profile
POST   /api/onboarding/complete    Complete onboarding
```

#### Subscription
```
GET    /api/subscription           Get subscription
GET    /api/subscription/plans     List plans
POST   /api/subscription/trial     Activate trial
POST   /api/subscription/activate  Activate paid plan
POST   /api/subscription/cancel    Cancel subscription
```

#### Super Admin
```
GET    /api/super-admin/analytics  Dashboard analytics
GET    /api/super-admin/users      List all users
PATCH  /api/super-admin/users/:id/status  Toggle status
GET    /api/super-admin/audit-logs  View audit logs
```

#### Subscription Governance
```
POST   /api/subscription-governance/plans  Create plan
GET    /api/subscription-governance/plans  List plans
PUT    /api/subscription-governance/plans/:id  Update plan
GET    /api/subscription-governance/revenue/analytics  Revenue analytics
```

---

### C. Database Quick Reference

#### Collections
- `users` - User accounts
- `shopkeeperprofiles` - Shop details
- `offers` - Promotional offers
- `subscriptions` - Subscription records
- `subscriptionplans` - Available plans
- `onboardingstatuses` - Onboarding progress
- `auditlogs` - Activity logs
- `otps` - OTP records

#### Key Indexes
```javascript
users: { phone: 1 }, { role: 1 }
offers: { shopkeeperId: 1 }, { pincode: 1, category: 1 }
subscriptions: { userId: 1 }, { status: 1 }
auditlogs: { userId: 1 }, { timestamp: -1 }
```

---

### D. Common Commands

#### Server
```bash
# Development
npm run dev

# Production
npm start

# Create super admin
npm run create:superadmin

# Seed subscription plans
npm run seed:plans

# Database migration
npm run migrate:admin
```

#### Client
```bash
# Run on device
flutter run

# Build APK
flutter build apk

# Build iOS
flutter build ios

# Clean build
flutter clean
flutter pub get
```

---

### E. Troubleshooting

#### Server Issues

**MongoDB Connection Failed**
```bash
# Check connection string
echo $MONGODB_URI

# Test connection
mongosh "mongodb+srv://..."
```

**JWT Token Invalid**
```bash
# Check secret
echo $JWT_SECRET

# Verify token expiry
# Default: 7 days
```

**OTP Not Sending**
```bash
# Check SMS settings
echo $SEND_OTP_VIA_SMS

# Use master OTP in dev
echo $MASTER_OTP
```

#### Client Issues

**API Connection Failed**
```dart
// Check API config
print(ApiConfig.baseUrl);

// Android emulator: use 10.0.2.2
// iOS simulator: use localhost
```

**Image Upload Failed**
```dart
// Check Cloudinary config
// Verify file size < 10MB
// Check internet connection
```

---

### F. Contact & Support

**Development Team**:
- Backend: Node.js/Express
- Frontend: Flutter/Dart
- Database: MongoDB
- DevOps: Render.com, MongoDB Atlas

**Repository**: [GitHub URL]  
**Documentation**: This file  
**API Docs**: [Postman Collection URL]

---

### G. Changelog

#### Version 1.0.0 (Current)
- ✅ 6-role RBAC system
- ✅ OTP authentication
- ✅ Subscription management
- ✅ Onboarding workflow
- ✅ Offer CRUD operations
- ✅ Audit logging
- ✅ Super admin dashboard
- 🔄 Customer experience (in progress)

#### Planned Features
- 📋 Payment integration (Razorpay)
- 📋 AI recommendations
- 📋 AI chatbot
- 📋 Push notifications
- 📋 Advanced analytics
- 📋 Performance optimization

---

### H. License

**Proprietary Software**  
© 2026 MyOffers. All rights reserved.

This software and associated documentation files are proprietary and confidential. Unauthorized copying, distribution, or use is strictly prohibited.

---

### I. Glossary

- **RBAC**: Role-Based Access Control
- **JWT**: JSON Web Token
- **OTP**: One-Time Password
- **MRR**: Monthly Recurring Revenue
- **SSA**: Sales Service Agent
- **ODM**: Object Document Mapper (Mongoose)
- **CDN**: Content Delivery Network
- **API**: Application Programming Interface
- **CRUD**: Create, Read, Update, Delete
- **SMS**: Short Message Service
- **SSL**: Secure Sockets Layer
- **TLS**: Transport Layer Security

---

## End of Documentation

**Document Version**: 1.0.0  
**Last Updated**: February 20, 2026  
**Total Pages**: 50+  
**Format**: Markdown

For updates and revisions, please refer to the version control system.

