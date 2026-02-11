const mongoose = require('mongoose');
const User = require('../models/User');

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
  listShopkeepers,
  approveShopkeeper,
  rejectShopkeeper,
};

