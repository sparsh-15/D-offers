/**
 * Professional banner SVG text-overlay templates.
 *
 * Design philosophy (matching Men's Avenue / Flipkart reference):
 *   - Full-bleed background photo — NO split, NO solid panels
 *   - Text floats ON the photo with heavy drop-shadows for legibility
 *   - Shop name = prominent highlighted badge (top or upper-left)
 *   - Discount = MASSIVE bold text
 *   - Title / description = medium text below discount
 *   - Bottom bar with location + CTA button
 *   - Semi-transparent scrims only where absolutely needed for readability
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
  return str.length > max ? str.slice(0, max - 1) + "\u2026" : str;
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

/* ── Shared SVG defs ── */

function heavyShadow() {
  return `
  <filter id="ds" x="-8%" y="-8%" width="116%" height="116%">
    <feDropShadow dx="0" dy="3" stdDeviation="5" flood-color="#000" flood-opacity="0.65"/>
  </filter>
  <filter id="dsLight" x="-4%" y="-4%" width="108%" height="108%">
    <feDropShadow dx="0" dy="1" stdDeviation="2" flood-color="#000" flood-opacity="0.40"/>
  </filter>`;
}

/* ════════════════════════════════════════════════════════════
   TEMPLATE 1 — shopBrandHero
   Men's Avenue "Free Stitching Offer" reference style.
   Shop badge top-centre, HUGE discount, title, bottom location bar.
   Photo fills entire background.
   ════════════════════════════════════════════════════════════ */

function shopBrandHero({ discount, title, shop, location, cta, palette }) {
  const d = escapeXml(discount);
  const t = escapeXml(truncate(title, 50));
  const s = escapeXml(truncate(shop, 26).toUpperCase());
  const l = escapeXml(truncate(location, 40));
  const { primary, accent, textColor } = palette;

  const badgeW = Math.max(220, s.length * 18 + 50);
  const badgeX = (1080 - badgeW) / 2;

  return `<svg xmlns="http://www.w3.org/2000/svg" width="1080" height="540">
  <defs>${heavyShadow()}</defs>

  <!-- Shop name badge — top centre (prominent) -->
  <rect x="${badgeX}" y="20" width="${badgeW}" height="52" rx="26"
        fill="${primary}" opacity="0.92"/>
  <rect x="${badgeX + 3}" y="23" width="${badgeW - 6}" height="46" rx="23"
        fill="none" stroke="${accent}" stroke-width="2" opacity="0.8"/>
  <text x="540" y="53" text-anchor="middle" font-family="Arial,sans-serif"
        font-size="24" font-weight="900" letter-spacing="3"
        fill="${textColor}">${s}</text>

  <!-- HUGE discount -->
  <text x="540" y="200" text-anchor="middle" font-family="Arial,sans-serif"
        font-size="110" font-weight="900"
        fill="${textColor}" filter="url(#ds)">${d}</text>

  <!-- Title / description -->
  <text x="540" y="265" text-anchor="middle" font-family="Arial,sans-serif"
        font-size="34" font-weight="600"
        fill="${textColor}" filter="url(#dsLight)">${t}</text>

  <!-- Bottom bar: dark scrim + location + CTA -->
  <rect x="0" y="460" width="1080" height="80" fill="${primary}" opacity="0.88"/>
  <text x="50" y="510" font-family="Arial,sans-serif" font-size="24"
        font-weight="600" fill="${textColor}" opacity="0.95">@ ${l}</text>
  <rect x="830" y="475" width="210" height="50" rx="25" fill="${accent}"/>
  <text x="935" y="508" text-anchor="middle" font-family="Arial,sans-serif"
        font-size="22" font-weight="bold" fill="${textColor}">${escapeXml(cta)}</text>
</svg>`;
}

shopBrandHero.logoPosition = { x: 20, y: 470 };

/* ════════════════════════════════════════════════════════════
   TEMPLATE 2 — leftTextOverlay
   Men's Avenue "50% OFF" reference style.
   Text on left floating on photo, shop badge top-left,
   massive discount, subtitle, location at bottom.
   ════════════════════════════════════════════════════════════ */

