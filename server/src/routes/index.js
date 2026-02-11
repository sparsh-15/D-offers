const express = require('express');
const authRoutes = require('./authRoutes');
const customerRoutes = require('./customerRoutes');
const offerRoutes = require('./offerRoutes');
const shopkeeperRoutes = require('./shopkeeperRoutes');
const metaRoutes = require('./metaRoutes');
const adminRoutes = require('./adminRoutes');

const router = express.Router();

router.use('/auth', authRoutes);
router.use('/customer', customerRoutes);
router.use('/offers', offerRoutes);
router.use('/shopkeeper', shopkeeperRoutes);
router.use('/meta', metaRoutes);
router.use('/admin', adminRoutes);

module.exports = router;
