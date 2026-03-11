// const { GoogleGenerativeAI } = require('@google/generative-ai');
// const cloudinary = require('../config/cloudinary');

// // Use a valid Gemini image model; allow override via env
// const IMAGE_MODEL_NAME =
//   process.env.GEMINI_IMAGE_MODEL || 'gemini-2.5-flash-image';

// let imageModel;

// function getImageModel() {
//   if (!process.env.GEMINI_API_KEY) {
//     throw new Error('GEMINI_API_KEY is not configured in environment');
//   }
//   if (!imageModel) {
//     const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
//     imageModel = genAI.getGenerativeModel({ model: IMAGE_MODEL_NAME });
//   }
//   return imageModel;
// }

// function buildBannerPrompt({
//   title,
//   description,
//   category,
//   discountType,
//   discountValue,
//   shopName,
//   shopLocation,
// }) {
//   const discountLabel =
//     discountType === 'percentage' && discountValue != null
//       ? `${discountValue}% OFF`
//       : discountType === 'fixed' && discountValue != null
//         ? `₹${discountValue} OFF`
//         : 'Special Offer';

//   return [
//     "Design a mobile-friendly promotional banner image for a hyperlocal Indian retail shop.",
//     'Requirements:',
//     '- Horizontal aspect ratio suitable for a 1080x540 px display.',
//     '- High contrast, bold typography, very readable on small phones.',
//     '- Prominently display the main discount text.',
//     '- Keep background clean and modern, no small unreadable text.',
//     '- Avoid any text that looks like UI buttons.',
//     '',
//     `Shop name: ${shopName || 'Local Shop'}`,
//     shopLocation ? `Location: ${shopLocation}` : '',
//     `Offer title: ${title || 'Limited time offer'}`,
//     `Discount: ${discountLabel}`,
//     category ? `Category: ${category}` : '',
//     description ? `Details: ${description}` : '',
//     '',
//     'Return only the image, no additional text.',
//   ]
//     .filter(Boolean)
//     .join('\n');
// }

// async function generateBannerImageUrl(params) {
//   const model = getImageModel();
//   const prompt = buildBannerPrompt(params);

//   console.log('[AI_BANNER] Generating banner with prompt snippet:', prompt.slice(0, 160));

//   const result = await model.generateContent([prompt]);

//   const part =
//     result?.response?.candidates?.[0]?.content?.parts?.find(
//       (p) => p.inlineData && p.inlineData.data,
//     ) || result?.response?.candidates?.[0]?.content?.parts?.[0];

//   if (!part || !part.inlineData || !part.inlineData.data) {
//     throw new Error('Image generation failed: no image data returned from Gemini.');
//   }

//   const buffer = Buffer.from(part.inlineData.data, 'base64');

//   const uploadResult = await new Promise((resolve, reject) => {
//     const stream = cloudinary.uploader.upload_stream(
//       {
//         folder: 'doffers/ai-banners',
//         resource_type: 'image',
//         format: 'png',
//       },
//       (err, resultData) => {
//         if (err) return reject(err);
//         resolve(resultData);
//       },
//     );
//     stream.end(buffer);
//   });

//   const imageUrl = uploadResult.secure_url || uploadResult.url;

//   return {
//     imageUrl,
//     altText: `${params.title || 'Offer'} banner for ${params.shopName || 'Local Shop'}`,
//     promptUsed: prompt,
//   };
// }

// module.exports = {
//   generateBannerImageUrl,
// };



// const { GoogleGenerativeAI } = require('@google/generative-ai');
// const cloudinary = require('../../config/cloudinary');

// const IMAGE_MODEL_NAME =
//   process.env.GEMINI_IMAGE_MODEL || 'gemini-2.5-flash-image';

// let imageModel;

// function getImageModel() {
//   if (!process.env.GEMINI_API_KEY) {
//     throw new Error('GEMINI_API_KEY is not configured in environment');
//   }

//   if (!imageModel) {
//     const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
//     imageModel = genAI.getGenerativeModel({ model: IMAGE_MODEL_NAME });
//   }

//   return imageModel;
// }

// /* ------------------------------------------------------- */
// /* CATEGORY → VISUAL SCENE MAP */
// /* ------------------------------------------------------- */

// const CATEGORY_SCENES = {
//   retail:
//     'modern Indian retail store with shopping bags, product shelves and customers shopping',

//   restaurant:
//     'restaurant interior with delicious plated dishes and customers dining',

//   grocery:
//     'fresh vegetables, fruits and grocery shelves inside a supermarket',

//   pharmacy:
//     'clean pharmacy store with medicine shelves and pharmacist assisting customer',

//   electronics:
//     'electronics showroom with smartphones, laptops and gadgets display',

//   clothing:
//     'fashion models wearing stylish clothes in a modern clothing store',

//   beauty_salon:
//     'modern beauty salon with hairstyling and grooming scene',

//   gym_fitness:
//     'gym interior with people exercising and fitness equipment',

//   education:
//     'modern classroom or study center with students learning',

//   healthcare:
//     'clean medical clinic or healthcare center with doctor and patient',