function leftTextOverlay({ discount, title, shop, location, cta, palette }) {
  const d = escapeXml(discount);
  const t = escapeXml(truncate(title, 46));
  const s = escapeXml(truncate(shop, 24).toUpperCase());
  const l = escapeXml(truncate(location, 36));
  const { primary, accent, textColor } = palette;

  const badgeW = Math.max(200, s.length * 17 + 40);

  return `<svg xmlns="http://www.w3.org/2000/svg" width="1080" height="540">
  <defs>
    ${heavyShadow()}
    <!-- Soft left scrim for text readability — NOT a hard panel -->
    <linearGradient id="leftScrim" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0%"  stop-color="#000" stop-opacity="0.50"/>
      <stop offset="45%" stop-color="#000" stop-opacity="0.18"/>
      <stop offset="65%" stop-color="#000" stop-opacity="0"/>
    </linearGradient>
  </defs>

  <!-- Subtle dark scrim on left so white text is readable -->
  <rect x="0" y="0" width="1080" height="540" fill="url(#leftScrim)"/>

  <!-- Shop badge — top left -->
  <rect x="36" y="24" width="${badgeW}" height="48" rx="24"
        fill="${primary}" opacity="0.92"/>
  <rect x="${36 + 3}" y="27" width="${badgeW - 6}" height="42" rx="21"
        fill="none" stroke="${accent}" stroke-width="2" opacity="0.75"/>
  <text x="${36 + badgeW / 2}" y="55" text-anchor="middle"
        font-family="Arial,sans-serif" font-size="22" font-weight="900"
        letter-spacing="2.5" fill="${textColor}">${s}</text>

  <!-- MASSIVE discount -->
  <text x="50" y="200" font-family="Arial,sans-serif"
        font-size="108" font-weight="900"
        fill="${textColor}" filter="url(#ds)">${d}</text>

  <!-- Title / subtitle -->
  <text x="55" y="265" font-family="Arial,sans-serif"
        font-size="32" font-weight="600"
        fill="${textColor}" filter="url(#dsLight)">${t}</text>

  <!-- CTA button -->
  <rect x="50" y="310" width="200" height="50" rx="25" fill="${accent}"/>
  <text x="150" y="343" text-anchor="middle" font-family="Arial,sans-serif"
        font-size="21" font-weight="bold" fill="${textColor}">${escapeXml(cta)}</text>

  <!-- Bottom location bar -->
  <rect x="0" y="462" width="1080" height="78" fill="${primary}" opacity="0.85"/>
  <text x="540" y="510" text-anchor="middle" font-family="Arial,sans-serif"
        font-size="24" font-weight="700"
        fill="${textColor}">@ ${l}</text>
</svg>`;
}

leftTextOverlay.logoPosition = { x: 920, y: 24 };

/* ════════════════════════════════════════════════════════════
   TEMPLATE 3 — centreImpact
   Flipkart "Big Billion Days" — centred text floating on image.
   ════════════════════════════════════════════════════════════ */

function centreImpact({ discount, title, shop, location, cta, palette }) {
  const d = escapeXml(discount);
  const t = escapeXml(truncate(title, 50));
  const s = escapeXml(truncate(shop, 24).toUpperCase());
  const l = escapeXml(truncate(location, 36));
  const { primary, accent, textColor } = palette;

  const badgeW = Math.max(220, s.length * 18 + 50);
  const badgeX = (1080 - badgeW) / 2;

  return `<svg xmlns="http://www.w3.org/2000/svg" width="1080" height="540">
  <defs>
    ${heavyShadow()}
    <!-- Centre horizontal scrim band for text readability -->
    <linearGradient id="midScrim" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%"   stop-color="#000" stop-opacity="0"/>
      <stop offset="22%"  stop-color="#000" stop-opacity="0.35"/>
      <stop offset="50%"  stop-color="#000" stop-opacity="0.50"/>
      <stop offset="78%"  stop-color="#000" stop-opacity="0.35"/>
      <stop offset="100%" stop-color="#000" stop-opacity="0"/>
    </linearGradient>
  </defs>

  <rect x="0" y="0" width="1080" height="540" fill="url(#midScrim)"/>

  <!-- Shop badge — top centre -->
  <rect x="${badgeX}" y="18" width="${badgeW}" height="50" rx="25"
        fill="${primary}" opacity="0.92"/>
  <text x="540" y="50" text-anchor="middle" font-family="Arial,sans-serif"
        font-size="23" font-weight="900" letter-spacing="3"
        fill="${textColor}">${s}</text>

  <!-- HUGE centre discount -->
  <text x="540" y="260" text-anchor="middle" font-family="Arial,sans-serif"
        font-size="120" font-weight="900"
        fill="${textColor}" filter="url(#ds)">${d}</text>

  <!-- Title below -->
  <text x="540" y="320" text-anchor="middle" font-family="Arial,sans-serif"
        font-size="34" font-weight="600"
        fill="${textColor}" filter="url(#dsLight)">${t}</text>

  <!-- Bottom bar -->
  <rect x="0" y="462" width="1080" height="78" fill="${primary}" opacity="0.88"/>
  <text x="50" y="510" font-family="Arial,sans-serif" font-size="22"
        font-weight="600" fill="${textColor}">@ ${l}</text>
  <rect x="830" y="475" width="210" height="50" rx="25" fill="${accent}"/>
  <text x="935" y="508" text-anchor="middle" font-family="Arial,sans-serif"
        font-size="22" font-weight="bold" fill="${textColor}">${escapeXml(cta)}</text>
</svg>`;
}

