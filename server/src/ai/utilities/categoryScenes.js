/**
 * Rich visual scene descriptions per category.
 * Each entry provides detailed art-direction for the AI background generator:
 *   scene        – foreground / midground / background composition
 *   lighting     – photography lighting style
 *   palette      – dominant color mood (used as hint in the prompt)
 */
const CATEGORY_SCENES = {

  clothing: {
    scene:
      "editorial fashion photography with stylish Indian outfits displayed on wooden hangers, soft bokeh background of a premium boutique interior, pastel gradient wall, scattered fabric swatches and accessories in foreground",
    lighting: "soft diffused studio light with gentle rim highlights",
    palette: "warm pastels, blush pink, ivory, soft gold",
  },

  grocery: {
    scene:
      "overhead flat-lay of fresh colourful vegetables and fruits arranged on a clean marble countertop, wicker baskets of spices, vibrant greens reds and yellows, farmers-market abundance feel",
    lighting: "bright natural window light with subtle soft shadows",
    palette: "fresh greens, harvest yellows, crisp whites",
  },

  restaurant: {
    scene:
      "beautifully plated Indian thali and signature dishes on a dark wooden table, garnished with fresh herbs, steam rising, rustic restaurant ambience with warm bokeh lights in background",
    lighting: "warm ambient golden-hour restaurant lighting",
    palette: "warm amber, deep mahogany, cream, saffron",
  },

  electronics: {
    scene:
      "sleek smartphones laptops and gadgets arranged on a reflective dark surface, neon accent glow strips, futuristic tech showroom backdrop, clean product-photography composition",
    lighting: "dramatic cool-toned rim light with subtle blue neon accents",
    palette: "cool midnight blue, electric cyan, slate grey",
  },

  pharmacy: {
    scene:
      "clean pharmacy interior with neatly organised medicine shelves, green cross signage, health supplement bottles in foreground, sterile white-and-teal colour scheme",
    lighting: "bright even clinical lighting, no harsh shadows",
    palette: "medical teal, clean white, soft green",
  },

  jewelry: {
    scene:
      "luxury close-up of gold necklaces diamond rings and bangles on dark velvet display pad, subtle sparkle reflections, ornate jewellery box in background",
    lighting: "focused spot light with sparkle highlights on gems",
    palette: "rich gold, deep burgundy, royal purple, black velvet",
  },

  gym_fitness: {
    scene:
      "modern gym interior with dumbbells kettlebells and resistance bands, rubber mat floor, motivational energy vibe, blurred treadmill and weight rack in background",
    lighting: "high-contrast dramatic overhead gym lighting",
    palette: "bold orange, charcoal black, electric lime",
  },

  beauty_salon: {
    scene:
      "chic salon station with professional hair styling tools, mirrors, fresh flowers, makeup brushes and cosmetics neatly arranged, soft pink-and-gold decor",
    lighting: "warm flattering vanity-mirror glow",
    palette: "rose gold, blush pink, soft lavender, creamy white",
  },

  books_stationery: {
    scene:
      "cosy bookstore shelf full of colourful spines, open notebook with fountain pen, stacked journals, warm reading-nook atmosphere",
    lighting: "warm ambient lamp light with gentle shadows",
    palette: "earthy brown, warm ivory, forest green, mustard",
  },

  sports: {
    scene:
      "dynamic sports equipment arrangement – cricket bat, football, badminton racquet, running shoes – on a vibrant turf-green surface, stadium lights flaring in background",
    lighting: "bright stadium flood-light with energy flare",
    palette: "turf green, championship gold, fiery red",
  },

  pet_care: {
    scene:
      "adorable puppy and kitten sitting among colourful pet toys, premium pet food bowls, cosy pet bed in background, playful warm setting",
    lighting: "soft warm daylight, cheerful and inviting",
    palette: "sunny yellow, sky blue, warm orange, grass green",
  },

  travel: {
    scene:
      "vintage leather suitcase with travel stickers, passport and boarding pass, world map backdrop, miniature airplane model, wanderlust flat-lay composition",
    lighting: "golden-hour warm sunlight with long shadows",
    palette: "sky blue, sunset orange, sandy beige, cloud white",
  },

  retail: {
    scene:
      "modern Indian retail storefront with colourful shopping bags, neatly stacked product boxes, promotional bunting, clean shelving display",
    lighting: "bright even retail-floor lighting",
    palette: "vibrant red, clean white, warm yellow",
  },

  automotive: {
    scene:
      "gleaming car in a professional showroom with reflective floor, alloy wheel close-up detail, modern garage tools in background",
    lighting: "dramatic low-angle showroom spot lights",
    palette: "metallic silver, racing red, midnight black",
  },

  healthcare: {
    scene:
      "clean modern clinic reception area with stethoscope, health charts, potted green plants, calming blue-and-white interior",
    lighting: "soft even overhead LED panel light",
    palette: "calming blue, sterile white, soft mint green",
  },

  education: {
    scene:
      "bright classroom desk with open textbooks, colourful stationery, chalkboard with equations in background, globe and pencil holder",
    lighting: "bright natural classroom window light",
    palette: "academic navy, chalk white, apple red, pencil yellow",
  },

  home_services: {
    scene:
      "tidy home interior with tool kit, paint swatches, fresh installations, clean modern kitchen or bathroom renovation scene",
    lighting: "bright natural interior daylight",
    palette: "warm wood tones, clean white, sky blue accent",
  },

  entertainment: {
    scene:
      "vibrant entertainment zone with neon gaming lights, popcorn bucket, movie clapperboard, colourful LED strips, party confetti",
    lighting: "neon glow with colourful LED ambient accents",
    palette: "neon purple, electric pink, vivid cyan, jet black",
  },

  food_beverage: {
    scene:
      "artisan coffee cup with latte art alongside fresh pastries, juice bottles, street-food snacks on a rustic wooden counter, café chalkboard in background",
    lighting: "warm café counter-top lighting with soft steam haze",
    palette: "espresso brown, cream, berry red, matcha green",
  },

  other: {
    scene:
      "clean modern shop interior with neatly arranged product shelves, warm inviting retail environment, subtle gradient wall",
    lighting: "bright even retail lighting",
    palette: "neutral warm grey, accent red, clean white",
  },
};

module.exports = CATEGORY_SCENES;