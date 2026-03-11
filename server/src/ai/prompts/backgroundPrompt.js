const CATEGORY_SCENES = require("../utilities/categoryScenes");
const { getSeasonalModifier } = require("../utilities/seasonalThemes");

/**
 * Builds a detailed, Flipkart / Myntra-grade prompt for the
 * AI image model to generate a professional banner background.
 *
 * @param {string} category  – shop/offer category key
 * @returns {string}
 */
function buildBackgroundPrompt(category) {
  const cat = CATEGORY_SCENES[category] || CATEGORY_SCENES.other;
  const seasonal = getSeasonalModifier();

  const seasonalBlock = seasonal
    ? `
Seasonal / Festival Overlay:
This banner coincides with "${seasonal.name}".
Subtly weave the following festive visual accents into the scene
WITHOUT overpowering the product / shop context:
${seasonal.prompt}
`
    : "";

  return `
You are a senior art-director at a top Indian e-commerce company
(think Flipkart Big Billion Days, Myntra End of Reason Sale, Men's Avenue).
Generate a premium promotional banner image.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CANVAS & COMPOSITION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
• Dimensions : 1080 × 540 px  (2 : 1 horizontal)
• The image must fill the ENTIRE canvas edge-to-edge.
  NO blank areas, NO white space, NO split panels.
• The scene should feel like a real professional
  commercial photograph shot in a studio or real location.
• Think high-end retail store interior / lifestyle shoot /
  product flat-lay that covers the full frame.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCENE DIRECTION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
${cat.scene}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
LIGHTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
${cat.lighting}
Use cinematic lighting with depth — NOT flat or evenly lit.
Warm highlights, soft shadows, natural light fall-off.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
COLOUR MOOD
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Dominant palette: ${cat.palette}
${seasonalBlock}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
QUALITY & STYLE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
• Photo-realistic, 8K-render quality, commercial advertising standard.
• Professional product / lifestyle photography aesthetic.
• Magazine-cover-worthy composition and colour grading.
• The image should look like an actual photograph, not illustrated.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STRICT RULES — DO NOT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
• Do NOT include any text, words, letters, numbers, watermarks.
• Do NOT include logos, brand names, price tags or UI elements.
• Do NOT include borders, frames, or phone mockups.
• Do NOT leave any blank / white / empty areas.
• Do NOT generate any cluttered or noisy backgrounds.

Return ONLY the image. No text output.
`;
}

module.exports = buildBackgroundPrompt;