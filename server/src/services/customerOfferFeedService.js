const { Prisma } = require('@prisma/client');
const { prisma } = require('../db/prisma');

function ci(value) {
  return String(value || '').trim();
}

function base64UrlEncode(input) {
  return Buffer.from(input, 'utf8')
    .toString('base64')
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');
}

function base64UrlDecode(input) {
  const padded = String(input || '').replace(/-/g, '+').replace(/_/g, '/');
  const padLen = padded.length % 4 === 0 ? 0 : 4 - (padded.length % 4);
  const withPad = padded + '='.repeat(padLen);
  return Buffer.from(withPad, 'base64').toString('utf8');
}

function encodeCursor(obj) {
  return base64UrlEncode(JSON.stringify(obj));
}

function decodeCursor(cursor) {
  if (!cursor) return null;
  try {
    return JSON.parse(base64UrlDecode(cursor));
  } catch (_) {
    return null;
  }
}

function normalizeSort(sort) {
  const s = ci(sort).toLowerCase();
  if (!s) return 'newest';
  if (
    s === 'newest' ||
    s === 'most_liked' ||
    s === 'discount_high_to_low' ||
    s === 'discount_low_to_high'
  ) {
    return s;
  }
  return 'newest';
}

function isTruthyFeaturedSegment(segment) {
  const s = ci(segment).toLowerCase();
  return s === 'featured' || s === 'true' || s === '1';
}

async function hasAnyShopkeeperMatchingLocation({ pincode, city, state }) {
  const p = ci(pincode);
  const c = ci(city);
  const st = ci(state);
  if (!p && !c && !st) return true;

  const where = {
    role: 'shopkeeper',
    isActive: true,
    approvalStatus: { not: 'rejected' },
  };
  if (p) where.pincode = p;
  if (c) where.city = { equals: c, mode: 'insensitive' };
  if (st) where.state = { equals: st, mode: 'insensitive' };

  const count = await prisma.user.count({ where });
  return count > 0;
}

function buildOrderBySql({ sort, featuredSegment }) {
  if (featuredSegment) {
    // tierScore desc, likes desc, created desc, id desc
    return Prisma.sql`
      tier_score DESC,
      o.likes_count DESC,
      o.created_at DESC,
      o.id DESC
    `;
  }

  switch (sort) {
    case 'most_liked':
      return Prisma.sql`o.likes_count DESC, o.created_at DESC, o.id DESC`;
    case 'discount_high_to_low':
      return Prisma.sql`o.discount_value DESC NULLS LAST, o.created_at DESC, o.id DESC`;
    case 'discount_low_to_high':
      return Prisma.sql`o.discount_value ASC NULLS LAST, o.created_at DESC, o.id DESC`;
    case 'newest':
    default:
      return Prisma.sql`o.created_at DESC, o.id DESC`;
  }
}

