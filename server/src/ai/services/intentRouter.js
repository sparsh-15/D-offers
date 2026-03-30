const { GoogleGenerativeAI } = require('@google/generative-ai');
const offerTools = require('../tools/offerTools');
const couponTools = require('../tools/couponTools');
const shopTools = require('../tools/shopTools');
const { BUSINESS_CATEGORY_LABELS } = require('../../config/businessCategories');
const { isValidPincodeFormat } = require('../../services/pincodeService');

// Keep this list in sync with the intents described in the prompt.
const INTENTS = {
  SEARCH_OFFERS: 'search_offers',
  LIST_USER_COUPONS: 'list_user_coupons',
  BEST_COUPONS_FOR_PLAN: 'best_coupons_for_plan',
  LIKE_OFFER: 'like_offer',
  UNLIKE_OFFER: 'unlike_offer',
  SEARCH_SHOPS_NEARBY: 'search_shops_nearby',
};

let classifierModel;
const CHAT_CONTEXT_TTL_MS = 10 * 60 * 1000;
const chatContextStore = new Map();

function getClassifierModel() {
  if (!process.env.GEMINI_API_KEY) {
    throw new Error('GEMINI_API_KEY is not configured in environment');
  }
  if (!classifierModel) {
    const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
    classifierModel = genAI.getGenerativeModel({
      model: 'gemini-2.5-flash',
    });
  }
  return classifierModel;
}

function safeJsonParse(text) {
  if (!text) return null;
  const start = text.indexOf('{');
  const end = text.lastIndexOf('}');
  if (start === -1 || end === -1 || end <= start) return null;
  try {
    return JSON.parse(text.slice(start, end + 1));
  } catch {
    return null;
  }
}

function hasMeaningfulValue(value) {
  return value !== undefined && value !== null && String(value).trim().length > 0;
}

function sanitizeText(value) {
  return String(value || '').trim();
}

function getUserContext(userId) {
  if (!userId) return null;
  const context = chatContextStore.get(userId);
  if (!context) return null;
  if (Date.now() - context.updatedAt > CHAT_CONTEXT_TTL_MS) {
    chatContextStore.delete(userId);
    return null;
  }
  return context;
}

function setUserContext(userId, next) {
  if (!userId) return;
  chatContextStore.set(userId, {
    ...next,
    updatedAt: Date.now(),
  });
}

function mergeParamsWithContext(params = {}, context = null) {
  if (!context || !context.params) {
    return { ...params };
  }

  const merged = { ...params };
  const previous = context.params;

  if (!hasMeaningfulValue(merged.category) && hasMeaningfulValue(previous.category)) {
    merged.category = previous.category;
  }
  if (!hasMeaningfulValue(merged.pincode) && hasMeaningfulValue(previous.pincode)) {
    merged.pincode = previous.pincode;
  }
  if (!hasMeaningfulValue(merged.city) && hasMeaningfulValue(previous.city)) {
    merged.city = previous.city;
  }
  if (!hasMeaningfulValue(merged.state) && hasMeaningfulValue(previous.state)) {
    merged.state = previous.state;
  }

  return merged;
}

function normalizeSearchParams(params = {}) {
  const normalized = { ...params };

  if (hasMeaningfulValue(normalized.pincode)) {
    normalized.pincode = sanitizeText(normalized.pincode).replace(/\D/g, '');
    if (!isValidPincodeFormat(normalized.pincode)) {
      normalized._validationError = {
        field: 'pincode',
        message: 'Please provide a valid 6-digit pincode.',
      };
      delete normalized.pincode;
    }
  }

  if (hasMeaningfulValue(normalized.city)) {
    normalized.city = sanitizeText(normalized.city);
  }

  if (hasMeaningfulValue(normalized.state)) {
    normalized.state = sanitizeText(normalized.state);
  }

  if (hasMeaningfulValue(normalized.category)) {
    const categoryMatch = offerTools.normalizeCategoryInput(normalized.category);
    if (categoryMatch.valid) {
      normalized.category = categoryMatch.category;
    } else {
      normalized._validationError = {
        field: 'category',
        message: 'Please choose a valid category from suggestions.',
      };
      delete normalized.category;
    }
  }

  return normalized;
}

function buildClarifyQuestions(params = {}) {
  const questions = [];
  const hasCategory = hasMeaningfulValue(params.category);
  const hasLocation =
    hasMeaningfulValue(params.pincode) ||
    hasMeaningfulValue(params.city) ||
    hasMeaningfulValue(params.state);

  if (!hasCategory) {
    questions.push('Which category should I search in?');
  }
  if (!hasLocation) {
    questions.push('Share your pincode or city so I can find nearby deals.');
  }
  if (!hasMeaningfulValue(params.minDiscount)) {
    questions.push('Any minimum discount preference?');
  }

  return questions.slice(0, 2);
}

