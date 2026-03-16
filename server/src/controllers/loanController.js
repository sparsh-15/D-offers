const { prisma } = require('../db/prisma');

async function submitLoanApplication(req, res, next) {
  try {
    const userId = req.user.id;
    const {
      fullName,
      mobileNumber,
      employmentType,
      monthlySalaryIncome,
      loanAmount,
      panNumber,
      bankName,
      accountType,
      last4AccountDigits,
      bankStatementUrl,
      cibilConsent,
      communicationConsent,
    } = req.body;

    // Validate required fields
    if (!fullName || !mobileNumber || !employmentType || !monthlySalaryIncome || 
        !loanAmount || !panNumber || !bankName || !accountType || !last4AccountDigits || !bankStatementUrl) {
      return res.status(400).json({
        success: false,
        message: 'All fields are required',
      });
    }

    if (typeof bankStatementUrl !== 'string' || bankStatementUrl.trim().length < 8) {
      return res.status(400).json({
        success: false,
        message: 'Valid bank statement upload is required',
      });
    }

    // Validate CIBIL consent (mandatory)
    if (!cibilConsent) {
      return res.status(400).json({
        success: false,
        message: 'CIBIL consent is mandatory to apply for a loan',
      });
    }

    // Validate PAN format (basic - 10 characters, alphanumeric)
    if (!panNumber || panNumber.length !== 10) {
      return res.status(400).json({
        success: false,
        message: 'Invalid PAN number. PAN must be 10 characters.',
      });
    }

    // Validate mobile number
    if (mobileNumber.length !== 10 || !/^\d{10}$/.test(mobileNumber)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid mobile number. Must be 10 digits.',
      });
    }

    // Validate account number
    if (!last4AccountDigits || last4AccountDigits.length !== 4) {
      return res.status(400).json({
        success: false,
        message: 'Invalid account number. Last 4 digits required.',
      });
    }

    // Validate numeric fields
    const salary = parseFloat(monthlySalaryIncome);
    const loan = parseFloat(loanAmount);

    if (isNaN(salary) || salary <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Monthly salary must be a positive number',
      });
    }

    if (isNaN(loan) || loan <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Loan amount must be a positive number',
      });
    }

    // Create loan application
    const loanApplication = await prisma.loanApplication.create({
      data: {
        customerId: userId,
        fullName: fullName.trim(),
        mobileNumber: mobileNumber.trim(),
        employmentType,
        monthlySalaryIncome: salary,
        loanAmount: loan,
        panNumber: panNumber.trim().toUpperCase(),
        bankName: bankName.trim(),
        accountType,
        last4AccountDigits: last4AccountDigits.trim(),
        bankStatementUrl: bankStatementUrl.trim(),
        cibilConsent,
        communicationConsent,
        status: 'pending',
      },
    });

    res.status(201).json({
      success: true,
      message: 'Loan application submitted successfully',
      loanApplicationId: loanApplication.id,
      data: {
        id: loanApplication.id,
        status: loanApplication.status,
        createdAt: loanApplication.createdAt,
      },
    });
  } catch (error) {
    console.error('Error submitting loan application:', error);
    next(error);
  }
}

async function getLoanApplications(req, res, next) {
  try {
    const userId = req.user.id;
    const { limit = 10, skip = 0 } = req.query;

    const limitNum = Math.min(Math.max(parseInt(limit, 10) || 10, 1), 100);
    const skipNum = Math.max(parseInt(skip, 10) || 0, 0);

    const applications = await prisma.loanApplication.findMany({
      where: { customerId: userId },
      orderBy: { createdAt: 'desc' },
      take: limitNum,
      skip: skipNum,
    });

    const total = await prisma.loanApplication.count({
      where: { customerId: userId },
    });

    res.status(200).json({
      success: true,
      data: applications,
      total,
      limit: limitNum,
      skip: skipNum,
    });
  } catch (error) {
    console.error('Error fetching loan applications:', error);
    next(error);
  }
}

async function getLoanApplicationById(req, res, next) {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    const application = await prisma.loanApplication.findFirst({
      where: {
        id,
        customerId: userId,
      },
    });

    if (!application) {
      return res.status(404).json({
        success: false,
        message: 'Loan application not found',
      });
    }

    res.status(200).json({
      success: true,
      data: application,
    });
  } catch (error) {
    console.error('Error fetching loan application:', error);
    next(error);
  }
}

module.exports = {
  submitLoanApplication,
  getLoanApplications,
  getLoanApplicationById,
};