//   automotive:
//     'car service center or automobile showroom with vehicles',

//   home_services:
//     'home improvement scene with technician repairing or installing appliances',

//   entertainment:
//     'entertainment zone with games, music or cinema vibe',

//   food_beverage:
//     'food stall or cafe serving delicious drinks and snacks',

//   jewelry:
//     'luxury jewelry store displaying gold and diamond ornaments',

//   books_stationery:
//     'bookstore with bookshelves, notebooks and stationery items',

//   sports:
//     'sports shop with sports equipment and active lifestyle visuals',

//   pet_care:
//     'pet shop with dogs, cats and pet products display',

//   travel:
//     'travel agency concept with suitcase, travel destinations and airplane visuals',

//   other:
//     'modern retail shop environment with products and customers'
// };

// /* ------------------------------------------------------- */
// /* PROMPT BUILDER */
// /* ------------------------------------------------------- */

// function buildBannerPrompt({
//   title,
//   description,
//   category,
//   discountType,
//   discountValue,
//   shopName,
//   shopLocation,
// }) {

//   const discountLabel =
//     discountType === 'percentage' && discountValue != null
//       ? `${discountValue}% OFF`
//       : discountType === 'fixed' && discountValue != null
//         ? `₹${discountValue} OFF`
//         : 'Special Offer';

//   const visualScene =
//     CATEGORY_SCENES[category] || CATEGORY_SCENES.other;

//   return `
// Create a professional promotional banner for a hyperlocal Indian retail business.

// Banner Specifications:
// • Size: 1080x540 horizontal banner
// • Mobile friendly layout
// • Left side: promotional text
// • Right side: product or customer visual

// Shop Information:
// Shop Name: ${shopName || 'Local Shop'}
// Location: ${shopLocation || 'Local Area'}
// Category: ${category || 'Retail'}

// Offer Information:
// Offer Title: ${title || 'Limited Time Offer'}
// Main Discount Text: ${discountLabel}
// Offer Details: ${description || ''}

// Visual Scene:
// ${visualScene}

// Typography Hierarchy:
// 1. VERY LARGE bold discount text (main focus)
// 2. Medium sized offer title
// 3. Smaller shop name and location

// Design Style:
// • Modern Indian retail advertisement
// • Premium marketing banner
// • Clean minimal background
// • Balanced layout
// • High contrast typography

// Style Reference:
// Myntra promotional banner, professional fashion advertisement,
// modern e-commerce sale poster, Indian retail marketing creative.

// Lighting & Photography:
// Soft studio lighting, professional product photography,
// clean shadows and premium visual quality.

// Important Rules:
// • Discount text must be extremely large and prominent
// • Text must be readable on small phones
// • Avoid clutter and small unreadable text
// • No UI buttons or interface elements
// • Professional advertising composition

// Make the banner look like it was designed by a professional marketing agency.

// Return ONLY the banner image.
// `;
// }

// /* ------------------------------------------------------- */
// /* IMAGE GENERATION */
// /* ------------------------------------------------------- */

// async function generateBannerImageUrl(params) {

//   const model = getImageModel();
//   const prompt = buildBannerPrompt(params);

//   console.log(
//     '[AI_BANNER] Generating banner with prompt snippet:',
//     prompt.slice(0, 160)
//   );

//   const result = await model.generateContent([prompt]);

//   const part =
//     result?.response?.candidates?.[0]?.content?.parts?.find(
//       (p) => p.inlineData && p.inlineData.data
//     ) || result?.response?.candidates?.[0]?.content?.parts?.[0];

//   if (!part || !part.inlineData || !part.inlineData.data) {
//     throw new Error('Image generation failed: no image data returned from Gemini.');
//   }

//   const buffer = Buffer.from(part.inlineData.data, 'base64');

//   /* ------------------------------------------------------- */
//   /* CLOUDINARY UPLOAD */
//   /* ------------------------------------------------------- */

//   const uploadResult = await new Promise((resolve, reject) => {

//     const stream = cloudinary.uploader.upload_stream(
//       {
//         folder: 'doffers/ai-banners',
//         resource_type: 'image',
//         format: 'png',
//       },
//       (err, resultData) => {
//         if (err) return reject(err);
//         resolve(resultData);
//       }
//     );

//     stream.end(buffer);
//   });

//   const imageUrl = uploadResult.secure_url || uploadResult.url;

//   return {
//     imageUrl,
//     altText: `${params.title || 'Offer'} banner for ${params.shopName || 'Local Shop'
//       }`,
//     promptUsed: prompt,
//   };
// }

// module.exports = {
//   generateBannerImageUrl,
// };



const { GoogleGenerativeAI } = require("@google/generative-ai");
const sharp = require("sharp");
const cloudinary = require("../../config/cloudinary");

const buildBackgroundPrompt = require("../prompts/backgroundPrompt");
const { extractBrandPalette } = require("../utilities/brandColor");
const { getSeasonalModifier } = require("../utilities/seasonalThemes");
const { pickTemplate } = require("../templates/bannerTemplates");

const IMAGE_MODEL_NAME =
  process.env.GEMINI_IMAGE_MODEL || "gemini-2.5-flash-image";

