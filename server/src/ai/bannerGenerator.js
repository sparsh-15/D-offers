const { GoogleGenerativeAI } = require('@google/generative-ai');
const cloudinary = require('../config/cloudinary');

// Use a valid Gemini image model; allow override via env
const IMAGE_MODEL_NAME =
  process.env.GEMINI_IMAGE_MODEL || 'gemini-2.5-flash-image';

let imageModel;

function getImageModel() {
  if (!process.env.GEMINI_API_KEY) {
    throw new Error('GEMINI_API_KEY is not configured in environment');
  }
  if (!imageModel) {
    const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
    imageModel = genAI.getGenerativeModel({ model: IMAGE_MODEL_NAME });
  }
  return imageModel;
}

function buildBannerPrompt({
  title,
  description,
  category,
  discountType,
  discountValue,
  shopName,
  shopLocation,
}) {
  const discountLabel =
    discountType === 'percentage' && discountValue != null
      ? `${discountValue}% OFF`
      : discountType === 'fixed' && discountValue != null
        ? `₹${discountValue} OFF`
        : 'Special Offer';

  return [
    "Design a mobile-friendly promotional banner image for a hyperlocal Indian retail shop.",
    'Requirements:',
    '- Horizontal aspect ratio suitable for a 1080x540 px display.',
    '- High contrast, bold typography, very readable on small phones.',
    '- Prominently display the main discount text.',
    '- Keep background clean and modern, no small unreadable text.',
    '- Avoid any text that looks like UI buttons.',
    '',
    `Shop name: ${shopName || 'Local Shop'}`,
    shopLocation ? `Location: ${shopLocation}` : '',
    `Offer title: ${title || 'Limited time offer'}`,
    `Discount: ${discountLabel}`,
    category ? `Category: ${category}` : '',
    description ? `Details: ${description}` : '',
    '',
    'Return only the image, no additional text.',
  ]
    .filter(Boolean)
    .join('\n');
}

async function generateBannerImageUrl(params) {
  const model = getImageModel();
  const prompt = buildBannerPrompt(params);

  console.log('[AI_BANNER] Generating banner with prompt snippet:', prompt.slice(0, 160));

  const result = await model.generateContent([prompt]);

  const part =
    result?.response?.candidates?.[0]?.content?.parts?.find(
      (p) => p.inlineData && p.inlineData.data,
    ) || result?.response?.candidates?.[0]?.content?.parts?.[0];

  if (!part || !part.inlineData || !part.inlineData.data) {
    throw new Error('Image generation failed: no image data returned from Gemini.');
  }

  const buffer = Buffer.from(part.inlineData.data, 'base64');

  const uploadResult = await new Promise((resolve, reject) => {
    const stream = cloudinary.uploader.upload_stream(
      {
        folder: 'doffers/ai-banners',
        resource_type: 'image',
        format: 'png',
      },
      (err, resultData) => {
        if (err) return reject(err);
        resolve(resultData);
      },
    );
    stream.end(buffer);
  });

  const imageUrl = uploadResult.secure_url || uploadResult.url;

  return {
    imageUrl,
    altText: `${params.title || 'Offer'} banner for ${params.shopName || 'Local Shop'}`,
    promptUsed: prompt,
  };
}

module.exports = {
  generateBannerImageUrl,
};

