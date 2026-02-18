const mongoose = require('mongoose');

const onboardingStatusSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      unique: true,
    },
    businessProfileCompleted: {
      type: Boolean,
      default: false,
    },
    termsAccepted: {
      type: Boolean,
      default: false,
    },
    termsAcceptedAt: {
      type: Date,
    },
    subscriptionActivated: {
      type: Boolean,
      default: false,
    },
    onboardingCompleted: {
      type: Boolean,
      default: false,
    },
    currentStep: {
      type: Number,
      default: 1, // 1: Business Profile, 2: Terms, 3: Subscription
    },
  },
  {
    timestamps: true,
  }
);

onboardingStatusSchema.index({ userId: 1 }, { unique: true });

// Method to check if onboarding is complete
onboardingStatusSchema.methods.isComplete = function () {
  return (
    this.businessProfileCompleted &&
    this.termsAccepted &&
    this.subscriptionActivated &&
    this.onboardingCompleted
  );
};

// Method to get next step
onboardingStatusSchema.methods.getNextStep = function () {
  if (!this.businessProfileCompleted) return 1;
  if (!this.termsAccepted) return 2;
  if (!this.subscriptionActivated) return 3;
  return 0; // Completed
};

module.exports = mongoose.model('OnboardingStatus', onboardingStatusSchema);