let imageModel;

function getImageModel() {
  if (!process.env.GEMINI_API_KEY) {
    throw new Error("GEMINI_API_KEY is not configured in environment");
  }

  if (!imageModel) {
    const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
    imageModel = genAI.getGenerativeModel({ model: IMAGE_MODEL_NAME });
  }

  return imageModel;
}

/* ── AI background generation ── */

async function generateBackground(category) {
  const model = getImageModel();
  const prompt = buildBackgroundPrompt(category);

  console.log(
    "[AI_BANNER] Background prompt snippet:",
    prompt.slice(0, 200)
  );

  const result = await model.generateContent([prompt]);

  const part =
    result?.response?.candidates?.[0]?.content?.parts?.find(
      (p) => p.inlineData && p.inlineData.data
    ) || result?.response?.candidates?.[0]?.content?.parts?.[0];

  if (!part || !part.inlineData || !part.inlineData.data) {
    throw new Error(
      "Image generation failed: no image data returned from Gemini for background."
    );
  }

  return Buffer.from(part.inlineData.data, "base64");
}

/* ── Logo fetching & circular crop ── */

async function fetchLogoBuffer(logoUrl) {
  if (!logoUrl) return null;
  try {
    const res = await fetch(logoUrl);
    if (!res.ok) return null;
    const arrayBuf = await res.arrayBuffer();

    const SIZE = 80;
    const BORDER = 4;
    const TOTAL = SIZE + BORDER * 2;

    // Create circular mask
    const circleMask = Buffer.from(
      `<svg width="${TOTAL}" height="${TOTAL}">
        <circle cx="${TOTAL / 2}" cy="${TOTAL / 2}" r="${SIZE / 2}"
                fill="white"/>
      </svg>`
    );

    // Resize logo into circle with white border
    const logo = await sharp(Buffer.from(arrayBuf))
      .resize(SIZE, SIZE, { fit: "cover" })
      .composite([{ input: circleMask, blend: "dest-in" }])
      .png()
      .toBuffer();

    // White circle border background
    const borderCircle = Buffer.from(
      `<svg width="${TOTAL}" height="${TOTAL}">
        <circle cx="${TOTAL / 2}" cy="${TOTAL / 2}" r="${TOTAL / 2}"
                fill="white"/>
      </svg>`
    );

    return sharp(borderCircle)
      .composite([{ input: logo, top: BORDER, left: BORDER }])
      .png()
      .toBuffer();
  } catch {
    return null;
  }
}

/* ── Main banner generation ── */

async function generateBannerImageUrl(params) {
  const discountLabel =
    params.discountType === "percentage" && params.discountValue != null
      ? `${params.discountValue}% OFF`
      : params.discountType === "fixed" && params.discountValue != null
        ? `₹${params.discountValue} OFF`
        : "Special Offer";

  // Run independent tasks in parallel
  const [backgroundBuffer, palette, logoBuffer] = await Promise.all([
    generateBackground(params.category),
    extractBrandPalette(params.logo, params.category),
    fetchLogoBuffer(params.logo),
  ]);

  const seasonal = getSeasonalModifier();

  const { svg, templateName, logoPosition } = pickTemplate({
    discount: discountLabel,
    title: params.title,
    shop: params.shopName,
    location: params.shopLocation,
    category: params.category,
    discountValue: params.discountValue != null ? Number(params.discountValue) : null,
    palette,
    templatePreference: params.templatePreference || null,
  });

  // ── Composite: full-bleed photo + SVG text overlay + optional logo ──
  const W = 1080;
  const H = 540;

  const layers = [
    { input: Buffer.from(svg), top: 0, left: 0 },
  ];

  if (logoBuffer && logoPosition) {
    layers.push({
      input: logoBuffer,
      top: logoPosition.y,
      left: logoPosition.x,
    });
  }

  const finalImage = await sharp(backgroundBuffer)
    .resize(W, H)
    .composite(layers)
    .sharpen({ sigma: 0.8 })
    .png({ compressionLevel: 6 })
    .toBuffer();

  const uploadResult = await new Promise((resolve, reject) => {
    const stream = cloudinary.uploader.upload_stream(
      {
        folder: "doffers/ai-banners",
        resource_type: "image",
        format: "png",
      },
      (err, resultData) => {
        if (err) return reject(err);
        resolve(resultData);
      }
    );
    stream.end(finalImage);
  });

  const imageUrl = uploadResult.secure_url || uploadResult.url;

  console.log(
    "[AI_BANNER] Generated:",
    JSON.stringify({
      template: templateName,
      seasonal: seasonal?.name || "none",
      palette: { primary: palette.primary, secondary: palette.secondary },
      category: params.category,
      hasLogo: !!logoBuffer,
    })
  );

  return {
    imageUrl,
    altText: `${params.title || "Offer"} banner for ${
      params.shopName || "Local Shop"
    }`,
    promptUsed: buildBackgroundPrompt(params.category),
    templateUsed: templateName,
    seasonalTheme: seasonal?.name || null,
  };
}

module.exports = { generateBannerImageUrl };