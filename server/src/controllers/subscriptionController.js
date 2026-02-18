const Subscription = require('../models/Subscription');
const OnboardingStatus = require('../models/OnboardingStatus');

/**
 * Get current subscription status
 */
async function getSubscription(req, res, next) {
  try {
    let subscription = await Subscription.findOne({ userId: req.user.userId });

    if (!subscription) {
      // Create default subscription (inactive)
      subscription = await Subscription.create({
        userId: req.user.userId,
        status: 'inactive',
      });
    }

    res.status(200).json({
      success: true,
      subscription: {
        planType: subscription.planType,
        status: subscription.status,
        startDate: subscription.startDate,
        endDate: subscription.endDate,
        autoRenew: subscription.autoRenew,
        isActive: subscription.isActive(),
        isExpired: subscription.isExpired(),
      },
    });
  } catch (err) {
    next(err);
  }
}

/**
 * Activate trial subscription (7 days free)
 */
async function activateTrial(req, res, next) {
  try {
    let subscription = await Subscription.findOne({ userId: req.user.userId });

    if (!subscription) {
      subscription = await Subscription.create({
        userId: req.user.userId,
      });
    }

    // Check if trial already used
    if (subscription.paymentHistory && subscription.paymentHistory.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Trial already used',
      });
    }

    const startDate = new Date();
    const endDate = new Date();
    endDate.setDate(endDate.getDate() + 7); // 7 days trial

    subscription.planType = 'trial';
    subscription.status = 'active';
    subscription.startDate = startDate;
    subscription.endDate = endDate;
    subscription.autoRenew = false;

    await subscription.save();

    // Update onboarding status
    const onboarding = await OnboardingStatus.findOne({ userId: req.user.userId });
    if (onboarding) {
      onboarding.subscriptionActivated = true;
      if (onboarding.businessProfileCompleted && onboarding.termsAccepted) {
        onboarding.onboardingCompleted = true;
      }
      await onboarding.save();
    }

    res.status(200).json({
      success: true,
      message: 'Trial subscription activated',
      subscription: {
        planType: subscription.planType,
        status: subscription.status,
        startDate: subscription.startDate,
        endDate: subscription.endDate,
        isActive: subscription.isActive(),
      },
    });
  } catch (err) {
    next(err);
  }
}

/**
 * Create/update subscription (for payment integration)
 */
async function createSubscription(req, res, next) {
  try {
    const { planType, durationMonths, transactionId, amount } = req.body;

    if (!planType || !durationMonths) {
      return res.status(400).json({
        success: false,
        message: 'Plan type and duration are required',
      });
    }

    let subscription = await Subscription.findOne({ userId: req.user.userId });

    if (!subscription) {
      subscription = await Subscription.create({
        userId: req.user.userId,
      });
    }

    const startDate = new Date();
    const endDate = new Date();
    endDate.setMonth(endDate.getMonth() + parseInt(durationMonths));

    subscription.planType = planType;
    subscription.status = 'active';
    subscription.startDate = startDate;
    subscription.endDate = endDate;
    subscription.autoRenew = req.body.autoRenew || false;

    // Add payment record
    if (transactionId && amount) {
      subscription.paymentHistory.push({
        amount: parseFloat(amount),
        currency: 'INR',
        paymentDate: new Date(),
        transactionId,
        status: 'success',
      });
    }

    await subscription.save();

    // Update onboarding status
    const onboarding = await OnboardingStatus.findOne({ userId: req.user.userId });
    if (onboarding) {
      onboarding.subscriptionActivated = true;
      if (onboarding.businessProfileCompleted && onboarding.termsAccepted) {
        onboarding.onboardingCompleted = true;
      }
      await onboarding.save();
    }

    res.status(200).json({
      success: true,
      message: 'Subscription activated',
      subscription: {
        planType: subscription.planType,
        status: subscription.status,
        startDate: subscription.startDate,
        endDate: subscription.endDate,
        autoRenew: subscription.autoRenew,
        isActive: subscription.isActive(),
      },
    });
  } catch (err) {
    next(err);
  }
}

/**
 * Cancel subscription
 */
async function cancelSubscription(req, res, next) {
  try {
    const subscription = await Subscription.findOne({ userId: req.user.userId });

    if (!subscription) {
      return res.status(404).json({
        success: false,
        message: 'No subscription found',
      });
    }

    subscription.status = 'cancelled';
    subscription.autoRenew = false;

    await subscription.save();

    res.status(200).json({
      success: true,
      message: 'Subscription cancelled',
      subscription: {
        planType: subscription.planType,
        status: subscription.status,
        endDate: subscription.endDate,
      },
    });
  } catch (err) {
    next(err);
  }
}

/**
 * Get subscription plans (for display)
 */
async function getPlans(req, res, next) {
  try {
    const plans = [
      {
        id: 'trial',
        name: 'Trial',
        price: 0,
        duration: 7,
        durationUnit: 'days',
        features: ['Create up to 5 offers', 'Basic analytics', '7 days access'],
      },
      {
        id: 'basic',
        name: 'Basic',
        price: 499,
        duration: 1,
        durationUnit: 'month',
        features: ['Unlimited offers', 'Basic analytics', 'Email support'],
      },
      {
        id: 'premium',
        name: 'Premium',
        price: 999,
        duration: 1,
        durationUnit: 'month',
        features: [
          'Unlimited offers',
          'Advanced analytics',
          'Priority support',
          'Featured listings',
        ],
      },
      {
        id: 'enterprise',
        name: 'Enterprise',
        price: 2499,
        duration: 1,
        durationUnit: 'month',
        features: [
          'Everything in Premium',
          'Dedicated account manager',
          'Custom integrations',
          'API access',
        ],
      },
    ];

    res.status(200).json({
      success: true,
      plans,
    });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  getSubscription,
  activateTrial,
  createSubscription,
  cancelSubscription,
  getPlans,
};
