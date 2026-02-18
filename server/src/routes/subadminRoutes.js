const express = require('express');
const authMiddleware = require('../middleware/auth');
const { requireRole } = require('../middleware/roleCheck');

const router = express.Router();

// Subadmin routes - similar to admin but with limited permissions
router.use(authMiddleware);
router.use(requireRole('subadmin'));

// Subadmin can view stats but not modify critical settings
router.get('/stats', async (req, res, next) => {
  try {
    // TODO: Implement subadmin stats (same as admin but read-only)
    res.status(200).json({
      success: true,
      stats: {
        totalUsers: 0,
        totalShopkeepers: 0,
        activeOffers: 0,
        pendingApprovals: 0,
      },
    });
  } catch (err) {
    next(err);
  }
});

// Subadmin can view users but not delete
router.get('/users', async (req, res, next) => {
  try {
    // TODO: Implement user list for subadmin
    res.status(200).json({
      success: true,
      users: [],
    });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
