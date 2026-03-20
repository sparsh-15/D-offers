const crypto = require('crypto');

const FREE_STARTER_PLAN_NAME = 'free_starter_all';
const FREE_INBOX_MESSAGE_LIMIT = 20;
const FREE_AI_BANNER_LIMIT = 1;
const FREE_MAX_ACTIVE_OFFERS = 1;
const FREE_WHATSAPP_LIMIT = 0;

const TRIAL_DURATION_DAYS = 7;
const TRIAL_DEFAULT_WHATSAPP_CAP = 75;

const TICKET_BAND_CAPS = {
  very_high: 100,
  high: 75,
  medium: 60,
  low: 50,
};

const CATEGORY_TICKET_BANDS = {
  jewelry: 'very_high',
  automotive: 'very_high',

  electronics: 'high',
  home_services: 'high',

  retail: 'medium',
  restaurant: 'medium',
  beauty_salon: 'medium',
  gym_fitness: 'medium',
  healthcare: 'medium',
  clothing: 'medium',

  grocery: 'low',
  pharmacy: 'low',
  books_stationery: 'low',
  pet_care: 'low',
};

function ci(value) {
  return String(value || '').trim().toLowerCase();
}

function normalizeBusinessFingerprint(shopName, address) {
  return `${ci(shopName)}|${ci(address)}`;
}

function hashFingerprint(fingerprint) {
  return crypto.createHash('sha256').update(String(fingerprint || '')).digest('hex');
}

function getTrialCapBandForCategory(category) {
  const normalized = ci(category);
  return CATEGORY_TICKET_BANDS[normalized] || 'medium';
}

function getDefaultTrialWhatsappCap(category) {
  const band = getTrialCapBandForCategory(category);
  return TICKET_BAND_CAPS[band] || TRIAL_DEFAULT_WHATSAPP_CAP;
}

function isTrialSubscription(subscription) {
  if (!subscription) return false;
  if (subscription.planSnapshot?.isTrial === true) return true;
  return ci(subscription.notes).includes('trial');
}

function isFreeStarterSnapshot(planSnapshot) {
  if (!planSnapshot) return false;
  if (ci(planSnapshot.name) === FREE_STARTER_PLAN_NAME) return true;
  return ci(planSnapshot.tier) === 'free';
}

function getTrialGuardKey(phone, fingerprintHash) {
  return `trial_guard:${ci(phone)}:${ci(fingerprintHash)}`;
}

module.exports = {
  FREE_STARTER_PLAN_NAME,
  FREE_INBOX_MESSAGE_LIMIT,
  FREE_AI_BANNER_LIMIT,
  FREE_MAX_ACTIVE_OFFERS,
  FREE_WHATSAPP_LIMIT,
  TRIAL_DURATION_DAYS,
  TRIAL_DEFAULT_WHATSAPP_CAP,
  TICKET_BAND_CAPS,
  CATEGORY_TICKET_BANDS,
  normalizeBusinessFingerprint,
  hashFingerprint,
  getDefaultTrialWhatsappCap,
  isTrialSubscription,
  isFreeStarterSnapshot,
  getTrialGuardKey,
};
