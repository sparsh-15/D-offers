const { prisma } = require('../db/prisma');
const { resolvePgId } = require('../repositories/idResolver');

function shape(onboarding) {
  const currentStep =
    !onboarding.businessProfileCompleted
      ? 1
      : !onboarding.termsAccepted
      ? 2
      : !onboarding.subscriptionActivated
      ? 3
      : 4;
  return {
    currentStep,
    businessProfileCompleted: onboarding.businessProfileCompleted,
    termsAccepted: onboarding.termsAccepted,
    subscriptionActivated: onboarding.subscriptionActivated,
    onboardingCompleted: onboarding.onboardingCompleted,
  };
}

async function getOnboardingStatus(req, res, next) {
  try {
    const userId = await resolvePgId('users', req.user.userId);
    let onboarding = await prisma.onboardingStatus.findUnique({ where: { userId } });
    if (!onboarding) {
      onboarding = await prisma.onboardingStatus.create({ data: { userId, currentStep: 1 } });
    }
    const profile = await prisma.shopkeeperProfile.findUnique({ where: { userId } });
    const subscription = await prisma.subscription.findFirst({
      where: { shopkeeperId: userId, status: 'active' },
      orderBy: { createdAt: 'desc' },
    });
    onboarding = await prisma.onboardingStatus.update({
      where: { userId },
      data: {
        businessProfileCompleted: !!profile && !!profile.shopName,
        subscriptionActivated:
          !!subscription && !!subscription.endDate && new Date(subscription.endDate) > new Date(),
      },
    });
    res.status(200).json({ success: true, onboarding: shape(onboarding) });
  } catch (err) {
    next(err);
  }
}

async function acceptTerms(req, res, next) {
  try {
    const userId = await resolvePgId('users', req.user.userId);
    const existing = await prisma.onboardingStatus.findUnique({ where: { userId } });
    const onboarding = existing
      ? await prisma.onboardingStatus.update({
          where: { userId },
          data: {
            termsAccepted: true,
            termsAcceptedAt: new Date(),
            currentStep: Math.max(existing.currentStep, 3),
          },
        })
      : await prisma.onboardingStatus.create({
          data: { userId, termsAccepted: true, termsAcceptedAt: new Date(), currentStep: 3 },
        });
    res.status(200).json({ success: true, message: 'Terms and conditions accepted', onboarding: shape(onboarding) });
  } catch (err) {
    next(err);
  }
}

async function completeBusinessProfile(req, res, next) {
  try {
    const userId = await resolvePgId('users', req.user.userId);
    const profile = await prisma.shopkeeperProfile.findUnique({ where: { userId } });
    if (!profile || !profile.shopName) {
      return res.status(400).json({ success: false, message: 'Business profile must be completed first' });
    }
    const existing = await prisma.onboardingStatus.findUnique({ where: { userId } });
    const onboarding = existing
      ? await prisma.onboardingStatus.update({
          where: { userId },
          data: {
            businessProfileCompleted: true,
            currentStep: Math.max(existing.currentStep, 2),
          },
        })
      : await prisma.onboardingStatus.create({
          data: { userId, businessProfileCompleted: true, currentStep: 2 },
        });
    res.status(200).json({ success: true, message: 'Business profile completed', onboarding: shape(onboarding) });
  } catch (err) {
    next(err);
  }
}

async function completeOnboarding(req, res, next) {
  try {
    const userId = await resolvePgId('users', req.user.userId);
    const onboarding = await prisma.onboardingStatus.findUnique({ where: { userId } });
    if (!onboarding) return res.status(404).json({ success: false, message: 'Onboarding not found' });
    if (!onboarding.businessProfileCompleted) {
      return res.status(400).json({ success: false, message: 'Business profile must be completed' });
    }
    if (!onboarding.termsAccepted) {
      return res.status(400).json({ success: false, message: 'Terms and conditions must be accepted' });
    }
    const subscription = await prisma.subscription.findFirst({
      where: { shopkeeperId: userId, status: 'active' },
      orderBy: { createdAt: 'desc' },
    });
    if (!subscription || !subscription.endDate || new Date(subscription.endDate) <= new Date()) {
      return res.status(400).json({ success: false, message: 'Active subscription required' });
    }
    await prisma.onboardingStatus.update({
      where: { userId },
      data: {
        subscriptionActivated: true,
        onboardingCompleted: true,
        currentStep: 4,
      },
    });
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

module.exports = { getOnboardingStatus, acceptTerms, completeBusinessProfile, completeOnboarding };