function buildCursorWhereSql({ sort, featuredSegment, cursorObj }) {
  if (!cursorObj) return Prisma.sql``;

  // Validate cursor shape lightly; if invalid, ignore cursor.
  if (featuredSegment) {
    const tierScore = Number(cursorObj.tierScore);
    const likesCount = Number(cursorObj.likesCount);
    const createdAt = ci(cursorObj.createdAt);
    const id = ci(cursorObj.id);
    if (!Number.isFinite(tierScore) || !Number.isFinite(likesCount) || !createdAt || !id) {
      return Prisma.sql``;
    }
    return Prisma.sql`
      AND (
        CASE COALESCE(ls.ranking_tier, 'normal')
          WHEN 'top3' THEN 3
          WHEN 'priority' THEN 2
          ELSE 1
        END < ${tierScore}
        OR (
          CASE COALESCE(ls.ranking_tier, 'normal')
            WHEN 'top3' THEN 3
            WHEN 'priority' THEN 2
            ELSE 1
          END = ${tierScore}
          AND o.likes_count < ${likesCount}
        )
        OR (
          CASE COALESCE(ls.ranking_tier, 'normal')
            WHEN 'top3' THEN 3
            WHEN 'priority' THEN 2
            ELSE 1
          END = ${tierScore}
          AND o.likes_count = ${likesCount}
          AND o.created_at < ${new Date(createdAt)}
        )
        OR (
          CASE COALESCE(ls.ranking_tier, 'normal')
            WHEN 'top3' THEN 3
            WHEN 'priority' THEN 2
            ELSE 1
          END = ${tierScore}
          AND o.likes_count = ${likesCount}
          AND o.created_at = ${new Date(createdAt)}
          AND o.id < ${id}::uuid
        )
      )
    `;
  }

  switch (sort) {
    case 'most_liked': {
      const likesCount = Number(cursorObj.likesCount);
      const createdAt = ci(cursorObj.createdAt);
      const id = ci(cursorObj.id);
      if (!Number.isFinite(likesCount) || !createdAt || !id) return Prisma.sql``;
      return Prisma.sql`
        AND (
          o.likes_count < ${likesCount}
          OR (o.likes_count = ${likesCount} AND o.created_at < ${new Date(createdAt)})
          OR (o.likes_count = ${likesCount} AND o.created_at = ${new Date(createdAt)} AND o.id < ${id}::uuid)
        )
      `;
    }
    case 'discount_high_to_low': {
      const createdAt = ci(cursorObj.createdAt);
      const id = ci(cursorObj.id);
      const rawDiscount = cursorObj.discountValue;
      if (!createdAt || !id) return Prisma.sql``;
      if (rawDiscount === null || rawDiscount === undefined || rawDiscount === '') {
        return Prisma.sql`
          AND (
            o.discount_value IS NULL
            AND (
              o.created_at < ${new Date(createdAt)}
              OR (o.created_at = ${new Date(createdAt)} AND o.id < ${id}::uuid)
            )
          )
        `;
      }
      const discountValue = Number(rawDiscount);
      if (!Number.isFinite(discountValue)) return Prisma.sql``;
      return Prisma.sql`
        AND (
          o.discount_value IS NULL
          OR o.discount_value < ${discountValue}::numeric
          OR (o.discount_value = ${discountValue}::numeric AND o.created_at < ${new Date(createdAt)})
          OR (o.discount_value = ${discountValue}::numeric AND o.created_at = ${new Date(createdAt)} AND o.id < ${id}::uuid)
        )
      `;
    }
    case 'discount_low_to_high': {
      const createdAt = ci(cursorObj.createdAt);
      const id = ci(cursorObj.id);
      const rawDiscount = cursorObj.discountValue;
      if (!createdAt || !id) return Prisma.sql``;
      if (rawDiscount === null || rawDiscount === undefined || rawDiscount === '') {
        return Prisma.sql`
          AND (
            o.discount_value IS NULL
            AND (
              o.created_at < ${new Date(createdAt)}
              OR (o.created_at = ${new Date(createdAt)} AND o.id < ${id}::uuid)
            )
          )
        `;
      }
      const discountValue = Number(rawDiscount);
      if (!Number.isFinite(discountValue)) return Prisma.sql``;
      return Prisma.sql`
        AND (
          o.discount_value IS NULL
          OR o.discount_value > ${discountValue}::numeric
          OR (o.discount_value = ${discountValue}::numeric AND o.created_at < ${new Date(createdAt)})
          OR (o.discount_value = ${discountValue}::numeric AND o.created_at = ${new Date(createdAt)} AND o.id < ${id}::uuid)
        )
      `;
    }
    case 'newest':
    default: {
      const createdAt = ci(cursorObj.createdAt);
      const id = ci(cursorObj.id);
      if (!createdAt || !id) return Prisma.sql``;
      return Prisma.sql`
        AND (
          o.created_at < ${new Date(createdAt)}
          OR (o.created_at = ${new Date(createdAt)} AND o.id < ${id}::uuid)
        )
      `;
    }
  }
}

