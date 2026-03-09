const { prisma } = require('../db/prisma');
const { sendOtp } = require('./otpService');
const auditLogRepository = require('../repositories/auditLogRepository');

function ci(value) {
  return String(value || '').trim();
}

function normalizePhone(value) {
  return ci(value).replace(/\s+/g, '');
}

function normalizeCoupon(value) {
  const trimmed = ci(value);
  return trimmed ? trimmed.toUpperCase() : null;
}

class LeadConflictError extends Error {
  constructor(code, message, details = {}, statusCode = 409) {
    super(message);
    this.name = 'LeadConflictError';
    this.code = code;
    this.details = details;
    this.statusCode = statusCode;
  }
}

function buildOwnerSummary(lead) {
  if (!lead) return null;
  return {
    leadId: lead.id,
    ownerAgentRole: lead.ssaId ? 'ssa' : 'company_sales_agent',
    createdAt: lead.createdAt,
    status: lead.status,
  };
}

function mapLead(lead, resultType = null) {
  return {
    id: lead.id,
    shopName: lead.shopName,
    ownerName: lead.ownerName,
    phone: lead.phone,
    pincode: lead.pincode,
    city: lead.city,
    category: lead.category,
    notes: lead.notes,
    couponCode: lead.couponCode,
    status: lead.status,
    inviteStatus: lead.inviteStatus || 'pending',
    inviteSentAt: lead.inviteSentAt ? lead.inviteSentAt.toISOString() : null,
    inviteError: lead.inviteError || null,
    claimedAt: lead.claimedAt ? lead.claimedAt.toISOString() : null,
    linkedUserId: lead.shopkeeperUserId || null,
    sourceAgentRole: lead.sourceAgentRole || null,
    resultType,
    createdAt: lead.createdAt.toISOString(),
    updatedAt: lead.updatedAt.toISOString(),
  };
}

async function validateAgentCoupon(tx, { agentId, couponCode, agentRole }) {
  const normalizedCouponCode = normalizeCoupon(couponCode);
  if (!normalizedCouponCode) return null;
  const now = new Date();
  const coupon = await tx.coupon.findFirst({
    where: {
      code: normalizedCouponCode,
      agentId,
      isActive: true,
      OR: [{ expiryDate: null }, { expiryDate: { gt: now } }],
    },
  });
  if (!coupon) {
    throw new LeadConflictError(
      'invalid_coupon',
      `Invalid or expired coupon code for this ${agentRole === 'ssa' ? 'SSA' : 'sales agent'}`,
      {},
      400,
    );
  }
  if (coupon.maxUses != null && coupon.currentUses >= coupon.maxUses) {
    throw new LeadConflictError(
      'coupon_usage_limit_reached',
      'Coupon has reached its maximum uses',
      {},
      400,
    );
  }
  return normalizedCouponCode;
}

function isOwnedByAgent(lead, agentId, agentRole) {
  return agentRole === 'ssa' ? lead?.ssaId === agentId : lead?.csaId === agentId;
}

