require('dotenv').config();

const mongoose = require('mongoose');
const config = require('../src/config');
const User = require('../src/models/User');
const { resolveCityStateFromPincode } = require('../src/services/pincodeService');

async function main() {
  const phone = process.env.ADMIN_PHONE;
  const name = process.env.ADMIN_NAME || 'Admin';
  const pincode = process.env.ADMIN_PINCODE;
  const address = process.env.ADMIN_ADDRESS || '';

  if (!phone) throw new Error('ADMIN_PHONE is required');
  if (!pincode) throw new Error('ADMIN_PINCODE is required');

  const { city, state } = await resolveCityStateFromPincode(pincode);

  await mongoose.connect(config.mongodbUri);

  const user = await User.findOneAndUpdate(
    { phone },
    {
      phone,
      role: 'admin',
      name,
      pincode: String(pincode).trim(),
      city,
      state,
      address,
      approvalStatus: 'approved',
    },
    { upsert: true, new: true, runValidators: true }
  );

  console.log('Seeded admin:', { id: user._id.toString(), phone: user.phone, name: user.name });
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });

