# Super Admin System Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     SUPER ADMIN SYSTEM                          │
│                                                                 │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐    │
│  │   Flutter    │    │   Express    │    │   MongoDB    │    │
│  │   Frontend   │◄──►│   Backend    │◄──►│   Database   │    │
│  └──────────────┘    └──────────────┘    └──────────────┘    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Component Architecture

### Frontend Layer (Flutter)
```
┌─────────────────────────────────────────────────────────┐
│                    Flutter App                          │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────────────────────────────────────┐     │
│  │         SuperAdminDashboard                  │     │
│  │  - System Overview                           │     │
│  │  - Analytics Cards                           │     │
│  │  - Quick Actions                             │     │
│  └──────────────────────────────────────────────┘     │
│                                                         │
│  ┌──────────────────────────────────────────────┐     │
│  │      UsersManagementScreen                   │     │
│  │  - User List                                 │     │
│  │  - Filters & Search                          │     │
│  │  - Activate/Deactivate                       │     │
│  │  - Approve/Reject                            │     │
│  └──────────────────────────────────────────────┘     │
│                                                         │
│  ┌──────────────────────────────────────────────┐     │
│  │      ShopsManagementScreen                   │     │
│  │  - Shop List                                 │     │
│  │  - Subscription Status                       │     │
│  │  - Filters & Search                          │     │
│  └──────────────────────────────────────────────┘     │
│                                                         │
│  ┌──────────────────────────────────────────────┐     │
│  │         AuditLogsScreen                      │     │
│  │  - Activity Log                              │     │
│  │  - Action Filters                            │     │
│  │  - Admin Tracking                            │     │
│  └──────────────────────────────────────────────┘     │
│                                                         │
│  ┌──────────────────────────────────────────────┐     │
│  │       SuperAdminService                      │     │
│  │  - API Client                                │     │
│  │  - Token Management                          │     │
│  │  - Error Handling                            │     │
│  └──────────────────────────────────────────────┘     │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Backend Layer (Express)
```
┌─────────────────────────────────────────────────────────┐
│                   Express Server                        │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────────────────────────────────────┐     │
│  │            Middleware Layer                  │     │
│  │  ┌────────────────────────────────────┐     │     │
│  │  │  authMiddleware                    │     │     │
│  │  │  - Verify JWT Token                │     │     │
│  │  │  - Extract User Info               │     │     │
│  │  └────────────────────────────────────┘     │     │
│  │  ┌────────────────────────────────────┐     │     │
│  │  │  requireSuperAdmin                 │     │     │
│  │  │  - Check Role = super_admin        │     │     │
│  │  │  - Return 403 if not authorized    │     │     │
│  │  └────────────────────────────────────┘     │     │
│  └──────────────────────────────────────────────┘     │
│                                                         │
│  ┌──────────────────────────────────────────────┐     │
│  │          Routes Layer                        │     │
│  │  /api/super-admin/*                          │     │
│  │  - /analytics                                │     │
│  │  - /users                                    │     │
│  │  - /users/:id                                │     │
│  │  - /users/:id/status                         │     │
│  │  - /users/:id/approval                       │     │
│  │  - /shops                                    │     │
│  │  - /audit-logs                               │     │
│  └──────────────────────────────────────────────┘     │
│                                                         │
│  ┌──────────────────────────────────────────────┐     │
│  │        Controller Layer                      │     │
│  │  superAdminController                        │     │
│  │  - getDashboardAnalytics()                   │     │
│  │  - getAllUsers()                             │     │
│  │  - getAllShops()                             │     │
│  │  - toggleUserStatus()                        │     │
│  │  - updateApprovalStatus()                    │     │
│  │  - getAuditLogs()                            │     │
│  │  - getUserDetails()                          │     │
│  └──────────────────────────────────────────────┘     │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Database Layer (MongoDB)
```
┌─────────────────────────────────────────────────────────┐
│                   MongoDB Database                      │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────────────────────────────────────┐     │
│  │            Users Collection                  │     │
│  │  - _id, name, phone, role                    │     │
│  │  - isActive, approvalStatus                  │     │
│  │  - pincode, city, state, address             │     │
│  │  - permissions, timestamps                   │     │
│  │                                              │     │
│  │  Indexes:                                    │     │
│  │  - phone (unique)                            │     │
│  │  - role + approvalStatus                     │     │
│  └──────────────────────────────────────────────┘     │
│                                                         │
│  ┌──────────────────────────────────────────────┐     │
│  │      ShopkeeperProfile Collection            │     │
│  │  - _id, userId (ref: User)                   │     │
│  │  - shopName, address, pincode                │     │
│  │  - city, category, description               │     │
│  │  - timestamps                                │     │
│  │                                              │     │
│  │  Indexes:                                    │     │
│  │  - userId (unique)                           │     │
│  └──────────────────────────────────────────────┘     │
│                                                         │
│  ┌──────────────────────────────────────────────┐     │
│  │        Subscription Collection               │     │
│  │  - _id, shopkeeperId (ref: User)             │     │
│  │  - planName, status                          │     │
│  │  - startDate, endDate                        │     │
│  │  - monthlyPrice, autoRenew                   │     │
│  │  - timestamps                                │     │
│  │                                              │     │
│  │  Indexes:                                    │     │
│  │  - shopkeeperId                              │     │
│  │  - status                                    │     │
│  └──────────────────────────────────────────────┘     │
│                                                         │
│  ┌──────────────────────────────────────────────┐     │
│  │         AuditLog Collection                  │     │
│  │  - _id, adminId (ref: User)                  │     │
│  │  - adminRole, action                         │     │
│  │  - targetUserId (ref: User)                  │     │
│  │  - targetUserRole, details                   │     │
│  │  - ipAddress, timestamp                      │     │
│  │                                              │     │
│  │  Indexes:                                    │     │
│  │  - adminId + createdAt                       │     │
│  │  - targetUserId                              │     │
│  │  - action                                    │     │
│  └──────────────────────────────────────────────┘     │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

## Data Flow Diagrams

### 1. User Login Flow
```
┌──────────┐      ┌──────────┐      ┌──────────┐      ┌──────────┐
│  Mobile  │      │   Auth   │      │   JWT    │      │   User   │
│   App    │      │  Service │      │  Service │      │   Model  │
└────┬─────┘      └────┬─────┘      └────┬─────┘      └────┬─────┘
     │                 │                 │                 │
     │  sendOtp()      │                 │                 │
     ├────────────────►│                 │                 │
     │                 │  findUser()     │                 │
     │                 ├────────────────────────────────►  │
     │                 │  ◄────────────────────────────────┤
     │                 │  generateOTP()  │                 │
     │                 ├────────────────►│                 │
     │  ◄──────────────┤                 │                 │
     │                 │                 │                 │
     │  verifyOtp()    │                 │                 │
     ├────────────────►│                 │                 │
     │                 │  validateOTP()  │                 │
     │                 ├────────────────►│                 │
     │                 │  generateToken()│                 │
     │                 ├────────────────►│                 │
     │  ◄──────────────┤  token          │                 │
     │                 │                 │                 │
     │  Store Token    │                 │                 │
     │                 │                 │                 │
```

### 2. Dashboard Analytics Flow
```
┌──────────┐      ┌──────────┐      ┌──────────┐      ┌──────────┐
│Dashboard │      │  Super   │      │   User   │      │Subscription│
│  Screen  │      │  Admin   │      │   Model  │      │   Model   │
│          │      │Controller│      │          │      │           │
└────┬─────┘      └────┬─────┘      └────┬─────┘      └────┬─────┘
     │                 │                 │                 │
     │ getAnalytics()  │                 │                 │
     ├────────────────►│                 │                 │
     │                 │  aggregate()    │                 │
     │                 ├────────────────►│                 │
     │                 │  usersByRole    │                 │
     │                 │◄────────────────┤                 │
     │                 │                 │                 │
     │                 │  aggregate()    │                 │
     │                 ├─────────────────────────────────►│
     │                 │  subscriptionStats                │
     │                 │◄─────────────────────────────────┤
     │                 │                 │                 │
     │                 │  calculateMRR() │                 │
     │                 │                 │                 │
     │  ◄──────────────┤  analytics      │                 │
     │                 │                 │                 │
     │  Display Data   │                 │                 │
     │                 │                 │                 │
```

### 3. User Activation Flow (with Audit Log)
```
┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐
│  Users   │  │  Super   │  │   User   │  │  Audit   │  │  Audit   │
│  Screen  │  │  Admin   │  │   Model  │  │  Helper  │  │   Log    │
│          │  │Controller│  │          │  │          │  │  Model   │
└────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘
     │            │            │            │            │
     │ toggle()   │            │            │            │
     ├───────────►│            │            │            │
     │            │ findUser() │            │            │
     │            ├───────────►│            │            │
     │            │◄───────────┤            │            │
     │            │            │            │            │
     │            │ update()   │            │            │
     │            ├───────────►│            │            │
     │            │◄───────────┤            │            │
     │            │            │            │            │
     │            │ logAction()│            │            │
     │            ├────────────────────────►│            │
     │            │            │            │ create()   │
     │            │            │            ├───────────►│
     │            │            │            │◄───────────┤
     │            │◄────────────────────────┤            │
     │◄───────────┤            │            │            │
     │            │            │            │            │
     │ Refresh    │            │            │            │
     │            │            │            │            │
```

## Security Architecture

### Authentication & Authorization Flow
```
┌─────────────────────────────────────────────────────────┐
│                  Request Flow                           │
└─────────────────────────────────────────────────────────┘

  Client Request
       │
       ▼
  ┌─────────────────┐
  │ Authorization   │
  │ Header Check    │
  └────────┬────────┘
           │
           ▼
  ┌─────────────────┐
  │ JWT Token       │
  │ Verification    │
  └────────┬────────┘
           │
           ▼
  ┌─────────────────┐
  │ Extract User    │
  │ Info (role)     │
  └────────┬────────┘
           │
           ▼
  ┌─────────────────┐
  │ Check Role      │
  │ = super_admin?  │
  └────────┬────────┘
           │
      ┌────┴────┐
      │         │
     Yes       No
      │         │
      ▼         ▼
  ┌────────┐ ┌────────┐
  │ Allow  │ │ 403    │
  │ Access │ │ Denied │
  └────────┘ └────────┘
```

### Audit Logging Flow
```
Every Admin Action
       │
       ▼
  ┌─────────────────┐
  │ Capture:        │
  │ - Admin ID      │
  │ - Admin Role    │
  │ - Action Type   │
  │ - Target User   │
  │ - IP Address    │
  │ - Timestamp     │
  │ - Details       │
  └────────┬────────┘
           │
           ▼
  ┌─────────────────┐
  │ Save to         │
  │ AuditLog        │
  │ Collection      │
  └────────┬────────┘
           │
           ▼
  ┌─────────────────┐
  │ Indexed for     │
  │ Fast Retrieval  │
  └─────────────────┘
```

## API Request/Response Examples

### Get Dashboard Analytics
```
Request:
GET /api/super-admin/analytics
Authorization: Bearer <token>

Response:
{
  "success": true,
  "data": {
    "usersByRole": {
      "shopkeeper": { "total": 150, "active": 120, "inactive": 30 },
      "customer": { "total": 5000, "active": 4500, "inactive": 500 },
      "ssa": { "total": 10, "active": 10, "inactive": 0 }
    },
    "totalShops": 150,
    "subscriptions": {
      "byStatus": {
        "active": { "count": 100, "revenue": 50000 },
        "inactive": { "count": 30, "revenue": 0 },
        "expired": { "count": 20, "revenue": 0 }
      },
      "mrr": 50000
    },
    "recentActivityCount": 45
  }
}
```

### Toggle User Status
```
Request:
PATCH /api/super-admin/users/507f1f77bcf86cd799439011/status
Authorization: Bearer <token>
Content-Type: application/json

{
  "isActive": false
}

Response:
{
  "success": true,
  "message": "User deactivated successfully",
  "data": {
    "userId": "507f1f77bcf86cd799439011",
    "isActive": false
  }
}

Audit Log Created:
{
  "adminId": "507f1f77bcf86cd799439012",
  "adminRole": "super_admin",
  "action": "user_deactivated",
  "targetUserId": "507f1f77bcf86cd799439011",
  "targetUserRole": "shopkeeper",
  "details": {
    "previousStatus": true,
    "newStatus": false
  },
  "ipAddress": "192.168.1.1",
  "createdAt": "2026-02-18T10:30:00.000Z"
}
```

## Performance Considerations

### Database Indexes
```
Users Collection:
- phone (unique) - Fast user lookup
- role + approvalStatus - Fast filtering

ShopkeeperProfile Collection:
- userId (unique) - Fast profile lookup

Subscription Collection:
- shopkeeperId - Fast subscription lookup
- status - Fast status filtering

AuditLog Collection:
- adminId + createdAt - Fast admin activity lookup
- targetUserId - Fast user history lookup
- action - Fast action filtering
```

### Pagination Strategy
```
Default: 20 items per page
Max: 100 items per page

Benefits:
- Reduced memory usage
- Faster response times
- Better user experience
- Scalable to millions of records
```

### Aggregation Pipelines
```
Analytics queries use MongoDB aggregation:
- $group for counting and summing
- $match for filtering
- $project for field selection
- Indexed fields for fast execution
```

## Scalability

### Horizontal Scaling
```
┌──────────┐     ┌──────────┐     ┌──────────┐
│  Server  │     │  Server  │     │  Server  │
│    1     │     │    2     │     │    3     │
└────┬─────┘     └────┬─────┘     └────┬─────┘
     │                │                │
     └────────────────┼────────────────┘
                      │
              ┌───────▼────────┐
              │  Load Balancer │
              └───────┬────────┘
                      │
              ┌───────▼────────┐
              │    MongoDB     │
              │  Replica Set   │
              └────────────────┘
```

### Caching Strategy (Future)
```
┌──────────┐
│  Redis   │  ← Cache analytics (5 min TTL)
│  Cache   │  ← Cache user lists (1 min TTL)
└────┬─────┘  ← Cache shop lists (1 min TTL)
     │
     ▼
┌──────────┐
│  Server  │
└────┬─────┘
     │
     ▼
┌──────────┐
│ MongoDB  │
└──────────┘
```

---

**This architecture provides:**
- ✅ Clean separation of concerns
- ✅ Scalable design
- ✅ Secure by default
- ✅ Comprehensive audit trail
- ✅ Fast performance
- ✅ Easy to maintain and extend
