# Governance API Endpoints Documentation

## Base URL
`/api/subscription-governance`

All endpoints require authentication and super_admin role unless specified otherwise.

---

## Business Categories

### Get All Categories
```
GET /api/meta/categories
```
**Public endpoint** - No authentication required

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "value": "retail",
      "label": "Retail Store"
    },
    {
      "value": "restaurant",
      "label": "Restaurant"
    },
    ...
  ]
}
```

**Available Categories:**
- `retail` - Retail Store
- `restaurant` - Restaurant
- `grocery` - Grocery Store
- `pharmacy` - Pharmacy
- `electronics` - Electronics
- `clothing` - Clothing & Fashion
- `beauty_salon` - Beauty Salon & Spa
- `gym_fitness` - Gym & Fitness
- `education` - Education & Training
- `healthcare` - Healthcare
- `automotive` - Automotive
- `home_services` - Home Services
- `entertainment` - Entertainment
- `food_beverage` - Food & Beverage
- `jewelry` - Jewelry
- `books_stationery` - Books & Stationery
- `sports` - Sports & Outdoors
- `pet_care` - Pet Care
- `travel` - Travel & Tourism
- `other` - Other
- `all` - All Categories (for plans only)

---

## Subscription Plans Management

### Get All Plans
```
GET /api/subscription-governance/plans
```

**Query Parameters:**
- `isActive` (boolean, optional) - Filter by active status
- `category` (string, optional) - Filter by category

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "_id": "plan_id",
      "name": "basic_retail",
      "displayName": "Basic Plan - Retail",
      "description": "Perfect for small retail stores",
      "monthlyPrice": 999,
      "durationDays": 30,
      "category": "retail",
      "features": ["10 offers per month", "Basic analytics"],
      "maxOffers": 10,
      "maxPhotosPerOffer": 5,
      "analyticsEnabled": false,
      "prioritySupport": false,
      "isActive": true,
      "sortOrder": 0,
      "createdAt": "2024-01-01T00:00:00.000Z",
      "updatedAt": "2024-01-01T00:00:00.000Z"
    }
  ]
}
```

### Create Plan
```
POST /api/subscription-governance/plans
```

**Request Body:**
```json
{
  "name": "basic_retail",
  "displayName": "Basic Plan - Retail",
  "description": "Perfect for small retail stores",
  "monthlyPrice": 999,
  "durationDays": 30,
  "category": "retail",
  "features": ["10 offers per month", "Basic analytics"],
  "maxOffers": 10,
  "maxPhotosPerOffer": 5,
  "analyticsEnabled": false,
  "prioritySupport": false,
  "sortOrder": 0
}
```

**Required Fields:**
- `name` - Unique identifier (lowercase, no spaces)
- `displayName` - Display name for users
- `monthlyPrice` - Price in rupees
- `category` - Business category (from enum)

**Response:**
```json
{
  "success": true,
  "message": "Subscription plan created successfully",
  "data": { /* plan object */ }
}
```

### Get Plan by ID
```
GET /api/subscription-governance/plans/:planId
```

**Response:**
```json
{
  "success": true,
  "data": {
    /* plan object */
    "activeSubscriptions": 15
  }
}
```

### Update Plan
```
PATCH /api/subscription-governance/plans/:planId
```

**Request Body:** (all fields optional)
```json
{
  "displayName": "Updated Plan Name",
  "description": "Updated description",
  "monthlyPrice": 1499,
  "durationDays": 30,
  "category": "restaurant",
  "features": ["Unlimited offers", "Advanced analytics"],
  "maxOffers": -1,
  "maxPhotosPerOffer": 10,
  "analyticsEnabled": true,
  "prioritySupport": true,
  "sortOrder": 1,
  "isActive": true,
  "priceChangeReason": "Market adjustment"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Plan updated successfully",
  "data": { /* updated plan */ }
}
```

### Delete Plan
```
DELETE /api/subscription-governance/plans/:planId
```

**Note:** Soft delete - deactivates the plan. Cannot delete plans with active subscriptions.

**Response:**
```json
{
  "success": true,
  "message": "Plan deactivated successfully"
}
```

### Get Recommended Plans
```
GET /api/subscription-governance/plans/recommend/category?category=retail
```

**Query Parameters:**
- `category` (required) - Business category

**Response:**
```json
{
  "success": true,
  "data": [
    /* plans for this category or 'all' categories */
  ]
}
```

---

## Subscriptions Management

### Get All Subscriptions
```
GET /api/subscription-governance/subscriptions
```

**Query Parameters:**
- `status` (string, optional) - Filter by status (active, expired, cancelled, pending)
- `planId` (string, optional) - Filter by plan ID
- `shopkeeperId` (string, optional) - Filter by shopkeeper ID
- `expiringSoon` (boolean, optional) - Get subscriptions expiring in next 7 days
- `page` (number, optional, default: 1) - Page number
- `limit` (number, optional, default: 20) - Items per page

