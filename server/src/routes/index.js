const express = require('express');
const authRoutes = require('./authRoutes');
const customerRoutes = require('./customerRoutes');
const offerRoutes = require('./offerRoutes');
const shopkeeperRoutes = require('./shopkeeperRoutes');
const metaRoutes = require('./metaRoutes');
const adminRoutes = require('./adminRoutes');
const uploadRoutes = require('./uploadRoutes');
const onboardingRoutes = require('./onboardingRoutes');
const subscriptionRoutes = require('./subscriptionRoutes');
const ssaRoutes = require('./ssaRoutes');
const companySalesRoutes = require('./companySalesRoutes');
const subadminRoutes = require('./subadminRoutes');
const superAdminRoutes = require('./superAdminRoutes');
const subscriptionGovernanceRoutes = require('./subscriptionGovernanceRoutes');
const agentGovernanceRoutes = require('./agentGovernanceRoutes');
const aiRoutes = require('./aiRoutes');

const router = express.Router();

router.use('/auth', authRoutes);
router.use('/customer', customerRoutes);
router.use('/offers', offerRoutes);
router.use('/shopkeeper', shopkeeperRoutes);
router.use('/meta', metaRoutes);
router.use('/admin', adminRoutes);
router.use('/upload', uploadRoutes);
router.use('/onboarding', onboardingRoutes);
router.use('/subscription', subscriptionRoutes);
router.use('/ssa', ssaRoutes);
router.use('/company-sales', companySalesRoutes);
router.use('/subadmin', subadminRoutes);
router.use('/super-admin', superAdminRoutes);
router.use('/subscription-governance', subscriptionGovernanceRoutes);
router.use('/agent-governance', agentGovernanceRoutes);
router.use('/ai', aiRoutes);

module.exports = router;
