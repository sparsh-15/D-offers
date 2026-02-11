const express = require('express');
const metaController = require('../controllers/metaController');

const router = express.Router();

router.get('/pincode/:pincode', metaController.pincodeLookup);

module.exports = router;

