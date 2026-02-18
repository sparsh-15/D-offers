# Super Admin Implementation Guide

## Overview
Complete Super Admin core control dashboard with full system visibility, role-based access control, and audit logging.

## Features Implemented

### 1. Backend Components

#### Models
- **Subscription.js** - Manages shop subscription data
  - Fields: shopkeeperId, planName, status, startDate, endDate, monthlyPrice, autoRenew
  - Statuses: active, inactive, expired, cancelled
  - Plans: basic, premium, enterprise

- **AuditLog.js** - Tracks all admin actions
  - Fields: adminId, adminRole, action, targetUserId, targetUserRole, details, ipAddress
  - Actions: user_activated, user_deactivated, user_approved, user_rejected, subscription_created, subscription_updated, subscription_cancelled, shop_approved, shop_rejected

#### Middleware
- **roleAuth.js** - Role-based access control
  - `requireRole(...roles)` - Check if user has any of the specified roles
  - `requireSuperAdmin()` - Strict super admin only access
  - `logAdminAction()` - Helper to log admin actions to audit log

#### Controllers
- **superAdminController.js** - All super admin operations
  - `getDashboardAnalytics()` - System overview with stats
  - `getAllUsers()` - List users with filters (role, status, approval, pincode, search)
  - `getAllShops()` - List shops with subscription data
  - `toggleUserStatus()` - Activate/deactivate users
  - `updateApprovalStatus()` - Approve/reject users
  - `getAuditLogs()` - View system activity logs
  - `getUserDetails()` - Detailed user information

#### Routes
- **superAdminRoutes.js** - All routes protected by auth + super admin middleware
  - `GET /api/super-admin/analytics` - Dashboard analytics
  - `GET /api/super-admin/users` - List all users
  - `GET /api/super-admin/users/:userId` - User details
  - `PATCH /api/super-admin/users/:userId/status` - Toggle user active status
  - `PATCH /api/super-admin/users/:userId/approval` - Update approval status
  - `GET /api/super-admin/shops` - List all shops
  - `GET /api/super-admin/audit-logs` - View audit logs

### 2. Frontend Components

#### Services
- **super_admin_service.dart** - API client for super admin operations
  - All CRUD operations for users, shops, and audit logs
  - Proper error handling and token management

#### Screens
- **super_admin_dashboard.dart** - Main dashboard
  - System overview with key metrics
  - Users by role breakdown
  - Subscription statistics
  - Quick action buttons
  - Real-time data refresh

- **users_management_screen.dart** - User management
  - List all users with pagination
  - Filter by role, status, approval status, pincode
  - Search by name or phone
  - Toggle user active/inactive status
  - Approve/reject pending users
  - Visual status indicators

- **shops_management_screen.dart** - Shop management
  - List all shops with subscription data
  - Filter by subscription status, pincode, category
  - Search by shop name
  - View subscription details
  - Pagination support

- **audit_logs_screen.dart** - Activity logs
  - View all admin actions
  - Filter by action type
  - See admin and target user details
  - Timestamp and action icons
  - Pagination support

## Security Features

### 1. Backend Security
- **Strict Role Validation**: All routes validate role on backend, not frontend
- **Token-based Authentication**: JWT tokens required for all requests
- **Audit Logging**: All admin actions are logged with IP address
- **Self-protection**: Super admin cannot deactivate their own account
- **Input Validation**: All inputs validated before processing

### 2. Frontend Security
- **Token Management**: Secure token storage and transmission
- **Error Handling**: Proper error messages without exposing sensitive data
- **Role-based UI**: UI elements shown/hidden based on user role

## Analytics & Reporting

### Dashboard Metrics
1. **Total Users** - Count of all users in system
2. **Total Shops** - Count of registered shops
3. **MRR (Monthly Recurring Revenue)** - Sum of active subscription prices
4. **Recent Activity** - Count of actions in last 7 days

### User Analytics
- Users by role (total, active, inactive)
- Approval status breakdown
- Geographic distribution (by pincode)

### Subscription Analytics
- Subscriptions by status (active, inactive, expired, cancelled)
- Revenue by status
- Total MRR calculation

## Search & Filter Capabilities

### User Filters
- **Role**: Filter by user role (super_admin, subadmin, company_sales_agent, ssa, shopkeeper, customer)
- **Status**: Active/Inactive
- **Approval Status**: Pending/Approved/Rejected
- **Pincode**: Filter by location
- **Search**: Name or phone number

### Shop Filters
- **Subscription Status**: Active/Inactive/Expired/Cancelled
- **Pincode**: Filter by location
- **City**: Filter by city
- **Category**: Filter by shop category
- **Search**: Shop name

### Audit Log Filters
- **Action Type**: Filter by specific action
- **Admin**: Filter by admin who performed action
- **Target User**: Filter by affected user
- **Date Range**: Filter by time period

## API Endpoints

### Analytics
```
GET /api/super-admin/analytics
Response: {
  usersByRole: { role: { total, active, inactive } },
  totalShops: number,
  subscriptions: {
    byStatus: { status: { count, revenue } },
    mrr: number
  },
  recentActivityCount: number
}
```