**Response:**
```json
{
  "success": true,
  "data": {
    "subscriptions": [
      {
        "_id": "sub_id",
        "shopkeeperId": {
          "_id": "user_id",
          "name": "Shop Owner",
          "phone": "9876543210"
        },
        "planId": {
          "_id": "plan_id",
          "displayName": "Basic Plan",
          "monthlyPrice": 999
        },
        "status": "active",
        "startDate": "2024-01-01T00:00:00.000Z",
        "endDate": "2024-01-31T23:59:59.999Z",
        "actualPrice": 999,
        "autoRenew": false,
        "paymentStatus": "paid",
        "createdAt": "2024-01-01T00:00:00.000Z"
      }
    ],
    "pagination": {
      "total": 100,
      "page": 1,
      "limit": 20,
      "pages": 5
    }
  }
}
```

### Create Subscription
```
POST /api/subscription-governance/subscriptions
```

**Request Body:**
```json
{
  "shopkeeperId": "user_id",
  "planId": "plan_id",
  "startDate": "2024-01-01",
  "durationMonths": 1,
  "autoRenew": false,
  "paymentMethod": "upi",
  "transactionId": "TXN123456",
  "notes": "Manual subscription creation"
}
```

**Required Fields:**
- `shopkeeperId` - User ID of shopkeeper
- `planId` - Subscription plan ID

**Response:**
```json
{
  "success": true,
  "message": "Subscription created successfully",
  "data": { /* subscription object */ }
}
```

### Update Subscription
```
PATCH /api/subscription-governance/subscriptions/:subscriptionId
```

**Request Body:** (all fields optional)
```json
{
  "status": "active",
  "endDate": "2024-02-28",
  "autoRenew": true,
  "notes": "Extended by admin"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Subscription updated successfully",
  "data": { /* updated subscription */ }
}
```

### Cancel Subscription
```
POST /api/subscription-governance/subscriptions/:subscriptionId/cancel
```

**Request Body:**
```json
{
  "reason": "Customer request"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Subscription cancelled successfully",
  "data": { /* cancelled subscription */ }
}
```

### Renew Subscription
```
POST /api/subscription-governance/subscriptions/:subscriptionId/renew
```

**Request Body:**
```json
{
  "durationMonths": 1,
  "paymentMethod": "upi",
  "transactionId": "TXN789012"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Subscription renewed successfully",
  "data": { /* renewed subscription */ }
}
```

---

## Monitoring & Analytics

### Get Monitoring Dashboard
```
GET /api/subscription-governance/monitoring/dashboard
```

**Response:**
```json
{
  "success": true,
  "data": {
    "statusCounts": {
      "active": {
        "count": 150,
        "revenue": 149850
      },
      "expired": {
        "count": 25,
        "revenue": 24975
      }
    },
    "expiringSoon": {
      "count": 12,
      "subscriptions": [ /* subscriptions expiring in 7 days */ ]
    },
    "recentlyExpired": {
      "count": 8,
      "subscriptions": [ /* subscriptions expired in last 7 days */ ]
    },
    "pending": {
      "count": 3,
      "subscriptions": [ /* pending subscriptions */ ]
    },
    "mrr": 149850
  }
}
```

### Get Revenue Intelligence
```
GET /api/subscription-governance/intelligence/revenue
```

**Response:**
```json
{
  "success": true,
  "data": {
    "currentMRR": 149850,
    "activeSubscriptions": 150,
    "projectedMRR": 145000,
    "growthTrend": [
      {
        "_id": { "year": 2024, "month": 1 },
        "newSubscriptions": 45,
        "revenue": 44955
      }
    ],
    "churnData": [
      {
        "_id": { "year": 2024, "month": 1, "status": "expired" },
        "count": 8
      }
    ],
    "planDistribution": [
      {
        "_id": "Basic Plan",
        "count": 100,
        "revenue": 99900
      },
      {
        "_id": "Premium Plan",
        "count": 50,
        "revenue": 99950
      }
    ],
    "alerts": {
      "unusualDrop": false,
      "dropPercentage": 0,
      "expiringNextMonth": 15
    }
  }
}
```

### Run Expiry Check
```
POST /api/subscription-governance/maintenance/expire-check
```

**Note:** This endpoint is meant for cron jobs to automatically expire subscriptions.

**Response:**
```json
{
  "success": true,
  "message": "Expiry check completed",
  "data": {
    "modifiedCount": 5
  }
}
```

---

## Error Responses

All endpoints return errors in this format:

```json
{
  "success": false,
  "message": "Error description"
}
```

**Common HTTP Status Codes:**
- `200` - Success
- `201` - Created
- `400` - Bad Request (validation error)
- `401` - Unauthorized
- `403` - Forbidden (insufficient permissions)
- `404` - Not Found
- `500` - Internal Server Error

---

## Notes

1. **Category-Based Plans**: Each plan is tied to a specific business category or 'all' categories
2. **Price History**: All price changes are tracked with admin ID, timestamp, and reason
3. **Soft Delete**: Plans are deactivated, not deleted, to maintain historical data
4. **Auto-Renewal**: Subscriptions can be set to auto-renew
5. **MRR Calculation**: Monthly Recurring Revenue is calculated from active subscriptions
6. **Expiry Alerts**: System tracks subscriptions expiring in next 7 days
7. **Churn Analysis**: Tracks expired and cancelled subscriptions for last 3 months
