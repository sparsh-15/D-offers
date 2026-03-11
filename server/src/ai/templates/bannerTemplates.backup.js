/**
 * Professional Flipkart / Myntra-style SVG banner templates.
 *
 * 6 layouts  ·  CTA buttons  ·  SVG gradients  ·  drop-shadow filters
 * Smart selection based on category + discount magnitude.
 */

/* ── Helpers ── */

function escapeXml(str) {
  if (!str) return "";
  return String(str)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&apos;");
}

function truncate(str, max) {
  if (!str) return "";
  return str.length > max ? str.slice(0, max - 1) + "…" : str;
}

/* ── CTA text mapping ── */

const CTA_MAP = {
  clothing: "Shop Now",
  beauty_salon: "Shop Now",
  jewelry: "Shop Now",
  restaurant: "Order Now",
  grocery: "Order Now",
  food_beverage: "Order Now",
  gym_fitness: "Join Now",
  healthcare: "Join Now",
  electronics: "Grab Deal",
  retail: "Grab Deal",
};

function ctaText(category) {
  return CTA_MAP[category] || "Claim Offer";
}

/* ── Shared SVG snippets ── */

function shadowFilter() {
  return `
  <filter id="ds" x="-4%" y="-4%" width="108%" height="108%">
    <feDropShadow dx="0" dy="2" stdDeviation="3" flood-color="#000" flood-opacity="0.45"/>
  </filter>`;
}

function gradientDef(id, c1, c2, angle) {
  // angle: 0=left→right, 90=top→bottom
  const coords =
    angle === 90
      ? 'x1="0" y1="0" x2="0" y2="1"'
      : 'x1="0" y1="0" x2="1" y2="0"';
  return `<linearGradient id="${id}" ${coords}>
    <stop offset="0%" stop-color="${c1}"/>
    <stop offset="100%" stop-color="${c2}"/>
  </linearGradient>`;
}

/* ════════════════════════════════════════════════════════════
   TEMPLATE 1 — heroLeftTemplate
   Myntra "End of Reason Sale" style.
   Gradient panel on left, large discount, CTA at bottom-left.
   ════════════════════════════════════════════════════════════ */

function heroLeftTemplate({ discount, title, shop, location, cta, palette }) {
  const d = escapeXml(discount);
  const t = escapeXml(truncate(title, 40));
  const s = escapeXml(truncate(shop, 30));
  const l = escapeXml(truncate(location, 30));
  const sBadge = escapeXml(truncate(shop, 22).toUpperCase());
  const { primary, secondary, accent, textColor } = palette;

  return `<svg xmlns="http://www.w3.org/2000/svg" width="1080" height="540">
  <defs>
    ${shadowFilter()}
    <linearGradient id="fadeLeft" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0%"  stop-color="${primary}" stop-opacity="0.55"/>
      <stop offset="30%" stop-color="${primary}" stop-opacity="0.30"/>
      <stop offset="55%" stop-color="${primary}" stop-opacity="0"/>
    </linearGradient>
  </defs>

  <rect x="0" y="0" width="1080" height="540" fill="url(#fadeLeft)"/>

  <text x="50" y="150" font-family="Arial,sans-serif" font-size="82" font-weight="bold"
        fill="${textColor}" filter="url(#ds)">${d}</text>

  <text x="50" y="215" font-family="Arial,sans-serif" font-size="36" font-weight="600"
        fill="${textColor}" opacity="0.95">${t}</text>

  <rect x="44" y="252" width="310" height="40" rx="20" fill="${accent}" opacity="0.90"/>
  <text x="199" y="278" text-anchor="middle" font-family="Arial,sans-serif" font-size="21"
        font-weight="800" letter-spacing="2.5" fill="${textColor}">${sBadge}</text>

  <text x="50" y="326" font-family="Arial,sans-serif" font-size="20"
        fill="${textColor}" opacity="0.7">${l}</text>

  <rect x="40" y="432" width="200" height="54" rx="27" fill="${accent}"/>
  <text x="140" y="467" text-anchor="middle" font-family="Arial,sans-serif"
        font-size="22" font-weight="bold" fill="${textColor}">${escapeXml(cta)}</text>
</svg>`;
}

heroLeftTemplate.logoPosition = { x: 50, y: 360 };

/* ════════════════════════════════════════════════════════════
   TEMPLATE 2 — splitDiagonalTemplate
   Bold geometric diagonal split.
   ════════════════════════════════════════════════════════════ */

