require('dotenv').config();

const ROLES = ['shopkeeper', 'customer', 'admin'];

module.exports = {
  port: process.env.PORT || 3000,
  mongodbUri: process.env.MONGODB_URI || 'mongodb://localhost:27017/doffers',
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
  isDev: process.env.NODE_ENV !== 'production',
  ROLES,
};
