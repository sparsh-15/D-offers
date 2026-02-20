// Business category enums for shopkeeper profiles and subscription plans

const BUSINESS_CATEGORIES = {
  RETAIL: 'retail',
  RESTAURANT: 'restaurant',
  GROCERY: 'grocery',
  PHARMACY: 'pharmacy',
  ELECTRONICS: 'electronics',
  CLOTHING: 'clothing',
  BEAUTY_SALON: 'beauty_salon',
  GYM_FITNESS: 'gym_fitness',
  EDUCATION: 'education',
  HEALTHCARE: 'healthcare',
  AUTOMOTIVE: 'automotive',
  HOME_SERVICES: 'home_services',
  ENTERTAINMENT: 'entertainment',
  FOOD_BEVERAGE: 'food_beverage',
  JEWELRY: 'jewelry',
  BOOKS_STATIONERY: 'books_stationery',
  SPORTS: 'sports',
  PET_CARE: 'pet_care',
  TRAVEL: 'travel',
  OTHER: 'other',
};

const BUSINESS_CATEGORY_LABELS = {
  [BUSINESS_CATEGORIES.RETAIL]: 'Retail Store',
  [BUSINESS_CATEGORIES.RESTAURANT]: 'Restaurant',
  [BUSINESS_CATEGORIES.GROCERY]: 'Grocery Store',
  [BUSINESS_CATEGORIES.PHARMACY]: 'Pharmacy',
  [BUSINESS_CATEGORIES.ELECTRONICS]: 'Electronics',
  [BUSINESS_CATEGORIES.CLOTHING]: 'Clothing & Fashion',
  [BUSINESS_CATEGORIES.BEAUTY_SALON]: 'Beauty Salon & Spa',
  [BUSINESS_CATEGORIES.GYM_FITNESS]: 'Gym & Fitness',
  [BUSINESS_CATEGORIES.EDUCATION]: 'Education & Training',
  [BUSINESS_CATEGORIES.HEALTHCARE]: 'Healthcare',
  [BUSINESS_CATEGORIES.AUTOMOTIVE]: 'Automotive',
  [BUSINESS_CATEGORIES.HOME_SERVICES]: 'Home Services',
  [BUSINESS_CATEGORIES.ENTERTAINMENT]: 'Entertainment',
  [BUSINESS_CATEGORIES.FOOD_BEVERAGE]: 'Food & Beverage',
  [BUSINESS_CATEGORIES.JEWELRY]: 'Jewelry',
  [BUSINESS_CATEGORIES.BOOKS_STATIONERY]: 'Books & Stationery',
  [BUSINESS_CATEGORIES.SPORTS]: 'Sports & Outdoors',
  [BUSINESS_CATEGORIES.PET_CARE]: 'Pet Care',
  [BUSINESS_CATEGORIES.TRAVEL]: 'Travel & Tourism',
  [BUSINESS_CATEGORIES.OTHER]: 'Other',
};

const BUSINESS_CATEGORY_LIST = Object.values(BUSINESS_CATEGORIES);

// Special category for plans that apply to all categories
const ALL_CATEGORIES = 'all';

function isValidCategory(category) {
  return BUSINESS_CATEGORY_LIST.includes(category) || category === ALL_CATEGORIES;
}

function getCategoryLabel(category) {
  return BUSINESS_CATEGORY_LABELS[category] || category;
}

function getAllCategories() {
  return BUSINESS_CATEGORY_LIST.map(cat => ({
    value: cat,
    label: BUSINESS_CATEGORY_LABELS[cat],
  }));
}

module.exports = {
  BUSINESS_CATEGORIES,
  BUSINESS_CATEGORY_LABELS,
  BUSINESS_CATEGORY_LIST,
  ALL_CATEGORIES,
  isValidCategory,
  getCategoryLabel,
  getAllCategories,
};
