/**
 * Script to create a Super Admin user
 * Usage: node scripts/create-super-admin.js <phone> <name>
 * Example: node scripts/create-super-admin.js 9876543210 "Admin User"
 */

require('dotenv').config();
const mongoose = require('mongoose');
const User = require('../src/models/User');
const config = require('../src/config');

async function createSuperAdmin() {
  try {
    // Get phone and name from command line arguments
    const phone = process.argv[2];
    const name = process.argv[3] || 'Super Admin';

    if (!phone) {
      console.error('❌ Error: Phone number is required');
      console.log('Usage: node scripts/create-super-admin.js <phone> <name>');
      console.log('Example: node scripts/create-super-admin.js 9876543210 "Admin User"');
      process.exit(1);
    }

    // Validate phone number (basic validation)
    if (!/^\d{10}$/.test(phone)) {
      console.error('❌ Error: Phone number must be 10 digits');
      process.exit(1);
    }

    // Connect to MongoDB
    console.log('📡 Connecting to MongoDB...');
    await mongoose.connect(config.mongodbUri);
    console.log('✅ Connected to MongoDB');

    // Check if user already exists
    const existingUser = await User.findOne({ phone });
    if (existingUser) {
      if (existingUser.role === 'super_admin') {
        console.log('ℹ️  Super Admin with this phone already exists');
        console.log('User Details:');
        console.log(`  - ID: ${existingUser._id}`);
        console.log(`  - Name: ${existingUser.name}`);
        console.log(`  - Phone: ${existingUser.phone}`);
        console.log(`  - Role: ${existingUser.role}`);
        console.log(`  - Active: ${existingUser.isActive}`);
        console.log(`  - Created: ${existingUser.createdAt}`);
      } else {
        console.log('⚠️  User exists with different role. Updating to super_admin...');
        existingUser.role = 'super_admin';
        existingUser.name = name;
        existingUser.isActive = true;
        existingUser.approvalStatus = 'approved';
        await existingUser.save();
        console.log('✅ User updated to Super Admin');
        console.log('User Details:');
        console.log(`  - ID: ${existingUser._id}`);
        console.log(`  - Name: ${existingUser.name}`);
        console.log(`  - Phone: ${existingUser.phone}`);
        console.log(`  - Role: ${existingUser.role}`);
      }
    } else {
      // Create new super admin user
      console.log('👤 Creating new Super Admin user...');
      const superAdmin = await User.create({
        phone,
        name,
        role: 'super_admin',
        isActive: true,
        approvalStatus: 'approved',
        permissions: ['all'],
      });

      console.log('✅ Super Admin created successfully!');
      console.log('User Details:');
      console.log(`  - ID: ${superAdmin._id}`);
      console.log(`  - Name: ${superAdmin.name}`);
      console.log(`  - Phone: ${superAdmin.phone}`);
      console.log(`  - Role: ${superAdmin.role}`);
      console.log(`  - Active: ${superAdmin.isActive}`);
      console.log(`  - Created: ${superAdmin.createdAt}`);
    }

    console.log('\n📱 Next Steps:');
    console.log('1. Use the phone number to login via OTP');
    console.log('2. Access Super Admin dashboard');
    console.log('3. Start managing users and shops');

  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  } finally {
    await mongoose.connection.close();
    console.log('\n👋 Disconnected from MongoDB');
    process.exit(0);
  }
}

// Run the script
createSuperAdmin();
