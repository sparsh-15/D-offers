const UUID_REGEX =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

function isUuid(value) {
  return typeof value === 'string' && UUID_REGEX.test(value);
}

async function resolvePgId(collectionName, id) {
  void collectionName;
  if (!id) return null;
  const asString = String(id);
  if (isUuid(asString)) return asString;
  return null;
}

module.exports = {
  isUuid,
  resolvePgId,
};
