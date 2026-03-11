const { Vibrant } = require("node-vibrant/node");

/* ── Category fallback palettes (when no logo is available) ── */

const CATEGORY_FALLBACK_COLORS = {
  clothing: "#E91E63",
  grocery: "#4CAF50",
  electronics: "#2196F3",
  restaurant: "#FF5722",
  food_beverage: "#FF5722",
  jewelry: "#FFD700",
  pharmacy: "#00BCD4",
  gym_fitness: "#FF6F00",
  beauty_salon: "#E91E63",
  books_stationery: "#795548",
  sports: "#4CAF50",
  pet_care: "#FF9800",
  travel: "#03A9F4",
  retail: "#F44336",
  automotive: "#607D8B",
  healthcare: "#0097A7",
  education: "#1565C0",
  home_services: "#8D6E63",
  entertainment: "#9C27B0",
  other: "#ff4d4f",
};

/* ── WCAG relative-luminance helpers ── */

function hexToRgb(hex) {
  const h = hex.replace("#", "");
  return {
    r: parseInt(h.substring(0, 2), 16),
    g: parseInt(h.substring(2, 4), 16),
    b: parseInt(h.substring(4, 6), 16),
  };
}

function relativeLuminance({ r, g, b }) {
  const [rs, gs, bs] = [r, g, b].map((c) => {
    const s = c / 255;
    return s <= 0.03928 ? s / 12.92 : Math.pow((s + 0.055) / 1.055, 2.4);
  });
  return 0.2126 * rs + 0.7152 * gs + 0.0722 * bs;
}

function contrastTextColor(hex) {
  return relativeLuminance(hexToRgb(hex)) > 0.4 ? "#1a1a1a" : "#ffffff";
}

function hexToRgba(hex, alpha) {
  const { r, g, b } = hexToRgb(hex);
  return `rgba(${r},${g},${b},${alpha})`;
}

/* ── Main extraction ── */

/**
 * Extracts a full brand-colour palette from the shop logo.
 *
 * @param {string|null} logoUrl
 * @param {string}      [category='other']
 * @returns {Promise<{
 *   primary: string,
 *   secondary: string,
 *   accent: string,
 *   textColor: string,
 *   gradientEnd: string
 * }>}
 */
async function extractBrandPalette(logoUrl, category = "other") {
  const fallback = CATEGORY_FALLBACK_COLORS[category] || "#ff4d4f";

  if (!logoUrl) {
    return buildPalette(fallback, null);
  }

  try {
    const palette = await Vibrant.from(logoUrl).getPalette();
    const primary = palette?.Vibrant?.hex || fallback;
    return buildPalette(primary, palette);
  } catch {
    return buildPalette(fallback, null);
  }
}

function buildPalette(primary, vibrantPalette) {
  const secondary =
    vibrantPalette?.DarkVibrant?.hex || darken(primary, 0.3);
  const accent =
    vibrantPalette?.LightVibrant?.hex || lighten(primary, 0.25);

  return {
    primary,
    secondary,
    accent,
    textColor: contrastTextColor(primary),
    gradientEnd: hexToRgba(primary, 0),
  };
}

/* ── Simple darken / lighten helpers ── */

function clamp(v) {
  return Math.max(0, Math.min(255, Math.round(v)));
}

function darken(hex, amount) {
  const { r, g, b } = hexToRgb(hex);
  const f = 1 - amount;
  return rgbToHex(clamp(r * f), clamp(g * f), clamp(b * f));
}

function lighten(hex, amount) {
  const { r, g, b } = hexToRgb(hex);
  return rgbToHex(
    clamp(r + (255 - r) * amount),
    clamp(g + (255 - g) * amount),
    clamp(b + (255 - b) * amount)
  );
}

function rgbToHex(r, g, b) {
  return (
    "#" +
    [r, g, b].map((c) => c.toString(16).padStart(2, "0")).join("")
  );
}

module.exports = {
  extractBrandPalette,
  contrastTextColor,
  hexToRgba,
  CATEGORY_FALLBACK_COLORS,
};