### User Management
```
GET /api/super-admin/users?role=&isActive=&approvalStatus=&pincode=&search=&page=&limit=
Response: {
  users: [...],
  pagination: { total, page, limit, pages }
}

GET /api/super-admin/users/:userId
Response: {
  user: {...},
  profile: {...},
  subscription: {...},
  recentLogs: [...]
}

PATCH /api/super-admin/users/:userId/status
Body: { isActive: boolean }

PATCH /api/super-admin/users/:userId/approval
Body: { approvalStatus: 'pending' | 'approved' | 'rejected' }
```

### Shop Management
```
GET /api/super-admin/shops?subscriptionStatus=&pincode=&city=&category=&search=&page=&limit=
Response: {
  shops: [...],
  pagination: { total, page, limit, pages }
}
```

### Audit Logs
```
GET /api/super-admin/audit-logs?action=&adminId=&targetUserId=&startDate=&endDate=&page=&limit=
Response: {
  logs: [...],
  pagination: { total, page, limit, pages }
}
```

## Installation & Setup

### Backend Setup
1. Models are automatically loaded by Mongoose
2. Routes are registered in `server/src/routes/index.js`
3. No additional configuration needed

### Frontend Setup
1. Install dependencies:
   ```bash
   cd client
   flutter pub get
   ```

2. Import super admin dashboard in your main app routing:
   ```dart
   import 'package:client/screens/super_admin/super_admin_dashboard.dart';
   ```

3. Add route based on user role:
   ```dart
   if (userRole == 'super_admin') {
     Navigator.pushReplacement(
       context,
       MaterialPageRoute(
         builder: (context) => const SuperAdminDashboard(),
       ),
     );
   }
   ```

## Usage Examples

### Activating a User
1. Navigate to Users Management
2. Find the user in the list
3. Toggle the switch to activate/deactivate
4. Action is logged in audit logs

### Approving a Shopkeeper
1. Navigate to Users Management
2. Filter by role: "Shopkeeper" and status: "Pending"
3. Click "Approve" or "Reject" button
4. Action is logged with admin details

### Viewing System Activity
1. Navigate to Audit Logs
2. Filter by action type if needed
3. View admin, target user, and timestamp
4. Use pagination to browse history

## Testing

### Test Super Admin Access
1. Create a user with role 'super_admin'
2. Login with super admin credentials
3. Access `/api/super-admin/analytics`
4. Should return dashboard data

### Test Role Protection
1. Login as non-super admin user
2. Try to access `/api/super-admin/analytics`
3. Should return 403 Forbidden

### Test Audit Logging
1. Perform any admin action (activate user, approve shopkeeper)
2. Check audit logs
3. Should see entry with admin details, action, and timestamp

## Future Enhancements

### Phase 2 (Suggested)
- Export audit logs to CSV/PDF
- Advanced analytics dashboard with charts
- Bulk user operations
- Email notifications for admin actions
- Subscription management (create, update, cancel)
- Revenue reports and forecasting
- User activity tracking
- System health monitoring

### Phase 3 (Suggested)
- AI-powered insights and recommendations
- Automated fraud detection
- Predictive analytics for subscriptions
- Custom report builder
- Real-time notifications
- Advanced search with Elasticsearch
- Data visualization with charts

## Dependencies Added

### Backend
- No new dependencies (uses existing Mongoose, JWT, Express)

### Frontend
- `cached_network_image: ^3.3.1` - For better image loading
- `intl: ^0.19.0` - For date formatting

## Files Created

### Backend (7 files)
1. `server/src/models/Subscription.js`
2. `server/src/models/AuditLog.js`
3. `server/src/middleware/roleAuth.js`
4. `server/src/controllers/superAdminController.js`
5. `server/src/routes/superAdminRoutes.js`
6. `server/src/routes/index.js` (updated)

### Frontend (4 files)
1. `client/lib/services/super_admin_service.dart`
2. `client/lib/screens/super_admin/super_admin_dashboard.dart`
3. `client/lib/screens/super_admin/users_management_screen.dart`
4. `client/lib/screens/super_admin/shops_management_screen.dart`
5. `client/lib/screens/super_admin/audit_logs_screen.dart`
6. `client/pubspec.yaml` (updated)

## Compliance & Best Practices

✅ **Backend Role Validation** - All routes check role on server
✅ **Audit Logging** - All admin actions are logged
✅ **Input Validation** - All inputs validated
✅ **Error Handling** - Proper error messages
✅ **Pagination** - All lists support pagination
✅ **Search & Filter** - Comprehensive filtering options
✅ **Security** - Token-based auth, role-based access
✅ **Scalability** - Indexed database queries
✅ **Documentation** - Complete API documentation

## Support

For issues or questions:
1. Check audit logs for error details
2. Verify user has 'super_admin' role
3. Check JWT token is valid
4. Ensure all dependencies are installed
5. Review server logs for backend errors

---

**Status**: ✅ Complete and Production Ready
**Version**: 1.0.0
**Last Updated**: 2026-02-18