centreImpact.logoPosition = { x: 20, y: 470 };

/* ════════════════════════════════════════════════════════════
   TEMPLATE 4 — topStripBanner
   Premium fashion — accent strip top, large text upper half,
   photo visible through entire canvas.
   ════════════════════════════════════════════════════════════ */

function topStripBanner({ discount, title, shop, location, cta, palette }) {
  const d = escapeXml(discount);
  const t = escapeXml(truncate(title, 46));
  const s = escapeXml(truncate(shop, 24).toUpperCase());
  const l = escapeXml(truncate(location, 36));
  const { primary, accent, textColor } = palette;

  const badgeW = Math.max(200, s.length * 17 + 40);

  return `<svg xmlns="http://www.w3.org/2000/svg" width="1080" height="540">
  <defs>
    ${heavyShadow()}
    <linearGradient id="topFade" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%"  stop-color="#000" stop-opacity="0.55"/>
      <stop offset="50%" stop-color="#000" stop-opacity="0.15"/>
      <stop offset="70%" stop-color="#000" stop-opacity="0"/>
    </linearGradient>
  </defs>

  <!-- Soft top scrim so text is readable over any photo -->
  <rect x="0" y="0" width="1080" height="540" fill="url(#topFade)"/>
  <!-- Accent strip -->
  <rect x="0" y="0" width="1080" height="6" fill="${accent}"/>

  <!-- Shop badge top-left -->
  <rect x="36" y="20" width="${badgeW}" height="46" rx="23"
        fill="${primary}" opacity="0.92"/>
  <text x="${36 + badgeW / 2}" y="50" text-anchor="middle"
        font-family="Arial,sans-serif" font-size="21" font-weight="900"
        letter-spacing="2.5" fill="${textColor}">${s}</text>

  <!-- Discount -->
  <text x="50" y="175" font-family="Arial,sans-serif"
        font-size="96" font-weight="900"
        fill="${textColor}" filter="url(#ds)">${d}</text>

  <!-- Title -->
  <text x="55" y="235" font-family="Arial,sans-serif"
        font-size="32" font-weight="600"
        fill="${textColor}" filter="url(#dsLight)">${t}</text>

  <!-- CTA -->
  <rect x="50" y="268" width="200" height="48" rx="24" fill="${accent}"/>
  <text x="150" y="299" text-anchor="middle" font-family="Arial,sans-serif"
        font-size="20" font-weight="bold" fill="${textColor}">${escapeXml(cta)}</text>

  <!-- Bottom location -->
  <rect x="0" y="462" width="1080" height="78" fill="${primary}" opacity="0.85"/>
  <text x="540" y="510" text-anchor="middle" font-family="Arial,sans-serif"
        font-size="24" font-weight="700" fill="${textColor}">@ ${l}</text>
</svg>`;
}

topStripBanner.logoPosition = { x: 950, y: 22 };

/* ════════════════════════════════════════════════════════════
   TEMPLATE 5 — bottomBarHero
   Full photo visible, all info packed in a bold bottom bar.
   ════════════════════════════════════════════════════════════ */

function bottomBarHero({ discount, title, shop, location, cta, palette }) {
  const d = escapeXml(discount);
  const t = escapeXml(truncate(title, 50));
  const s = escapeXml(truncate(shop, 22).toUpperCase());
  const l = escapeXml(truncate(location, 30));
  const { primary, accent, textColor } = palette;

  return `<svg xmlns="http://www.w3.org/2000/svg" width="1080" height="540">
  <defs>
    ${heavyShadow()}
    <linearGradient id="btmFade" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%"   stop-color="#000" stop-opacity="0"/>
      <stop offset="52%"  stop-color="#000" stop-opacity="0"/>
      <stop offset="76%"  stop-color="#000" stop-opacity="0.45"/>
      <stop offset="100%" stop-color="${primary}" stop-opacity="0.95"/>
    </linearGradient>
  </defs>

  <rect x="0" y="0" width="1080" height="540" fill="url(#btmFade)"/>

  <!-- Shop badge — top right -->
  <rect x="810" y="22" width="240" height="46" rx="23"
        fill="${primary}" opacity="0.92"/>
  <text x="930" y="52" text-anchor="middle"
        font-family="Arial,sans-serif" font-size="21" font-weight="900"
        letter-spacing="2" fill="${textColor}">${s}</text>

  <!-- Discount — bottom left, big -->
  <text x="50" y="420" font-family="Arial,sans-serif"
        font-size="80" font-weight="900"
        fill="${textColor}" filter="url(#ds)">${d}</text>

  <!-- Title -->
  <text x="50" y="468" font-family="Arial,sans-serif"
        font-size="28" font-weight="600"
        fill="${textColor}" filter="url(#dsLight)">${t}</text>

  <!-- Location -->
  <text x="50" y="520" font-family="Arial,sans-serif"
        font-size="20" font-weight="600"
        fill="${textColor}" opacity="0.85">@ ${l}</text>

  <!-- CTA -->
  <rect x="830" y="458" width="210" height="50" rx="25" fill="${accent}"/>
  <text x="935" y="491" text-anchor="middle" font-family="Arial,sans-serif"
        font-size="22" font-weight="bold" fill="${textColor}">${escapeXml(cta)}</text>
</svg>`;
}

