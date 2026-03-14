const express = require('express');
const router = express.Router();
const { getAllCategories } = require('../config/businessCategories');
const { resolveCityStateFromPincode } = require('../services/pincodeService');
const { prisma } = require('../db/prisma');

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

// Distinct states from active approved customers
router.get('/states', async (req, res, next) => {
  try {
    const rows = await prisma.user.findMany({
      where: {
        role: 'customer',
        isActive: true,
        approvalStatus: 'approved',
        state: { not: '' },
      },
      select: { state: true },
      distinct: ['state'],
      orderBy: { state: 'asc' },
    });

    const seen = new Set();
    const states = [];
    for (const row of rows) {
      const value = String(row.state || '').trim();
      if (!value) continue;
      const key = value.toLowerCase();
      if (seen.has(key)) continue;
      seen.add(key);
      states.push(value);
    }

    res.json({ success: true, data: { states } });
  } catch (err) {
    next(err);
  }
});

// Distinct cities from active approved customers filtered by state
router.get('/states/:state/cities', async (req, res, next) => {
  try {
    const state = String(req.params.state || '').trim();
    if (!state) {
      return res.status(400).json({
        success: false,
        message: 'State is required',
      });
    }

    const rows = await prisma.user.findMany({
      where: {
        role: 'customer',
        isActive: true,
        approvalStatus: 'approved',
        state: { equals: state, mode: 'insensitive' },
        city: { not: '' },
      },
      select: { city: true },
      distinct: ['city'],
      orderBy: { city: 'asc' },
    });

    const seen = new Set();
    const cities = [];
    for (const row of rows) {
      const value = String(row.city || '').trim();
      if (!value) continue;
      const key = value.toLowerCase();
      if (seen.has(key)) continue;
      seen.add(key);
      cities.push(value);
    }

    res.json({ success: true, data: { state, cities } });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
