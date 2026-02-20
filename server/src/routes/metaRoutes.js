const express = require('express');
const router = express.Router();
const { getAllCategories } = require('../config/businessCategories');
const { resolveCityStateFromPincode } = require('../services/pincodeService');

// Get all business categories (public endpoint)
router.get('/categories', (req, res) => {
  try {
    const categories = getAllCategories();
    res.json({
      success: true,
      data: categories,
    });
  } catch (err) {
    console.error('[META] getCategories error:', err);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch categories',
    });
  }
});

// Pincode lookup (existing endpoint)
router.get('/pincode/:pincode', async (req, res, next) => {
  try {
    const { pincode } = req.params;
    const result = await resolveCityStateFromPincode(pincode);
    res.json({
      success: true,
      data: result,
    });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
