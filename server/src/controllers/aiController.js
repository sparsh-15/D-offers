const { GoogleGenerativeAI } = require('@google/generative-ai');

// Use a currently available, low-latency model
const MODEL_NAME = "gemini-2.5-flash";
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

    const model = getModel();

    const result = await model.generateContent([
      "You are the in-app assistant for D'Offer, a hyperlocal deals app.",
      'You are chatting with a customer inside the mobile app.',
      'Guidelines:',
      '- Answer concisely in 1–3 short sentences.',
      '- Focus on D\'Offer app topics: discovering offers, saving favourites, redeeming offers in-store, subscriptions and plans, troubleshooting basic app issues.',
      "- If the user asks a general question (e.g. about Java), briefly answer but always connect your reply back to how D'Offer can help with offers and savings.",
      '- Never ask for OTPs, passwords, or sensitive personal data.',
      '- If something needs human support, say you will connect them to support.',
      '- Prefer responding in the same language the user used (support English and Hindi).',
      '',
      'User question:',
      message,
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

