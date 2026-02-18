const Subscription = require('../models/Subscription');
const OnboardingStatus = require('../models/OnboardingStatus');

/**
 * Middleware to check if shopkeeper has active subscription
 * Only applies to shopkeeper role
 */
async function requireActiveSubscription(req, res, next) {
  try {
    // Only check subscription for shopkeepers
    if (req.user.role !== 'shopkeeper') {
      return next();
    }

    const subscription = await Subscription.findOne({ userId: req.user.userId });

    if (!subscription) {
      return res.status(403).json({
        success: false,
        message: 'No subscription found',
        code: 'NO_SUBSCRIPTION',
        redirectTo: '/subscription',
      });
    }

    // Check if subscription is active and not expired
    if (!subscription.isActive()) {
      return res.status(403).json({
        success: false,
        message: 'Subscription is inactive or expired',
        code: 'SUBSCRIPTION_INACTIVE',
        redirectTo: '/subscription',
        subscription: {
          status: subscription.status,
          endDate: subscription.endDate,
        },
      });
    }

    // Attach subscription to request for use in controllers
    req.subscription = subscription;
    next();
  } catch (err) {
    console.error('[SUBSCRIPTION_CHECK] Error:', err);
    next(err);
  }
}

/**
 * Middleware to check if shopkeeper has completed onboarding
 * Only applies to shopkeeper role
 */
async function requireOnboardingComplete(req, res, next) {
  try {
    // Only check onboarding for shopkeepers
    if (req.user.role !== 'shopkeeper') {
      return next();
    }

    const onboarding = await OnboardingStatus.findOne({ userId: req.user.userId });

    if (!onboarding) {
      return res.status(403).json({
        success: false,
        message: 'Onboarding not started',
        code: 'ONBOARDING_NOT_STARTED',
        redirectTo: '/onboarding',
        currentStep: 1,
      });
    }

    if (!onboarding.isComplete()) {
      const nextStep = onboarding.getNextStep();
      return res.status(403).json({
        success: false,
        message: 'Onboarding not completed',
        code: 'ONBOARDING_INCOMPLETE',
        redirectTo: '/onboarding',
        currentStep: nextStep,
        onboarding: {
          businessProfileCompleted: onboarding.businessProfileCompleted,
          termsAccepted: onboarding.termsAccepted,
          subscriptionActivated: onboarding.subscriptionActivated,
        },
      });
    }

    // Attach onboarding to request
    req.onboarding = onboarding;
    next();
  } catch (err) {
    console.error('[ONBOARDING_CHECK] Error:', err);
    next(err);
  }
}

module.exports = {
  requireActiveSubscription,
  requireOnboardingComplete,
};
