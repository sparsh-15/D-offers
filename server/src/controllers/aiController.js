const { GoogleGenerativeAI } = require('@google/generative-ai');
const { routeIntent } = require('../ai/services/intentRouter');

// Use a currently available, low-latency model for answer generation
const MODEL_NAME = 'gemini-2.5-flash';
let model;

function getModel() {
  if (!process.env.GEMINI_API_KEY) {
    throw new Error('GEMINI_API_KEY is not configured in environment');
  }
  if (!model) {
    const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
    model = genAI.getGenerativeModel({ model: MODEL_NAME });
  }
  return model;
}

async function customerHelpChat(req, res, next) {
  try {
    const { message } = req.body || {};

    if (!message || typeof message !== 'string') {
      return res
        .status(400)
        .json({ success: false, message: 'message (string) is required' });
    }

    console.log('[AI] /ai/chat request:', {
      userId: req.user?.id,
      message: message.slice(0, 200),
    });

    // Step 1: classify intent and execute the appropriate tool(s)
    const routed = await routeIntent({
      user: req.user,
      message,
    });

    const model = getModel();

    // Step 2: generate a friendly answer using tool results
    const result = await model.generateContent([
      "You are the in-app assistant for myOffers, a hyperlocal deals app.",
      'You are chatting with a customer inside the mobile app.',
      'Guidelines:',
      '- Answer concisely in 1–3 short sentences.',
      "- Focus on myOffers app topics: discovering offers, saving favourites, redeeming offers in-store, subscriptions and plans, troubleshooting basic app issues.",
      "- If the user asks a general question (e.g. about Java), briefly answer but always connect your reply back to how myOffers can help with offers and savings.",
      '- Never ask for OTPs, passwords, or sensitive personal data.',
      '- If something needs human support, say you will connect them to support.',
      '- Prefer responding in the same language the user used (support English and Hindi).',
      '- If toolResult.mode is "clarify", DO NOT list offers. Ask 1-2 focused follow-up questions (category, location, discount) and guide the user to choose.',
      '- If offers are available, summarize only the top 3-5 relevant options instead of dumping a long list.',
      '',
      'You have already called internal tools and received structured data below as JSON.',
      'Use that data to ground your answer (do not invent offers or coupons that are not in the JSON).',
      '',
      'User question:',
      message,
      '',
      'Tool context JSON:',
      JSON.stringify(
        {
          intent: routed.intent,
          params: routed.params,
          toolResult: routed.toolResult,
        },
        null,
        2,
      ),
    ]);

    const reply =
      (result.response && typeof result.response.text === 'function'
        ? result.response.text()
        : null) ||
      "Sorry, I couldn't generate an answer right now. Please try again in a moment.";

    console.log('[AI] /ai/chat reply length:', reply?.length ?? 0);

    res.json({
      success: true,
      data: {
        reply,
        actions: routed.actions || [],
        items: routed.items || {},
      },
    });
  } catch (err) {
    console.error('[AI] /ai/chat error:', err);
    next(err);
  }
}

module.exports = {
  customerHelpChat,
};

