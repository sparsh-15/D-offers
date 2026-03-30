const PINCODE_REGEX = /^\d{6}$/;
const PINCODE_CACHE_TTL_MS = 24 * 60 * 60 * 1000;
const pincodeCache = new Map();

function normalizePincode(pincode) {
  if (pincode == null) return '';
  return String(pincode).trim();
}

function isValidPincodeFormat(pincode) {
  return PINCODE_REGEX.test(normalizePincode(pincode));
}

function getCachedPincode(pincode) {
  const cached = pincodeCache.get(pincode);
  if (!cached) return null;
  if (Date.now() - cached.updatedAt > PINCODE_CACHE_TTL_MS) {
    pincodeCache.delete(pincode);
    return null;
  }
  return cached.value;
}

function setCachedPincode(pincode, value) {
  pincodeCache.set(pincode, {
    value,
    updatedAt: Date.now(),
  });
}

async function lookupIndiaPost(pincode) {
  const cached = getCachedPincode(pincode);
  if (cached) {
    return cached;
  }

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 5000);
  try {
    const res = await fetch(`https://api.postalpincode.in/pincode/${encodeURIComponent(pincode)}`, {
      signal: controller.signal,
      headers: { 'accept': 'application/json' },
    });
    if (!res.ok) return null;
    const data = await res.json();
    // Expected shape: [{ Status: "Success", PostOffice: [{ District, State, Name, Block, ...}] }]
    const first = Array.isArray(data) ? data[0] : null;
    if (!first || first.Status !== 'Success' || !Array.isArray(first.PostOffice) || first.PostOffice.length === 0) {
      return null;
    }

    // Get state from first post office
    const state = first.PostOffice[0].State || '';

    // Get all unique areas/cities from all post offices
    const areas = first.PostOffice.map(po => {
      // Prefer Name (area name), then Block, then District
      return {
        name: po.Name || po.Block || po.District || '',
        district: po.District || '',
        block: po.Block || '',
      };
    }).filter(area => area.name); // Remove empty names

    // Remove duplicates based on name
    const uniqueAreas = Array.from(
      new Map(areas.map(area => [area.name, area])).values()
    );

    const resolved = {
      state,
      areas: uniqueAreas,
      district: first.PostOffice[0].District || ''
    };
    setCachedPincode(pincode, resolved);
    return resolved;
  } catch (e) {
    // Return stale cache if network fails during lookup.
    return getCachedPincode(pincode);
  } finally {
    clearTimeout(timeout);
  }
}

async function resolveCityStateFromPincode(pincode) {
  const normalized = normalizePincode(pincode);
  if (!isValidPincodeFormat(normalized)) {
    const err = new Error('Invalid pincode');
    err.statusCode = 400;
    throw err;
  }
  const result = await lookupIndiaPost(normalized);
  if (!result) {
    const err = new Error('Unable to resolve city/state from pincode');
    err.statusCode = 400;
    throw err;
  }
  return {
    pincode: normalized,
    state: result.state,
    district: result.district,
    areas: result.areas
  };
}

module.exports = {
  resolveCityStateFromPincode,
  isValidPincodeFormat,
  normalizePincode,
};