async function listCustomerOffersFeed({
  userId,
  status,
  limit,
  skip,
  pincode,
  city,
  state,
  q,
  category,
  sort,
  segment,
  cursor,
}) {
  const limitNum = Math.min(Math.max(parseInt(limit, 10) || 100, 1), 200);
  const skipNum = Math.max(parseInt(skip, 10) || 0, 0);

  const featuredSegment = isTruthyFeaturedSegment(segment);
  const normalizedSort = normalizeSort(sort);
  const cursorObj = decodeCursor(cursor);

  // Location fallback behavior (match existing controller):
  // If location filters are provided but no shopkeepers match, ignore location filters.
  const hasLocationInput = !!ci(pincode) || !!ci(city) || !!ci(state);
  const locationIsUsable = !hasLocationInput
    ? true
    : await hasAnyShopkeeperMatchingLocation({ pincode, city, state });

  const where = [];
  where.push(Prisma.sql`u.role = 'shopkeeper'::role_enum`);
  where.push(Prisma.sql`u.is_active = true`);
  where.push(Prisma.sql`u.approval_status <> 'rejected'::approval_status_enum`);

  const statusCi = ci(status);
  if (statusCi) where.push(Prisma.sql`o.status = ${statusCi}::offer_status_enum`);

  if (locationIsUsable) {
    const p = ci(pincode);
    const c = ci(city);
    const st = ci(state);
    if (p) where.push(Prisma.sql`u.pincode = ${p}`);
    if (c) where.push(Prisma.sql`u.city ILIKE ${c}`);
    if (st) where.push(Prisma.sql`u.state ILIKE ${st}`);
  }

  const categoryCi = ci(category);
  if (categoryCi) where.push(Prisma.sql`o.category ILIKE ${categoryCi}`);

  const qCi = ci(q);
  if (qCi) {
    const like = `%${qCi.replace(/%/g, '\\%').replace(/_/g, '\\_')}%`;
    where.push(Prisma.sql`
      (
        o.title ILIKE ${like} ESCAPE '\\'
        OR COALESCE(o.description, '') ILIKE ${like} ESCAPE '\\'
        OR COALESCE(o.category, '') ILIKE ${like} ESCAPE '\\'
        OR COALESCE(p.shop_name, '') ILIKE ${like} ESCAPE '\\'
      )
    `);
  }

  if (featuredSegment) {
    where.push(Prisma.sql`COALESCE(ls.ranking_tier, 'normal') IN ('top3', 'priority')`);
  }

  const orderBySql = buildOrderBySql({ sort: normalizedSort, featuredSegment });
  const cursorSql = buildCursorWhereSql({ sort: normalizedSort, featuredSegment, cursorObj });

  const query = Prisma.sql`
    WITH latest_sub AS (
      SELECT DISTINCT ON (s.shopkeeper_id)
        s.shopkeeper_id,
        (s.plan_snapshot->>'rankingTier') AS ranking_tier
      FROM subscriptions s
      WHERE s.status = 'active'::subscription_status_enum
      ORDER BY s.shopkeeper_id, s.created_at DESC
    )
    SELECT
      o.id,
      o.shopkeeper_id AS "shopkeeperId",
      COALESCE(p.shop_name, 'Shop') AS "shopName",
      o.title,
      COALESCE(o.description, '') AS description,
      COALESCE(o.photos, ARRAY[]::text[]) AS photos,
      COALESCE(o.terms_and_conditions, '') AS "termsAndConditions",
      COALESCE(o.category, '') AS category,
      o.discount_type AS "discountType",
      o.discount_value AS "discountValue",
      o.valid_from AS "validFrom",
      o.valid_to AS "validTo",
      o.status,
      o.likes_count AS "likesCount",
      (ol.offer_id IS NOT NULL) AS "isLiked",
      o.created_at AS "createdAt",
      o.updated_at AS "updatedAt",
      COALESCE(ls.ranking_tier, 'normal') AS "shopRankingTier",
      CASE COALESCE(ls.ranking_tier, 'normal')
        WHEN 'top3' THEN 3
        WHEN 'priority' THEN 2
        ELSE 1
      END AS tier_score
    FROM offers o
    JOIN users u ON u.id = o.shopkeeper_id
    LEFT JOIN shopkeeper_profiles p ON p.user_id = o.shopkeeper_id
    LEFT JOIN latest_sub ls ON ls.shopkeeper_id = o.shopkeeper_id
    LEFT JOIN offer_likes ol
      ON ol.offer_id = o.id
      AND ol.user_id = ${userId}::uuid
    WHERE ${Prisma.join(where, Prisma.sql` AND `)}
    ${cursorSql}
    ORDER BY ${orderBySql}
    OFFSET ${cursorObj ? 0 : skipNum}
    LIMIT ${limitNum + 1}
  `;

  // Uncomment for debugging the generated SQL if needed:
  // console.log('CUSTOMER_FEED_SQL\n', query.sql, '\nVALUES:', query.values);

  const rows = await prisma.$queryRaw(query);

  const hasMore = rows.length > limitNum;
  const pageRows = hasMore ? rows.slice(0, limitNum) : rows;

  const offers = pageRows.map((r) => ({
    id: r.id,
    shopkeeperId: r.shopkeeperId,
    shopName: r.shopName || null,
    title: r.title || '',
    description: r.description || '',
    photos: Array.isArray(r.photos) ? r.photos : [],
    termsAndConditions: r.termsAndConditions || '',
    category: r.category || '',
    discountType: r.discountType || '',
    discountValue: r.discountValue,
    validFrom: r.validFrom ? new Date(r.validFrom).toISOString() : null,
    validTo: r.validTo ? new Date(r.validTo).toISOString() : null,
    status: r.status || 'active',
    likesCount: Number(r.likesCount || 0),
    isLiked: !!r.isLiked,
    createdAt: r.createdAt ? new Date(r.createdAt).toISOString() : null,
    updatedAt: r.updatedAt ? new Date(r.updatedAt).toISOString() : null,
    shopRankingTier: r.shopRankingTier || 'normal',
    isFeatured: r.shopRankingTier === 'top3' || r.shopRankingTier === 'priority',
  }));

  let nextCursor = null;
  if (hasMore && pageRows.length) {
    const last = pageRows[pageRows.length - 1];
    if (featuredSegment) {
      nextCursor = encodeCursor({
        segment: 'featured',
        tierScore: Number(last.tier_score || 1),
        likesCount: Number(last.likesCount || 0),
        createdAt: new Date(last.createdAt).toISOString(),
        id: last.id,
      });
    } else if (normalizedSort === 'most_liked') {
      nextCursor = encodeCursor({
        sort: 'most_liked',
        likesCount: Number(last.likesCount || 0),
        createdAt: new Date(last.createdAt).toISOString(),
        id: last.id,
      });
    } else if (
      normalizedSort === 'discount_high_to_low' ||
      normalizedSort === 'discount_low_to_high'
    ) {
      nextCursor = encodeCursor({
        sort: normalizedSort,
        discountValue: last.discountValue === undefined ? null : last.discountValue,
        createdAt: new Date(last.createdAt).toISOString(),
        id: last.id,
      });
    } else {
      nextCursor = encodeCursor({
        sort: 'newest',
        createdAt: new Date(last.createdAt).toISOString(),
        id: last.id,
      });
    }
  }

  return {
    offers,
    pageInfo: {
      hasMore,
      nextCursor,
      limit: limitNum,
    },
  };
}

module.exports = {
  listCustomerOffersFeed,
  encodeCursor,
  decodeCursor,
};

