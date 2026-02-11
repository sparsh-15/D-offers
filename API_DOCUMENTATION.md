# API Documentation

Base URL: `http://localhost:3000/api`

## Authentication Flow

### 1. Signup (New User)

**Endpoint:** `POST /api/auth/signup`

**Request Body:**
```json
{
  "role": "customer",
  "phone": "9876543210",
  "name": "John Doe",
  "pincode": "110001",
  "address": "123 Main St"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Signup OTP sent"
}
```

**Error Response (400):**
```json
{
  "success": false,
  "message": "This phone is already registered as customer"
}
```

---

### 2. Send OTP (Login - Existing User)

**Endpoint:** `POST /api/auth/send-otp`

**Request Body:**
```json
{
  "role": "customer",
  "phone": "9876543210"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "OTP sent"
}
```

**Error Response (404):**
```json
{
  "success": false,
  "message": "Account not found. Please signup first."
}
```

**Error Response (400):**
```json
{
  "success": false,
  "message": "This phone is registered as shopkeeper"
}
```

---

### 3. Verify OTP

**Endpoint:** `POST /api/auth/verify-otp`

**Request Body:**
```json
{
  "role": "customer",
  "phone": "9876543210",
  "otp": "123456"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "507f1f77bcf86cd799439011",
    "phone": "9876543210",
    "role": "customer"
  }
}
```

**Error Response (401):**
```json
{
  "success": false,
  "message": "Invalid or expired OTP"
}
```

**Error Response (404):**
```json
{
  "success": false,
  "message": "Account not found. Please signup first."
}
```

---

### 4. Get Current User

**Endpoint:** `GET /api/auth/me`

**Headers:**
```
Authorization: Bearer <token>
```

**Success Response (200):**
```json
{
  "success": true,
  "user": {
    "id": "507f1f77bcf86cd799439011",
    "name": "John Doe",
    "phone": "9876543210",
    "role": "customer",
    "pincode": "110001",
    "city": "New Delhi",
    "state": "Delhi",
    "address": "123 Main St",
    "approvalStatus": "approved",
    "createdAt": "2024-01-01T00:00:00.000Z"
  }
}
```

---

### 5. Get Last OTP (Dev Only)

**Endpoint:** `GET /api/auth/dev/last-otp?phone=9876543210`

**Success Response (200):**
```json
{
  "success": true,
  "otp": "123456",
  "expiresAt": "2024-01-01T00:10:00.000Z"
}
```

---

## Customer Endpoints

### Get Offers

**Endpoint:** `GET /api/customer/offers?pincode=110001`

**Headers:**
```
Authorization: Bearer <token>
```

**Success Response (200):**
```json
{
  "success": true,
  "offers": [
    {
      "id": "507f1f77bcf86cd799439011",
      "title": "50% Off on Electronics",
      "description": "Limited time offer",
      "discountType": "percentage",
      "discountValue": 50,
      "validFrom": "2024-01-01T00:00:00.000Z",
      "validTo": "2024-12-31T23:59:59.000Z",
      "status": "active",
      "shopkeeper": {
        "id": "507f1f77bcf86cd799439012",
        "name": "Tech Store",
        "phone": "9876543211"
      }
    }
  ]
}
```

---

## Shopkeeper Endpoints

### Get Profile

**Endpoint:** `GET /api/shopkeeper/profile`

**Headers:**
```
Authorization: Bearer <token>
```

**Success Response (200):**
```json
{
  "success": true,
  "profile": {
    "shopName": "Tech Store",
    "address": "456 Market St",
    "pincode": "110001",
    "city": "New Delhi",
    "category": "Electronics",
    "description": "Best electronics in town"
  }
}
```

**Not Found (404):**
```json
{
  "success": false,
  "message": "Profile not found"
}
```

---

### Update Profile

**Endpoint:** `PUT /api/shopkeeper/profile`

**Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "shopName": "Tech Store",
  "address": "456 Market St",
  "pincode": "110001",
  "city": "New Delhi",
  "category": "Electronics",
  "description": "Best electronics in town"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "profile": {
    "shopName": "Tech Store",
    "address": "456 Market St",
    "pincode": "110001",
    "city": "New Delhi",
    "category": "Electronics",
    "description": "Best electronics in town"
  }
}
```

---

### Get My Offers

**Endpoint:** `GET /api/shopkeeper/offers`

**Headers:**
```
Authorization: Bearer <token>
```

**Success Response (200):**
```json
{
  "success": true,
  "offers": [
    {
      "id": "507f1f77bcf86cd799439011",
      "title": "50% Off",
      "description": "Limited time",
      "discountType": "percentage",
      "discountValue": 50,
      "validFrom": "2024-01-01T00:00:00.000Z",
      "validTo": "2024-12-31T23:59:59.000Z",
      "status": "active"
    }
  ]
}
```

---

### Create Offer

**Endpoint:** `POST /api/shopkeeper/offers`

**Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "title": "50% Off on Electronics",
  "description": "Limited time offer",
  "discountType": "percentage",
  "discountValue": 50,
  "validFrom": "2024-01-01T00:00:00.000Z",
  "validTo": "2024-12-31T23:59:59.000Z"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "offer": {
    "id": "507f1f77bcf86cd799439011",
    "title": "50% Off on Electronics",
    "description": "Limited time offer",
    "discountType": "percentage",
    "discountValue": 50,
    "validFrom": "2024-01-01T00:00:00.000Z",
    "validTo": "2024-12-31T23:59:59.000Z",
    "status": "active"
  }
}
```

---

### Update Offer

**Endpoint:** `PUT /api/shopkeeper/offers/:id`

**Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "title": "60% Off on Electronics",
  "status": "inactive"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "offer": {
    "id": "507f1f77bcf86cd799439011",
    "title": "60% Off on Electronics",
    "status": "inactive"
  }
}
```

---

### Delete Offer

**Endpoint:** `DELETE /api/shopkeeper/offers/:id`

**Headers:**
```
Authorization: Bearer <token>
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Offer deleted"
}
```

---

## Admin Endpoints

### Get Shopkeepers

**Endpoint:** `GET /api/admin/shopkeepers?status=pending`

**Headers:**
```
Authorization: Bearer <token>
```

**Query Parameters:**
- `status` (optional): pending | approved | rejected

**Success Response (200):**
```json
{
  "success": true,
  "shopkeepers": [
    {
      "id": "507f1f77bcf86cd799439011",
      "name": "Shop Owner",
      "phone": "9876543210",
      "role": "shopkeeper",
      "pincode": "110001",
      "city": "New Delhi",
      "state": "Delhi",
      "address": "123 Main St",
      "approvalStatus": "pending",
      "createdAt": "2024-01-01T00:00:00.000Z"
    }
  ]
}
```

---

### Approve Shopkeeper

**Endpoint:** `PATCH /api/admin/shopkeepers/:id/approve`

**Headers:**
```
Authorization: Bearer <token>
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Shopkeeper approved"
}
```

---

### Reject Shopkeeper

**Endpoint:** `PATCH /api/admin/shopkeepers/:id/reject`

**Headers:**
```
Authorization: Bearer <token>
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Shopkeeper rejected"
}
```

---

## Error Responses

All endpoints may return these common errors:

**400 Bad Request:**
```json
{
  "success": false,
  "message": "Validation error message"
}
```

**401 Unauthorized:**
```json
{
  "success": false,
  "message": "Invalid or expired token"
}
```

**403 Forbidden:**
```json
{
  "success": false,
  "message": "Access denied"
}
```

**404 Not Found:**
```json
{
  "success": false,
  "message": "Resource not found"
}
```

**500 Internal Server Error:**
```json
{
  "success": false,
  "message": "Internal server error"
}
```

---

## Notes

1. All authenticated endpoints require `Authorization: Bearer <token>` header
2. Master OTP for testing: `999999`
3. Phone numbers should be 10 digits
4. Pincodes should be 6 digits
5. Roles: `customer`, `shopkeeper`, `admin`
6. Approval statuses: `pending`, `approved`, `rejected`
7. Offer statuses: `active`, `inactive`
8. Discount types: `percentage`, `fixed`
