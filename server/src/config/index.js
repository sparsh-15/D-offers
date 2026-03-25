require('dotenv').config();

const ROLES = [
  'super_admin',
  'subadmin',
  'company_sales_agent',
  'ssa', // Sales Service Agent
  'shopkeeper',
  'customer'
];

module.exports = {
  port: process.env.PORT || 3000,
  dbProvider: 'postgres',
  dbReadProvider: 'postgres',
  databaseUrl: process.env.DATABASE_URL || '',
  pgbouncerUrl: process.env.PGBOUNCER_URL || '',
  adminSeed: {
    enabled: process.env.ADMIN_SEED_ENABLED !== 'false',
    phone: process.env.ADMIN_PHONE || '',
    name: process.env.ADMIN_NAME || 'Admin',
    pincode: process.env.ADMIN_PINCODE || '',
    address: process.env.ADMIN_ADDRESS || '',
    role: process.env.ADMIN_ROLE || 'super_admin',
  },
  jwt: {
    secret: process.env.JWT_SECRET || 'dev-secret-change-in-production',
    expiry: process.env.JWT_EXPIRY || '7d',
  },
  otp: {
    masterOtp: process.env.MASTER_OTP || '999999',
    expiryMinutes: parseInt(process.env.OTP_EXPIRY_MINUTES, 10) || 10,
    sendViaSms: process.env.SEND_OTP_VIA_SMS === 'true',
  },
  sms: {
    provider: process.env.SMS_PROVIDER || 'twilio',
    twilio: {
      accountSid: process.env.TWILIO_ACCOUNT_SID,
      authToken: process.env.TWILIO_AUTH_TOKEN,
      phoneNumber: process.env.TWILIO_PHONE_NUMBER,
    },
  },
  rewards: {
    expiryIntervalMs: parseInt(process.env.REWARD_EXPIRY_INTERVAL_MS, 10) || 10 * 60 * 1000,
    reconciliationIntervalMs: parseInt(process.env.REWARD_RECONCILIATION_INTERVAL_MS, 10) || 30 * 60 * 1000,
    startupDelayMs: parseInt(process.env.REWARD_MAINTENANCE_STARTUP_DELAY_MS, 10) || 15 * 1000,
  },
  isDev: process.env.NODE_ENV !== 'production',
  ROLES,
};
