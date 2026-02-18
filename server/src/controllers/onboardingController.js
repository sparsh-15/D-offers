const OnboardingStatus = require('../models/OnboardingStatus');
const ShopkeeperProfile = require('../models/ShopkeeperProfile');
const Subscription = require('../models/Subscription');

/**
 * Get current onboarding status
 */
async function getOnboardingStatus(req, res, next) {
  try {
    let onboarding = await OnboardingStatus.findOne({ userId: req.user.userId });

    if (!onboarding) {
      // Create initial onboarding status
      onboarding = await OnboardingStatus.create({
        userId: req.user.userId,
        currentStep: 1,
      });
    }

    // Check actual completion status
    const profile = await ShopkeeperProfile.findOne({ userId: req.user.userId });
    const subscription = await Subscription.findOne({ userId: req.user.userId });

    // Update flags based on actual data
    onboarding.businessProfileCompleted = !!profile && !!profile.shopName;
    onboarding.subscriptionActivated = subscription ? subscription.isActive() : false;

    await onboarding.save();

    res.status(200).json({
      success: true,
      onboarding: {
        currentStep: onboarding.getNextStep() || 4, // 4 means completed
        businessProfileCompleted: onboarding.businessProfileCompleted,
        termsAccepted: onboarding.termsAccepted,
        subscriptionActivated: onboarding.subscriptionActivated,
        onboardingCompleted: onboarding.isComplete(),
      },
    });
  } catch (err) {
    next(err);
  }
}

/**
 * Accept terms and conditions
 */
async function acceptTerms(req, res, next) {
  try {
    let onboarding = await OnboardingStatus.findOne({ userId: req.user.userId });

    if (!onboarding) {
      onboarding = await OnboardingStatus.create({
        userId: req.user.userId,
      });
    }

    onboarding.termsAccepted = true;
    onboarding.termsAcceptedAt = new Date();
    onboarding.currentStep = Math.max(onboarding.currentStep, 3);

    await onboarding.save();

    res.status(200).json({
      success: true,
      message: 'Terms and conditions accepted',
      onboarding: {
        currentStep: onboarding.getNextStep() || 4,
        businessProfileCompleted: onboarding.businessProfileCompleted,
        termsAccepted: onboarding.termsAccepted,
        subscriptionActivated: onboarding.subscriptionActivated,
        onboardingCompleted: onboarding.isComplete(),
      },
    });
  } catch (err) {
    next(err);
  }
}

/**
 * Complete business profile step
 */
async function completeBusinessProfile(req, res, next) {
  try {
    // Check if profile exists
    const profile = await ShopkeeperProfile.findOne({ userId: req.user.userId });

    if (!profile || !profile.shopName) {
      return res.status(400).json({
        success: false,
        message: 'Business profile must be completed first',
      });
    }

    let onboarding = await OnboardingStatus.findOne({ userId: req.user.userId });

    if (!onboarding) {
      onboarding = await OnboardingStatus.create({
        userId: req.user.userId,
      });
    }

    onboarding.businessProfileCompleted = true;
    onboarding.currentStep = Math.max(onboarding.currentStep, 2);

    await onboarding.save();

    res.status(200).json({
      success: true,
      message: 'Business profile completed',
      onboarding: {
        currentStep: onboarding.getNextStep() || 4,
        businessProfileCompleted: onboarding.businessProfileCompleted,
        termsAccepted: onboarding.termsAccepted,
        subscriptionActivated: onboarding.subscriptionActivated,
        onboardingCompleted: onboarding.isComplete(),
      },
    });
  } catch (err) {
    next(err);
  }
}

/**
 * Mark onboarding as complete (after subscription activation)
 */
async function completeOnboarding(req, res, next) {
  try {
    const onboarding = await OnboardingStatus.findOne({ userId: req.user.userId });

    if (!onboarding) {
      return res.status(404).json({
        success: false,
        message: 'Onboarding not found',
      });
    }

    // Verify all steps are complete
    if (!onboarding.businessProfileCompleted) {
      return res.status(400).json({
        success: false,
        message: 'Business profile must be completed',
      });
    }

    if (!onboarding.termsAccepted) {
      return res.status(400).json({
        success: false,
        message: 'Terms and conditions must be accepted',
      });
    }

    const subscription = await Subscription.findOne({ userId: req.user.userId });
    if (!subscription || !subscription.isActive()) {
      return res.status(400).json({
        success: false,
        message: 'Active subscription required',
      });
    }

    onboarding.subscriptionActivated = true;
    onboarding.onboardingCompleted = true;
    onboarding.currentStep = 4;

    await onboarding.save();

    res.status(200).json({
      success: true,
      message: 'Onboarding completed successfully',
      onboarding: {
        currentStep: 4,
        businessProfileCompleted: true,
        termsAccepted: true,
        subscriptionActivated: true,
        onboardingCompleted: true,
      },
    });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  getOnboardingStatus,
  acceptTerms,
  completeBusinessProfile,
  completeOnboarding,
};
