/**
 * Indian festival / seasonal auto-detection.
 *
 * Returns a prompt modifier snippet + optional accent colour
 * based on proximity to the current date.
 *
 * Dates are approximate; many Indian festivals follow the lunar
 * calendar and shift each year, so a ±7-day window is used.
 */

const FESTIVALS = [
  // ── Major shopping festivals ──
  {
    name: "Diwali",
    month: 10, // 0-indexed (November)
    day: 1,
    window: 10, // days before the date to activate
    prompt:
      "Festive Diwali celebration theme: warm golden lighting, glowing diyas and candles, sparkler bokeh, rangoli patterns framing the edges, rich marigold garlands, luxurious festive Indian atmosphere",
    accent: "#FFD700",
  },
  {
    name: "Holi",
    month: 2, // March
    day: 14,
    window: 7,
    prompt:
      "Vibrant Holi festival theme: colourful gulal powder clouds in pink yellow green and blue, splashes of bright colour, playful rainbow palette, joyful spring energy",
    accent: "#FF4081",
  },
  {
    name: "Christmas & New Year",
    month: 11, // December
    day: 25,
    window: 12,
    prompt:
      "Christmas and New Year celebration theme: falling confetti and snowflakes, red-green-gold colour accents, gift boxes, fairy-light bokeh, warm holiday cheer",
    accent: "#C62828",
  },
  {
    name: "New Year Sale",
    month: 0, // January
    day: 1,
    window: 7,
    prompt:
      "New Year sale theme: golden glitter confetti burst, champagne fizz bokeh, fresh-start energy, celebratory fireworks accents in the sky",
    accent: "#FFD700",
  },

  // ── Other key Indian festivals ──
  {
    name: "Raksha Bandhan",
    month: 7, // August
    day: 19,
    window: 5,
    prompt:
      "Raksha Bandhan theme: decorative rakhis, warm family celebration vibes, pastel pink and gold accents, Indian festive warmth",
    accent: "#E91E63",
  },
  {
    name: "Independence Day",
    month: 7, // August
    day: 15,
    window: 3,
    prompt:
      "Indian Independence Day patriotic theme: tricolour saffron-white-green accents, subtle flag motifs, proud national celebration",
    accent: "#FF9933",
  },
  {
    name: "Republic Day",
    month: 0, // January
    day: 26,
    window: 3,
    prompt:
      "Republic Day patriotic theme: tricolour saffron-white-green accents, Ashoka Chakra motif hint, national pride celebration",
    accent: "#138808",
  },
  {
    name: "Navratri / Durga Puja",
    month: 9, // October
    day: 10,
    window: 9,
    prompt:
      "Navratri festive theme: vibrant dandiya sticks, traditional Indian patterns, rich red orange and gold colours, energetic celebration",
    accent: "#FF5722",
  },
  {
    name: "Eid",
    month: 3, // approximate – shifts yearly
    day: 31,
    window: 5,
    prompt:
      "Eid celebration theme: crescent moon and star accents, elegant green-and-gold palette, lantern glow, warm togetherness atmosphere",
    accent: "#2E7D32",
  },
  {
    name: "Onam",
    month: 8, // September
    day: 5,
    window: 5,
    prompt:
      "Onam harvest festival theme: pookalam floral carpet patterns, banana leaf feast vibes, vibrant Kerala colours, traditional warmth",
    accent: "#FFC107",
  },
  {
    name: "Pongal / Makar Sankranti",
    month: 0, // January
    day: 14,
    window: 3,
    prompt:
      "Pongal harvest theme: overflowing pot of rice, sugarcane stalks, kite festival colours, warm south-Indian festive vibes",
    accent: "#FF6F00",
  },

  // ── Seasonal sale periods ──
  {
    name: "Summer Sale",
    month: 4, // May
    day: 15,
    window: 20,
    prompt:
      "Hot summer sale theme: bright sunny vibes, cool refreshing blues and yellows, ice cubes, sunglasses, tropical leaves, energetic summer mood",
    accent: "#00BCD4",
  },
  {
    name: "Monsoon Sale",
    month: 6, // July
    day: 15,
    window: 15,
    prompt:
      "Monsoon sale theme: raindrops on glass, lush green freshness, colourful umbrella accents, cool refreshing atmosphere",
    accent: "#26A69A",
  },
  {
    name: "Back to School",
    month: 5, // June
    day: 10,
    window: 10,
    prompt:
      "Back-to-school theme: colourful notebooks, pencils, backpacks, chalkboard texture accents, energetic academic vibes",
    accent: "#1565C0",
  },
  {
    name: "Valentine's Day",
    month: 1, // February
    day: 14,
    window: 7,
    prompt:
      "Valentine's Day romantic theme: soft red and pink hearts, rose petals, love-letter accents, warm romantic bokeh glow",
    accent: "#D50000",
  },
];

/**
 * Returns the closest active festival/season modifier, or null.
 *
 * @returns {{ name: string, prompt: string, accent: string } | null}
 */
function getSeasonalModifier() {
  const now = new Date();
  const year = now.getFullYear();

  let best = null;
  let bestDistance = Infinity;

  for (const f of FESTIVALS) {
    const festDate = new Date(year, f.month, f.day);
    const diff = (festDate - now) / (1000 * 60 * 60 * 24); // days

    // Activate if we are within the window BEFORE the festival,
    // or up to 2 days AFTER it (people still celebrate).
    if (diff >= -2 && diff <= f.window) {
      const distance = Math.abs(diff);
      if (distance < bestDistance) {
        bestDistance = distance;
        best = { name: f.name, prompt: f.prompt, accent: f.accent };
      }
    }
  }

  return best;
}

module.exports = { getSeasonalModifier };
