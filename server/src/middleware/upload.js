const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Create uploads directory if it doesn't exist
const uploadDir = path.join(__dirname, '../../uploads');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

// Configure multer storage
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, uploadDir);
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
    cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname));
  },
});

// File filter to accept images and PDF documents
const fileFilter = (req, file, cb) => {
  console.log('[UPLOAD] File received:', {
    originalname: file.originalname,
    mimetype: file.mimetype,
    fieldname: file.fieldname
  });

  // Check supported mime types
  const isImageMimetype = file.mimetype && file.mimetype.startsWith('image/');
  const isPdfMimetype = file.mimetype === 'application/pdf';
  
  // Check file extension
  const allowedExtensions = /\.(jpeg|jpg|png|gif|webp|pdf)$/i;
  const hasValidExtension = allowedExtensions.test(file.originalname.toLowerCase());

  // Accept if mime type is supported OR extension is supported
  if (isImageMimetype || isPdfMimetype || hasValidExtension) {
    console.log('[UPLOAD] File accepted');
    return cb(null, true);
  } else {
    console.log('[UPLOAD] File rejected - Invalid type');
    cb(new Error(`Only image or PDF files are allowed. Received: ${file.mimetype}`));
  }
};

// Configure multer
const upload = multer({
  storage: storage,
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB max file size
  },
  fileFilter: fileFilter,
});

module.exports = upload;