bottomBarHero.logoPosition = { x: 20, y: 20 };

/* ════════════════════════════════════════════════════════════
   TEMPLATE 6 — cornerBadgeClassic
   Corner circle badge with discount + full photo visible.
   ════════════════════════════════════════════════════════════ */

function cornerBadgeClassic({ discount, title, shop, location, cta, palette }) {
  const d = escapeXml(discount);
  const t = escapeXml(truncate(title, 46));
  const s = escapeXml(truncate(shop, 22).toUpperCase());
  const l = escapeXml(truncate(location, 30));
  const { primary, accent, textColor } = palette;

  return `<svg xmlns="http://www.w3.org/2000/svg" width="1080" height="540">
  <defs>${heavyShadow()}</defs>

  <!-- Corner discount badge -->
  <circle cx="135" cy="135" r="115" fill="${primary}" opacity="0.93"/>
  <circle cx="135" cy="135" r="105" fill="none" stroke="${accent}"
          stroke-width="3" opacity="0.70"/>
  <text x="135" y="122" text-anchor="middle" font-family="Arial,sans-serif"
        font-size="46" font-weight="900"
        fill="${textColor}" filter="url(#ds)">${d}</text>
  <text x="135" y="162" text-anchor="middle" font-family="Arial,sans-serif"
        font-size="16" font-weight="700" letter-spacing="2"
        fill="${accent}">LIMITED DEAL</text>

  <!-- Title — centre, with heavy shadow for readability -->
  <text x="540" y="310" text-anchor="middle" font-family="Arial,sans-serif"
        font-size="44" font-weight="800"
        fill="${textColor}" filter="url(#ds)">${t}</text>

  <!-- Bottom bar: shop name + location + CTA -->
  <rect x="0" y="444" width="1080" height="96" fill="${primary}" opacity="0.90"/>
  <text x="50" y="486" font-family="Arial,sans-serif" font-size="25"
        font-weight="900" letter-spacing="2"
        fill="${textColor}">${s}</text>
  <text x="50" y="522" font-family="Arial,sans-serif" font-size="19"
        font-weight="600" fill="${textColor}" opacity="0.80">@ ${l}</text>

  <rect x="830" y="467" width="210" height="50" rx="25" fill="${accent}"/>
  <text x="935" y="500" text-anchor="middle" font-family="Arial,sans-serif"
        font-size="22" font-weight="bold" fill="${textColor}">${escapeXml(cta)}</text>
</svg>`;
}

cornerBadgeClassic.logoPosition = { x: 960, y: 22 };

/* ═══════════════════════════════════════════════
   Smart template selection
   ═══════════════════════════════════════════════ */

const ALL_TEMPLATES = [
  shopBrandHero,
  leftTextOverlay,
  centreImpact,
  topStripBanner,
  bottomBarHero,
  cornerBadgeClassic,
];

const CATEGORY_PREFERRED = {
  clothing: [leftTextOverlay, shopBrandHero],
  beauty_salon: [shopBrandHero, leftTextOverlay],
  jewelry: [shopBrandHero, centreImpact],
  restaurant: [bottomBarHero, shopBrandHero],
  grocery: [bottomBarHero, shopBrandHero],
  food_beverage: [bottomBarHero, shopBrandHero],
  electronics: [centreImpact, topStripBanner],
  gym_fitness: [topStripBanner, centreImpact],
  sports: [topStripBanner, centreImpact],
  retail: [leftTextOverlay, centreImpact],
};

function pickTemplate(data) {
  const cta = ctaText(data.category);
  const payload = { ...data, cta };

  // 1. Honour explicit preference
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

  // 2. High-impact discounts (>=50%) -> dramatic templates
  const bigDeal = typeof data.discountValue === "number" && data.discountValue >= 50;
  if (bigDeal) {
    const dramatic = [cornerBadgeClassic, centreImpact, shopBrandHero];
    const pick = dramatic[Math.floor(Math.random() * dramatic.length)];
    return {
      svg: pick(payload),
      templateName: pick.name,
      logoPosition: pick.logoPosition,
    };
  }

  // 3. Category-preferred
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