async function createOrLinkLead({
  agentId,
  agentRole,
  shopName,
  ownerName,
  phone,
  pincode,
  city,
  category,
  notes,
  couponCode,
  ipAddress,
}) {
  if (!ci(shopName) || !ci(phone)) {
    throw new LeadConflictError(
      'invalid_payload',
      'Shop name and phone are required',
      {},
      400,
    );
  }

  const normalizedPhone = normalizePhone(phone);
  let createdLead;
  let linkedUserId;
  let resultType = 'lead_created_user_invited';
  let ownerSummary = null;

  try {
    await prisma.$transaction(
      async (tx) => {
      const existingActiveLead = await tx.shopLead.findFirst({
        where: {
          phone: normalizedPhone,
          status: { in: ['open', 'contacted', 'claimed'] },
        },
        orderBy: { createdAt: 'asc' },
      });

      if (existingActiveLead) {
        ownerSummary = buildOwnerSummary(existingActiveLead);
        const sameAgent = isOwnedByAgent(existingActiveLead, agentId, agentRole);
        if (sameAgent) {
          throw new LeadConflictError(
            'lead_phone_already_claimed',
            'This phone already has an active lead by you.',
            { owner: ownerSummary },
          );
        }
        throw new LeadConflictError(
          'lead_phone_already_owned',
          'This phone is already registered/onboarded under another lead.',
          { owner: ownerSummary },
        );
      }

      let user = await tx.user.findUnique({ where: { phone: normalizedPhone } });
      if (user && user.role !== 'shopkeeper') {
        throw new LeadConflictError(
          'lead_phone_already_registered',
          `This phone is already registered as ${user.role}`,
          { role: user.role },
        );
      }

      const normalizedCouponCode = await validateAgentCoupon(tx, {
        agentId,
        couponCode,
        agentRole,
      });

      if (!user) {
        user = await tx.user.create({
          data: {
            name: ci(ownerName) || ci(shopName),
            phone: normalizedPhone,
            role: 'shopkeeper',
            pincode: ci(pincode) || '',
            city: ci(city) || '',
            state: '',
            address: '',
            approvalStatus: 'approved',
            signupCouponCode: normalizedCouponCode || undefined,
            signupCouponCapturedAt: normalizedCouponCode ? new Date() : undefined,
          },
        });
      } else {
        resultType = 'lead_created_existing_user_linked';
      }

      linkedUserId = user.id;
      createdLead = await tx.shopLead.create({
        data: {
          ssaId: agentRole === 'ssa' ? agentId : null,
          csaId: agentRole === 'company_sales_agent' ? agentId : null,
          shopkeeperUserId: user.id,
          shopName: ci(shopName),
          ownerName: ci(ownerName) || null,
          phone: normalizedPhone,
          pincode: ci(pincode) || null,
          city: ci(city) || null,
          category: ci(category) || null,
          notes: ci(notes) || null,
          couponCode: normalizedCouponCode,
          sourceAgentRole: agentRole,
          claimedAt: resultType === 'lead_created_existing_user_linked' ? new Date() : null,
          inviteStatus: 'pending',
          status: 'open',
        },
      });

      await tx.user.updateMany({
        where: { id: user.id, onboardedByLeadId: null },
        data: { onboardedByLeadId: createdLead.id },
      });
      },
      { timeout: 15000 },
    );
  } catch (err) {
    if (err instanceof LeadConflictError) {
      await auditLogRepository.create({
        adminId: agentId,
        adminRole: agentRole,
        action: 'lead_conflict_rejected',
        targetUserId: linkedUserId || null,
        targetUserRole: 'shopkeeper',
        details: {
          code: err.code,
          phone: normalizedPhone,
          owner: err.details?.owner || ownerSummary,
        },
        ipAddress: ipAddress || null,
      });
    }
    throw err;
  }

  await auditLogRepository.create({
    adminId: agentId,
    adminRole: agentRole,
    action: 'lead_created',
    targetUserId: linkedUserId,
    targetUserRole: 'shopkeeper',
    details: { leadId: createdLead.id, phone: normalizedPhone, resultType },
    ipAddress: ipAddress || null,
  });

  if (resultType === 'lead_created_existing_user_linked') {
    await auditLogRepository.create({
      adminId: agentId,
      adminRole: agentRole,
      action: 'lead_linked_existing_user',
      targetUserId: linkedUserId,
      targetUserRole: 'shopkeeper',
      details: { leadId: createdLead.id, phone: normalizedPhone },
      ipAddress: ipAddress || null,
    });
  }

  let inviteStatus = 'sent';
  let inviteError = null;
  try {
    await sendOtp(normalizedPhone, 'shopkeeper');
  } catch (inviteErr) {
    inviteStatus = 'failed';
    inviteError = ci(inviteErr?.message || inviteErr) || 'Failed to send invite OTP';
  }

  const updatedLead = await prisma.shopLead.update({
    where: { id: createdLead.id },
    data: {
      inviteStatus,
      inviteSentAt: inviteStatus === 'sent' ? new Date() : null,
      inviteError,
    },
  });

  await auditLogRepository.create({
    adminId: agentId,
    adminRole: agentRole,
    action: inviteStatus === 'sent' ? 'lead_invite_sent' : 'lead_invite_failed',
    targetUserId: linkedUserId,
    targetUserRole: 'shopkeeper',
    details: {
      leadId: updatedLead.id,
      phone: normalizedPhone,
      inviteStatus,
      inviteError,
    },
    ipAddress: ipAddress || null,
  });

  return mapLead(updatedLead, resultType);
}

async function retryLeadInvite({ leadId, agentId, agentRole, ipAddress }) {
  const lead = await prisma.shopLead.findFirst({
    where: {
      id: leadId,
      ...(agentRole === 'ssa' ? { ssaId: agentId } : { csaId: agentId }),
    },
  });
  if (!lead) {
    throw new LeadConflictError('lead_not_found', 'Lead not found', {}, 404);
  }

  let inviteStatus = 'sent';
  let inviteError = null;
  try {
    await sendOtp(lead.phone, 'shopkeeper');
  } catch (inviteErr) {
    inviteStatus = 'failed';
    inviteError = ci(inviteErr?.message || inviteErr) || 'Failed to send invite OTP';
  }

  const updated = await prisma.shopLead.update({
    where: { id: lead.id },
    data: {
      inviteStatus,
      inviteSentAt: inviteStatus === 'sent' ? new Date() : null,
      inviteError,
    },
  });

  await auditLogRepository.create({
    adminId: agentId,
    adminRole: agentRole,
    action: inviteStatus === 'sent' ? 'lead_invite_sent' : 'lead_invite_failed',
    targetUserId: lead.shopkeeperUserId || null,
    targetUserRole: 'shopkeeper',
    details: {
      leadId: lead.id,
      retry: true,
      inviteStatus,
      inviteError,
    },
    ipAddress: ipAddress || null,
  });

  return mapLead(updated);
}

module.exports = {
  LeadConflictError,
  createOrLinkLead,
  retryLeadInvite,
  mapLead,
};