function splitDiagonalTemplate({ discount, title, shop, cta, palette }) {
  const d = escapeXml(discount);
  const t = escapeXml(truncate(title, 36));
  const s = escapeXml(truncate(shop, 30));
  const sBadge = escapeXml(truncate(shop, 22).toUpperCase());
  const { primary, secondary, accent, textColor } = palette;

  return `<svg xmlns="http://www.w3.org/2000/svg" width="1080" height="540">
  <defs>
    ${shadowFilter()}
    <linearGradient id="dGrad" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0%"  stop-color="${primary}"   stop-opacity="0.50"/>
      <stop offset="28%" stop-color="${primary}"   stop-opacity="0.28"/>
      <stop offset="50%" stop-color="${secondary}" stop-opacity="0"/>
    </linearGradient>
  </defs>

  <rect x="0" y="0" width="1080" height="540" fill="url(#dGrad)"/>

  <text x="50" y="180" font-family="Arial,sans-serif" font-size="78" font-weight="bold"
        fill="${textColor}" filter="url(#ds)">${d}</text>

  <text x="50" y="250" font-family="Arial,sans-serif" font-size="34" font-weight="600"
        fill="${textColor}" opacity="0.95">${t}</text>

  <rect x="44" y="268" width="310" height="40" rx="20" fill="${accent}" opacity="0.90"/>
  <text x="199" y="294" text-anchor="middle" font-family="Arial,sans-serif" font-size="21"
        font-weight="800" letter-spacing="2.5" fill="${textColor}">${sBadge}</text>

  <rect x="40" y="422" width="190" height="50" rx="25" fill="${accent}"/>
  <text x="135" y="455" text-anchor="middle" font-family="Arial,sans-serif"
        font-size="21" font-weight="bold" fill="${textColor}">${escapeXml(cta)}</text>
</svg>`;
}

splitDiagonalTemplate.logoPosition = { x: 50, y: 345 };

/* ════════════════════════════════════════════════════════════
   TEMPLATE 3 — fullWidthBarTemplate
   Flipkart "Big Billion Days" — top accent strip + centered hero text.
   ════════════════════════════════════════════════════════════ */

function fullWidthBarTemplate({ discount, title, shop, cta, palette }) {
  const d = escapeXml(discount);
  const t = escapeXml(truncate(title, 44));
  const s = escapeXml(truncate(shop, 36));
  const { primary, secondary, accent, textColor } = palette;

  return `<svg xmlns="http://www.w3.org/2000/svg" width="1080" height="540">
  <defs>
    ${shadowFilter()}
    ${gradientDef("topGrad", primary, accent, 0)}
  </defs>

  <!-- top accent strip -->
  <rect x="0" y="0" width="1080" height="8" fill="url(#topGrad)"/>

  <!-- centre panel -->
  <rect x="0" y="180" width="1080" height="190" fill="${primary}" opacity="0.88"/>

  <text x="540" y="265" text-anchor="middle" font-family="Arial,sans-serif"
        font-size="90" font-weight="bold" fill="${textColor}" filter="url(#ds)">${d}</text>

  <text x="540" y="320" text-anchor="middle" font-family="Arial,sans-serif"
        font-size="34" font-weight="600" fill="${textColor}" opacity="0.95">${t}</text>

  <!-- bottom CTA bar -->
  <rect x="0" y="490" width="1080" height="50" fill="${secondary}" opacity="0.85"/>
  <text x="430" y="523" font-family="Arial,sans-serif" font-size="22"
        fill="${textColor}" opacity="0.85">${s}</text>
  <rect x="700" y="496" width="180" height="40" rx="20" fill="${accent}"/>
  <text x="790" y="523" text-anchor="middle" font-family="Arial,sans-serif"
        font-size="20" font-weight="bold" fill="${textColor}">${escapeXml(cta)}</text>
</svg>`;
}

fullWidthBarTemplate.logoPosition = { x: 30, y: 495 };

/* ════════════════════════════════════════════════════════════
   TEMPLATE 4 — cornerBadgeTemplate
   Amazon Lightning Deals style — bold corner starburst / badge.
   ════════════════════════════════════════════════════════════ */

