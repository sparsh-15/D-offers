const { resolveCityStateFromPincode } = require('../services/pincodeService');

async function pincodeLookup(req, res, next) {
  try {
    const { pincode } = req.params;
    const result = await resolveCityStateFromPincode(pincode);
    res.status(200).json({ success: true, ...result });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  pincodeLookup,
};