async function buildClarifyActions() {
  const categories = await offerTools.getActiveOfferCategories({ limit: 4 });
  const categoryActions = categories.map((category) => ({
    label: `${BUSINESS_CATEGORY_LABELS[category] || category} offers`,
    type: 'ask_followup',
    message: `Show me ${BUSINESS_CATEGORY_LABELS[category] || category} offers.`,
  }));

  return [
    ...categoryActions,
    {
      label: 'Nearby offers by pincode',
      type: 'ask_followup',
      message: 'Show me nearby offers for my pincode 560001.',
    },
    {
      label: 'High discount offers',
      type: 'ask_followup',
      message: 'Show me offers with at least 30% discount.',
    },
  ].slice(0, 4);
}

function shouldClarifyBeforeOfferSearch(params = {}) {
  const hasQuery = hasMeaningfulValue(params.query);
  const hasCategory = hasMeaningfulValue(params.category);
  const hasLocation =
    hasMeaningfulValue(params.pincode) ||
    hasMeaningfulValue(params.city) ||
    hasMeaningfulValue(params.state);
  const hasMinDiscount = hasMeaningfulValue(params.minDiscount);

  // If user asked very broadly (no category/location/query/discount), ask clarifying questions first.
  return !hasQuery && !hasCategory && !hasLocation && !hasMinDiscount;
}

async function classifyIntent(message) {
  const model = getClassifierModel();
  const canonicalCategories = Object.keys(BUSINESS_CATEGORY_LABELS)
    .map((key) => `${key} (${BUSINESS_CATEGORY_LABELS[key]})`)
    .join(', ');

  const prompt = [
    'You are an intent classifier for the D\'Offer mobile app assistant.',
    'Your job is ONLY to output a single JSON object describing the intent and parameters.',
    'Supported intents:',
    `- ${INTENTS.SEARCH_OFFERS}: user wants to browse or search offers or deals.`,
    `- ${INTENTS.LIST_USER_COUPONS}: user wants to see available coupons or coupon list.`,
    `- ${INTENTS.BEST_COUPONS_FOR_PLAN}: user asks for best coupon for a subscription or plan.`,
    `- ${INTENTS.LIKE_OFFER}: user wants to like/favorite a specific offer.`,
    `- ${INTENTS.UNLIKE_OFFER}: user wants to remove like from a specific offer.`,
    `- ${INTENTS.SEARCH_SHOPS_NEARBY}: user wants to find shops near them (by pincode/city/state) that are on MyOffers.`,
    '',
    'Schema (JSON):',
    '{',
    '  "intent": "<one of the supported intent ids>",',
    '  "params": {',
    '    // key-value parameters extracted from the user message',
    '  }',
    '}',
    '',
    'Rules:',
    '- Always choose the most specific intent.',
    '- If location is mentioned (pincode, city, state), put it in params.',
    '- For SEARCH_OFFERS, useful params: query, category, pincode, city, state, minDiscount.',
    `- Canonical categories: ${canonicalCategories}`,
    '- If user says a natural category (for example food, dining, fashion), still map to closest canonical category in params.category.',
    '- If pincode is provided, pass digits only in params.pincode.',
    '- For SEARCH_SHOPS_NEARBY, useful params: pincode, city, state, limit.',
    '- For LIST_USER_COUPONS, params can be empty.',
    '- For BEST_COUPONS_FOR_PLAN, params: planId (if mentioned), planName (if textual), limit.',
    '- For LIKE_OFFER / UNLIKE_OFFER, include offerId if it is clearly specified in the message.',
    '- If the user clearly asks for shops or stores near them, prefer SEARCH_SHOPS_NEARBY.',
    '- If you are unsure between SEARCH_OFFERS and LIST_USER_COUPONS, prefer SEARCH_OFFERS.',
    '',
    'User message:',
    message,
    '',
    'Now respond with ONLY the JSON object and nothing else.',
  ].join('\n');

  const result = await model.generateContent([prompt]);
  const rawText =
    (result.response && typeof result.response.text === 'function'
      ? result.response.text()
      : null) || '';

  const parsed = safeJsonParse(rawText);
  if (!parsed || !parsed.intent) {
    return {
      intent: INTENTS.SEARCH_OFFERS,
      params: { query: message },
    };
  }

  return {
    intent: String(parsed.intent),
    params: parsed.params || {},
  };
}