function cornerBadgeTemplate({ discount, title, shop, location, cta, palette }) {
  const d = escapeXml(discount);
  const t = escapeXml(truncate(title, 40));
  const s = escapeXml(truncate(shop, 30));
  const l = escapeXml(truncate(location, 28));
  const { primary, accent, textColor } = palette;

  return `<svg xmlns="http://www.w3.org/2000/svg" width="1080" height="540">
  <defs>
    ${shadowFilter()}
  </defs>

  <!-- corner badge circle -->
  <circle cx="130" cy="130" r="110" fill="${primary}" opacity="0.95"/>
  <text x="130" y="118" text-anchor="middle" font-family="Arial,sans-serif"
        font-size="42" font-weight="bold" fill="${textColor}" filter="url(#ds)">${d}</text>
  <text x="130" y="158" text-anchor="middle" font-family="Arial,sans-serif"
        font-size="18" fill="${textColor}" opacity="0.85">LIMITED DEAL</text>

  <!-- centre title -->
  <text x="540" y="310" text-anchor="middle" font-family="Arial,sans-serif"
        font-size="42" font-weight="bold" fill="${primary}" filter="url(#ds)">${t}</text>

  <!-- bottom bar -->
  <rect x="0" y="450" width="1080" height="90" fill="${primary}" opacity="0.9"/>
  <text x="50" y="500" font-family="Arial,sans-serif" font-size="22"
        fill="${textColor}" opacity="0.9">${s}${l ? "  ·  " + l : ""}</text>

  <rect x="820" y="465" width="210" height="50" rx="25" fill="${accent}"/>
  <text x="925" y="498" text-anchor="middle" font-family="Arial,sans-serif"
        font-size="22" font-weight="bold" fill="${textColor}">${escapeXml(cta)}</text>
</svg>`;
}

cornerBadgeTemplate.logoPosition = { x: 960, y: 20 };

/* ════════════════════════════════════════════════════════════
   TEMPLATE 5 — gradientOverlayTemplate
   Premium fashion / lifestyle — full left→right gradient fade.
   ════════════════════════════════════════════════════════════ */

function gradientOverlayTemplate({ discount, title, shop, location, cta, palette }) {
  const d = escapeXml(discount);
  const t = escapeXml(truncate(title, 40));
  const s = escapeXml(truncate(shop, 30));
  const l = escapeXml(truncate(location, 28));
  const sBadge = escapeXml(truncate(shop, 22).toUpperCase());
  const { primary, gradientEnd, accent, textColor } = palette;

  return `<svg xmlns="http://www.w3.org/2000/svg" width="1080" height="540">
  <defs>
    ${shadowFilter()}
    <linearGradient id="fadeGrad" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0%"  stop-color="${primary}" stop-opacity="0.50"/>
      <stop offset="30%" stop-color="${primary}" stop-opacity="0.25"/>
      <stop offset="52%" stop-color="${primary}" stop-opacity="0"/>
    </linearGradient>
    <linearGradient id="btmScrim" x1="0" y1="0" x2="0" y2="1">
      <stop offset="60%"  stop-color="#000" stop-opacity="0"/>
      <stop offset="100%" stop-color="#000" stop-opacity="0.38"/>
    </linearGradient>
  </defs>

  <rect x="0" y="0" width="1080" height="540" fill="url(#fadeGrad)"/>
  <rect x="0" y="0" width="1080" height="540" fill="url(#btmScrim)"/>

  <text x="60" y="166" font-family="Arial,sans-serif" font-size="82" font-weight="bold"
        fill="${textColor}" filter="url(#ds)">${d}</text>

  <text x="60" y="232" font-family="Arial,sans-serif" font-size="36" font-weight="600"
        fill="${textColor}" opacity="0.95">${t}</text>

  <rect x="54" y="252" width="310" height="40" rx="20" fill="${accent}" opacity="0.90"/>
  <text x="209" y="278" text-anchor="middle" font-family="Arial,sans-serif" font-size="21"
        font-weight="800" letter-spacing="2.5" fill="${textColor}">${sBadge}</text>

  <text x="60" y="320" font-family="Arial,sans-serif" font-size="20"
        fill="${textColor}" opacity="0.72">${l}</text>

  <rect x="50" y="442" width="210" height="52" rx="26" fill="${accent}"/>
  <text x="155" y="476" text-anchor="middle" font-family="Arial,sans-serif"
        font-size="22" font-weight="bold" fill="${textColor}">${escapeXml(cta)}</text>
</svg>`;
}

gradientOverlayTemplate.logoPosition = { x: 60, y: 360 };

/* ════════════════════════════════════════════════════════════
   TEMPLATE 6 — bottomBannerTemplate
   Swiggy / Zomato promo style — scene fills canvas, bold bar on bottom 30 %.
   ════════════════════════════════════════════════════════════ */

