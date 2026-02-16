# Cloudinary Setup Instructions

## Prerequisites
1. Create a Cloudinary account at https://cloudinary.com/
2. Get your Cloud Name, API Key, and API Secret from the dashboard

## Environment Variables

Add the following to your `.env` file:

```env
CLOUDINARY_CLOUD_NAME=your_cloud_name_here
CLOUDINARY_API_KEY=492165161531146
CLOUDINARY_API_SECRET=KEhBXvr3pFUMwV6WtPCCsWs9znI
```

**Note:** Replace `your_cloud_name_here` with your actual Cloudinary cloud name.

## Installation

Run the following command to install required packages:

```bash
npm install
```

This will install:
- `cloudinary` - Cloudinary SDK for Node.js
- `multer` - Middleware for handling multipart/form-data (file uploads)

## API Endpoints

### Upload Single Image
- **POST** `/api/upload/image`
- **Headers:** `Authorization: Bearer <token>`
- **Body:** `multipart/form-data` with field name `image`
- **Response:**
  ```json
  {
    "success": true,
    "url": "https://res.cloudinary.com/...",
    "publicId": "d-offers/offer-images/..."
  }
  ```

### Upload Multiple Images
- **POST** `/api/upload/images`
- **Headers:** `Authorization: Bearer <token>`
- **Body:** `multipart/form-data` with field name `images` (multiple files)
- **Response:**
  ```json
  {
    "success": true,
    "images": [
      {
        "url": "https://res.cloudinary.com/...",
        "publicId": "d-offers/offer-images/..."
      }
    ]
  }
  ```

### Delete Image
- **DELETE** `/api/upload/image`
- **Headers:** `Authorization: Bearer <token>`
- **Body:**
  ```json
  {
    "publicId": "d-offers/offer-images/..."
  }
  ```

## Features

- **Automatic Image Optimization:** Images are automatically optimized for web
- **Size Limits:** Maximum 10MB per file
- **Supported Formats:** JPEG, JPG, PNG, GIF, WEBP
- **Automatic Resizing:** Images are limited to 1920x1080 pixels
- **Quality Optimization:** Auto quality setting for best balance
- **Secure Storage:** Images stored in `d-offers/offer-images` folder
- **Authentication Required:** Only authenticated shopkeepers and admins can upload

## Security

- All upload endpoints require authentication
- Only shopkeepers and admins can upload images
- File type validation (only images allowed)
- File size validation (max 10MB)
- Temporary files are stored in `server/uploads/` and cleaned up after upload

## Folder Structure

```
server/
├── src/
│   ├── config/
│   │   └── cloudinary.js          # Cloudinary configuration
│   ├── controllers/
│   │   └── uploadController.js    # Upload logic
│   ├── middleware/
│   │   └── upload.js              # Multer configuration
│   └── routes/
│       └── uploadRoutes.js        # Upload routes
└── uploads/                       # Temporary upload folder (gitignored)
```

## Testing

You can test the upload functionality using tools like Postman or curl:

```bash
curl -X POST http://localhost:3000/api/upload/image \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "image=@/path/to/your/image.jpg"
```

## Troubleshooting

1. **"No file uploaded" error:** Make sure the field name is `image` for single upload or `images` for multiple
2. **"Only image files are allowed" error:** Check that you're uploading a valid image format
3. **"Failed to upload" error:** Verify your Cloudinary credentials in `.env`
4. **Authentication errors:** Ensure you're sending a valid JWT token in the Authorization header