async function handleIntent({ user, intent, params }) {
  switch (intent) {
    case INTENTS.SEARCH_SHOPS_NEARBY: {
      const toolResult = await shopTools.searchShopsNearby({ params });
      const actions = [
        {
          label: 'Browse nearby offers',
          type: 'open_offers_tab',
        },
      ];
      return {
        intent,
        params,
        toolResult,
        actions,
        items: { shops: toolResult.shops || [] },
      };
    }
    case INTENTS.SEARCH_OFFERS: {
      if (params?._validationError || shouldClarifyBeforeOfferSearch(params)) {
        const actions = await buildClarifyActions();
        const suggestedQuestions = buildClarifyQuestions(params);
        if (params?._validationError?.message) {
          suggestedQuestions.unshift(params._validationError.message);
        }
        return {
          intent,
          params,
          toolResult: {
            mode: 'clarify',
            reason: params?._validationError ? 'invalid_params' : 'broad_search',
            suggestedQuestions,
          },
          actions,
          items: {},
        };
      }

      const toolResult = await offerTools.searchOffers({ user, params });
      const actions =
        (toolResult.offers || []).slice(0, 3).map((offer) => ({
          label: `View ${offer.title || 'offer'}`,
          type: 'open_offer',
          offerId: offer.id,
        }));
      return {
        intent,
        params,
        toolResult,
        actions,
        items: { offers: toolResult.offers || [] },
      };
    }
    case INTENTS.LIST_USER_COUPONS: {
      const toolResult = await couponTools.getUserCoupons();
      const actions = [
        {
          label: 'Open Coupons',
          type: 'open_coupons_tab',
        },
      ];
      return {
        intent,
        params,
        toolResult,
        actions,
        items: { coupons: toolResult.coupons || [] },
      };
    }
    case INTENTS.BEST_COUPONS_FOR_PLAN: {
      const toolResult = await couponTools.getBestCouponsForPlan({ params });
      const actions = [
        {
          label: 'Open Coupons',
          type: 'open_coupons_tab',
        },
      ];
      return {
        intent,
        params,
        toolResult,
        actions,
        items: { coupons: toolResult.coupons || [] },
      };
    }
    case INTENTS.LIKE_OFFER: {
      const toolResult = await offerTools.likeOffer({ user, params });
      const actions = [
        {
          label: 'View offer',
          type: 'open_offer',
          offerId: toolResult.offerId,
        },
      ];
      return {
        intent,
        params,
        toolResult,
        actions,
        items: {},
      };
    }
    case INTENTS.UNLIKE_OFFER: {
      const toolResult = await offerTools.unlikeOffer({ user, params });
      const actions = [
        {
          label: 'View offer',
          type: 'open_offer',
          offerId: toolResult.offerId,
        },
      ];
      return {
        intent,
        params,
        toolResult,
        actions,
        items: {},
      };
    }
    default: {
      // Fallback to a generic search intent
      const toolResult = await offerTools.searchOffers({
        user,
        params: { query: params?.query || '' },
      });
      const actions =
        (toolResult.offers || []).slice(0, 3).map((offer) => ({
          label: `View ${offer.title || 'offer'}`,
          type: 'open_offer',
          offerId: offer.id,
        }));
      return {
        intent: INTENTS.SEARCH_OFFERS,
        params,
        toolResult,
        actions,
        items: { offers: toolResult.offers || [] },
      };
    }
  }
}

/**
 * Main entry point used by the AI controller.
 * - Classifies the user message into an intent + params.
 * - Executes the appropriate tool.
 * - Returns structured data for the answer and UI actions.
 */
async function routeIntent({ user, message }) {
  const classification = await classifyIntent(message);
  const context = getUserContext(user?.userId);
  const mergedParams = mergeParamsWithContext(classification.params, context);
  const normalizedParams = normalizeSearchParams(mergedParams);

  const handled = await handleIntent({
    user,
    intent: classification.intent,
    params: normalizedParams,
  });

  if (classification.intent === INTENTS.SEARCH_OFFERS) {
    const hasUsefulContext =
      hasMeaningfulValue(normalizedParams.category) ||
      hasMeaningfulValue(normalizedParams.pincode) ||
      hasMeaningfulValue(normalizedParams.city) ||
      hasMeaningfulValue(normalizedParams.state);

    if (hasUsefulContext) {
    setUserContext(user?.userId, {
      intent: classification.intent,
      params: {
        category: normalizedParams.category,
        pincode: normalizedParams.pincode,
        city: normalizedParams.city,
        state: normalizedParams.state,
      },
    });
    }
  }

  return handled;
}

module.exports = {
  INTENTS,
  routeIntent,
};