function bottomBannerTemplate({ discount, title, shop, location, cta, palette }) {
  const d = escapeXml(discount);
  const t = escapeXml(truncate(title, 44));
  const s = escapeXml(truncate(shop, 30));
  const l = escapeXml(truncate(location, 28));
  const { primary, secondary, accent, textColor } = palette;

  return `<svg xmlns="http://www.w3.org/2000/svg" width="1080" height="540">
  <defs>
    ${shadowFilter()}
    ${gradientDef("btmGrad", secondary, primary, 0)}
  </defs>

  <!-- fade-up overlay for readability above bar -->
  <linearGradient id="fadeUp" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0%" stop-color="${secondary}" stop-opacity="0"/>
    <stop offset="100%" stop-color="${secondary}" stop-opacity="0.65"/>
  </linearGradient>
  <rect x="0" y="300" width="1080" height="240" fill="url(#fadeUp)"/>

  <!-- bottom solid bar -->
  <rect x="0" y="380" width="1080" height="160" fill="url(#btmGrad)" opacity="0.92"/>

  <text x="50" y="440" font-family="Arial,sans-serif" font-size="64" font-weight="bold"
        fill="${textColor}" filter="url(#ds)">${d}</text>

  <text x="50" y="490" font-family="Arial,sans-serif" font-size="30" font-weight="600"
        fill="${textColor}" opacity="0.95">${t}</text>

  <text x="50" y="528" font-family="Arial,sans-serif" font-size="20"
        fill="${textColor}" opacity="0.8">${s}${l ? "  ·  " + l : ""}</text>

  <rect x="830" y="428" width="210" height="50" rx="25" fill="${accent}"/>
  <text x="935" y="461" text-anchor="middle" font-family="Arial,sans-serif"
        font-size="22" font-weight="bold" fill="${textColor}">${escapeXml(cta)}</text>
</svg>`;
}

bottomBannerTemplate.logoPosition = { x: 960, y: 385 };

/* ═══════════════════════════════════════════════
   Smart template selection
   ═══════════════════════════════════════════════ */

const ALL_TEMPLATES = [
  heroLeftTemplate,
  splitDiagonalTemplate,
  fullWidthBarTemplate,
  cornerBadgeTemplate,
  gradientOverlayTemplate,
  bottomBannerTemplate,
];

const CATEGORY_PREFERRED = {
  clothing: [gradientOverlayTemplate],
  beauty_salon: [gradientOverlayTemplate],
  jewelry: [gradientOverlayTemplate],
  restaurant: [bottomBannerTemplate, fullWidthBarTemplate],
  grocery: [bottomBannerTemplate, fullWidthBarTemplate],
  food_beverage: [bottomBannerTemplate, fullWidthBarTemplate],
  electronics: [splitDiagonalTemplate, cornerBadgeTemplate],
  gym_fitness: [splitDiagonalTemplate, fullWidthBarTemplate],
  sports: [splitDiagonalTemplate, fullWidthBarTemplate],
};

/**
 * @param {object}       data
 * @param {string}       data.discount
 * @param {string}       data.title
 * @param {string}       data.shop
 * @param {string}       data.location
 * @param {string}       data.category
 * @param {number|null}  data.discountValue  – raw number used for magnitude logic
 * @param {object}       data.palette        – { primary, secondary, accent, textColor, gradientEnd }
 * @param {string|null}  [data.templatePreference] – optional explicit template name
 * @returns {{ svg: string, templateName: string, logoPosition: {x:number,y:number} }}
 */
function pickTemplate(data) {
  const cta = ctaText(data.category);
  const payload = { ...data, cta };

  // 1. Honour explicit preference if given
  if (data.templatePreference) {
    const match = ALL_TEMPLATES.find(
      (fn) => fn.name === data.templatePreference
    );
    if (match) {
      return {
        svg: match(payload),
        templateName: match.name,
        logoPosition: match.logoPosition,
      };
    }
  }

  // 2. High-impact discounts (≥50%) → dramatic templates
  const bigDeal = typeof data.discountValue === "number" && data.discountValue >= 50;
  if (bigDeal) {
    const dramatic = [cornerBadgeTemplate, fullWidthBarTemplate];
    const pick = dramatic[Math.floor(Math.random() * dramatic.length)];
    return {
      svg: pick(payload),
      templateName: pick.name,
      logoPosition: pick.logoPosition,
    };
  }

  // 3. Category-preferred templates
  const preferred = CATEGORY_PREFERRED[data.category];
  if (preferred && preferred.length) {
    const pick = preferred[Math.floor(Math.random() * preferred.length)];
    return {
      svg: pick(payload),
      templateName: pick.name,
      logoPosition: pick.logoPosition,
    };
  }

  // 4. Fallback — random from all
  const pick = ALL_TEMPLATES[Math.floor(Math.random() * ALL_TEMPLATES.length)];
  return {
    svg: pick(payload),
    templateName: pick.name,
    logoPosition: pick.logoPosition,
  };
}

module.exports = { pickTemplate, ctaText };