const mongoose = require('mongoose');
const User = require('../models/User');
const Offer = require('../models/Offer');

async function getStats(req, res, next) {
  try {
    const totalUsers = await User.countDocuments();
    const totalShopkeepers = await User.countDocuments({ role: 'shopkeeper' });
    const pendingShopkeepers = await User.countDocuments({ role: 'shopkeeper', approvalStatus: 'pending' });
    const activeOffers = await Offer.countDocuments({ status: 'active' });

    res.status(200).json({
      success: true,
      stats: {
        totalUsers,
        totalShopkeepers,
        pendingShopkeepers,
        activeOffers,
      },
    });
  } catch (err) {
    next(err);
  }
}

async function listUsers(req, res, next) {
  try {
    const { role, limit, skip } = req.query;
    const filter = {};
    if (role) filter.role = role;

    const limitNum = Math.min(Math.max(parseInt(limit, 10) || 20, 1), 100);
    const skipNum = Math.max(parseInt(skip, 10) || 0, 0);

    const users = await User.find(filter)
      .select('name phone role pincode city state approvalStatus createdAt')
      .sort({ createdAt: -1 })
      .skip(skipNum)
      .limit(limitNum)
      .lean();

    res.status(200).json({
      success: true,
      users: users.map((u) => ({
        id: u._id,
        name: u.name,
        phone: u.phone,
        role: u.role,
        pincode: u.pincode,
        city: u.city,
        state: u.state,
        approvalStatus: u.approvalStatus,
        createdAt: u.createdAt,
      })),
    });
  } catch (err) {
    next(err);
  }
}

async function listShopkeepers(req, res, next) {
  try {
    const { status } = req.query; // pending|approved|rejected
    const filter = { role: 'shopkeeper' };
    if (status) filter.approvalStatus = status;

    const users = await User.find(filter)
      .select('name phone pincode city state address approvalStatus createdAt updatedAt')
      .sort({ createdAt: -1 })
      .lean();

    res.status(200).json({
      success: true,
      shopkeepers: users.map((u) => ({
        id: u._id,
        name: u.name,
        phone: u.phone,
        pincode: u.pincode,
        city: u.city,
        state: u.state,
        address: u.address,
        approvalStatus: u.approvalStatus,
        createdAt: u.createdAt,
        updatedAt: u.updatedAt,
      })),
    });
  } catch (err) {
    next(err);
  }
}

async function approveShopkeeper(req, res, next) {
  try {
    const { id } = req.params;
    if (!mongoose.Types.ObjectId.isValid(id)) {
      const err = new Error('Invalid user id');
      err.statusCode = 400;
      return next(err);
    }

    const user = await User.findOne({ _id: id, role: 'shopkeeper' });
    if (!user) {
      const err = new Error('Shopkeeper not found');
      err.statusCode = 404;
      return next(err);
    }

    user.approvalStatus = 'approved';
    await user.save();

    res.status(200).json({
      success: true,
      message: 'Shopkeeper approved',
      shopkeeper: { id: user._id, phone: user.phone, approvalStatus: user.approvalStatus },
    });
  } catch (err) {
    next(err);
  }
}

async function rejectShopkeeper(req, res, next) {
  try {
    const { id } = req.params;
    if (!mongoose.Types.ObjectId.isValid(id)) {
      const err = new Error('Invalid user id');
      err.statusCode = 400;
      return next(err);
    }

    const user = await User.findOne({ _id: id, role: 'shopkeeper' });
    if (!user) {
      const err = new Error('Shopkeeper not found');
      err.statusCode = 404;
      return next(err);
    }

    user.approvalStatus = 'rejected';
    await user.save();

    res.status(200).json({
      success: true,
      message: 'Shopkeeper rejected',
      shopkeeper: { id: user._id, phone: user.phone, approvalStatus: user.approvalStatus },
    });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  getStats,
  listUsers,
  listShopkeepers,
  approveShopkeeper,
  rejectShopkeeper,
};

