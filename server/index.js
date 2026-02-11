require('dotenv').config();
const mongoose = require('mongoose');
const config = require('./src/config');
const app = require('./src/app');

mongoose
  .connect(config.mongodbUri)
  .then(() => {
    console.log('MongoDB connected');
    app.listen(config.port, () => {
      console.log(`Server running on port ${config.port}`);
    });
  })
  .catch((err) => {
    console.error('MongoDB connection error:', err);
    process.exit(1);
  });
