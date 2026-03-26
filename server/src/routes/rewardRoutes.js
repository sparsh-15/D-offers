const express = require('express');
const authMiddleware = require('../middleware/auth');
const { requireRole } = require('../middleware/roleCheck');
const rewardController = require('../controllers/rewardController');

const router = express.Router();

router.use(authMiddleware);

router.post('/customer/like', requireRole('customer'), rewardController.awardCustomerLike);
router.post('/customer/unlike', requireRole('customer'), rewardController.reverseCustomerUnlike);
router.post('/customer/purchase-success', requireRole('customer'), rewardController.awardCustomerPurchase);

router.post('/shopkeeper/sale-closed', requireRole('shopkeeper'), rewardController.awardShopkeeperSale);
router.post('/shopkeeper/install-verified', requireRole('shopkeeper'), rewardController.awardShopkeeperInstall);
router.get('/shopkeeper/milestones/me', requireRole('shopkeeper'), rewardController.getMyMilestones);
router.post('/shopkeeper/milestones/:milestoneId/redeem', requireRole('shopkeeper'), rewardController.redeemMilestone);

router.get('/wallet/me', requireRole(['customer', 'shopkeeper']), rewardController.getMyWallet);
router.get('/wallet/me/ledger', requireRole(['customer', 'shopkeeper']), rewardController.getMyLedger);
router.get('/wallet/me/expiry-summary', requireRole(['customer', 'shopkeeper']), rewardController.getMyExpirySummary);

router.post('/admin/reversal', requireRole(['super_admin', 'subadmin']), rewardController.reverseReward);
router.get('/admin/metrics', requireRole(['super_admin', 'subadmin']), rewardController.getAdminMetrics);
router.get('/admin/config', requireRole(['super_admin', 'subadmin']), rewardController.listRewardConfig);
router.put('/admin/config/:key', requireRole(['super_admin', 'subadmin']), rewardController.updateRewardConfig);

module.exports = router;
