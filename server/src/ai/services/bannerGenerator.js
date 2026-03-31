
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
    console.log(imageModel);
    
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
        folder: "MyOffers/ai-banners",
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