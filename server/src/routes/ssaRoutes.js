const express = require('express');
const authMiddleware = require('../middleware/auth');
const { requireRole } = require('../middleware/roleCheck');

const router = express.Router();

// Sales Service Agent routes
router.use(authMiddleware);
router.use(requireRole('ssa'));

// SSA Dashboard stats
router.get('/stats', async (req, res, next) => {
  try {
    // TODO: Implement SSA-specific stats
    res.status(200).json({
      success: true,
      stats: {
        assignedShopkeepers: 0,
        activeLeads: 0,
        conversions: 0,
        commission: 0,
      },
    });
  } catch (err) {
    next(err);
  }
});

// Get assigned shopkeepers
router.get('/shopkeepers', async (req, res, next) => {
  try {
    // TODO: Implement assigned shopkeepers list
    res.status(200).json({
      success: true,
      shopkeepers: [],
    });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
