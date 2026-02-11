// Comprehensive API test script
const baseUrl = 'http://localhost:3000/api';

let customerToken = '';
let shopkeeperToken = '';
let adminToken = '';
let shopkeeperId = '';
let offerId = '';

// Helper function to make requests
async function request(method, endpoint, body = null, token = null) {
    const headers = { 'Content-Type': 'application/json' };
    if (token) headers['Authorization'] = `Bearer ${token}`;

    const options = { method, headers };
    if (body) options.body = JSON.stringify(body);

    try {
        const response = await fetch(`${baseUrl}${endpoint}`, options);
        const data = await response.json();
        return { status: response.status, data };
    } catch (error) {
        return { status: 0, error: error.message };
    }
}

// Test 1: Customer Signup
async function testCustomerSignup() {
    console.log('\n=== Test 1: Customer Signup ===');
    const result = await request('POST', '/auth/signup', {
        role: 'customer',
        phone: '8888888888',
        name: 'Test Customer',
        pincode: '110001',
        address: 'Test Address'
    });
    console.log('Status:', result.status);
    console.log('Response:', result.data);
    return result.status === 200;
}

// Test 2: Customer Verify OTP
async function testCustomerVerifyOtp() {
    console.log('\n=== Test 2: Customer Verify OTP ===');
    const result = await request('POST', '/auth/verify-otp', {
        role: 'customer',
        phone: '8888888888',
        otp: '999999'
    });
    console.log('Status:', result.status);
    console.log('Response:', result.data);
    if (result.status === 200) {
        customerToken = result.data.token;
        return true;
    }
    return false;
}

// Test 3: Customer Get Profile
async function testCustomerGetProfile() {
    console.log('\n=== Test 3: Customer Get Profile ===');
    const result = await request('GET', '/auth/me', null, customerToken);
    console.log('Status:', result.status);
    console.log('Response:', result.data);
    return result.status === 200;
}

// Test 4: Shopkeeper Signup
async function testShopkeeperSignup() {
    console.log('\n=== Test 4: Shopkeeper Signup ===');
    const result = await request('POST', '/auth/signup', {
        role: 'shopkeeper',
        phone: '7777777777',
        name: 'Test Shopkeeper',
        pincode: '110001',
        address: 'Shop Address'
    });
    console.log('Status:', result.status);
    console.log('Response:', result.data);
    return result.status === 200;
}

// Test 5: Shopkeeper Verify OTP (will fail if not approved)
async function testShopkeeperVerifyOtp() {
    console.log('\n=== Test 5: Shopkeeper Verify OTP ===');
    const result = await request('POST', '/auth/verify-otp', {
        role: 'shopkeeper',
        phone: '7777777777',
        otp: '999999'
    });
    console.log('Status:', result.status);
    console.log('Response:', result.data);
    if (result.status === 200) {
        shopkeeperToken = result.data.token;
        return true;
    }
    return false;
}

// Test 6: Admin Login
async function testAdminLogin() {
    console.log('\n=== Test 6: Admin Login (send OTP) ===');
    const result = await request('POST', '/auth/send-otp', {
        role: 'admin',
        phone: '9999999999'
    });
    console.log('Status:', result.status);
    console.log('Response:', result.data);
    return result.status === 200;
}

// Test 7: Admin Verify OTP
async function testAdminVerifyOtp() {
    console.log('\n=== Test 7: Admin Verify OTP ===');
    const result = await request('POST', '/auth/verify-otp', {
        role: 'admin',
        phone: '9999999999',
        otp: '999999'
    });
    console.log('Status:', result.status);
    console.log('Response:', result.data);
    if (result.status === 200) {
        adminToken = result.data.token;
        return true;
    }
    return false;
}

// Test 8: Admin Get Pending Shopkeepers
async function testAdminGetPendingShopkeepers() {
    console.log('\n=== Test 8: Admin Get Pending Shopkeepers ===');
    const result = await request('GET', '/admin/shopkeepers?status=pending', null, adminToken);
    console.log('Status:', result.status);
    console.log('Response:', result.data);
    if (result.status === 200 && result.data.shopkeepers.length > 0) {
        shopkeeperId = result.data.shopkeepers[0].id;
        return true;
    }
    return false;
}

// Test 9: Admin Approve Shopkeeper
async function testAdminApproveShopkeeper() {
    console.log('\n=== Test 9: Admin Approve Shopkeeper ===');
    const result = await request('PATCH', `/admin/shopkeepers/${shopkeeperId}/approve`, null, adminToken);
    console.log('Status:', result.status);
    console.log('Response:', result.data);
    return result.status === 200;
}

// Test 10: Shopkeeper Login After Approval
async function testShopkeeperLoginAfterApproval() {
    console.log('\n=== Test 10: Shopkeeper Login After Approval ===');
    const result = await request('POST', '/auth/send-otp', {
        role: 'shopkeeper',
        phone: '7777777777'
    });
    console.log('Status:', result.status);
    console.log('Response:', result.data);
    return result.status === 200;
}

// Test 11: Shopkeeper Verify OTP After Approval
async function testShopkeeperVerifyOtpAfterApproval() {
    console.log('\n=== Test 11: Shopkeeper Verify OTP After Approval ===');
    const result = await request('POST', '/auth/verify-otp', {
        role: 'shopkeeper',
        phone: '7777777777',
        otp: '999999'
    });
    console.log('Status:', result.status);
    console.log('Response:', result.data);
    if (result.status === 200) {
        shopkeeperToken = result.data.token;
        return true;
    }
    return false;
}

// Test 12: Shopkeeper Create Profile
async function testShopkeeperCreateProfile() {
    console.log('\n=== Test 12: Shopkeeper Create Profile ===');
    const result = await request('PUT', '/shopkeeper/profile', {
        shopName: 'Test Shop',
        address: 'Shop Address',
        pincode: '110001',
        city: 'New Delhi',
        category: 'Electronics',
        description: 'Best electronics shop'
    }, shopkeeperToken);
    console.log('Status:', result.status);
    console.log('Response:', result.data);
    return result.status === 200;
}

// Test 13: Shopkeeper Get Profile
async function testShopkeeperGetProfile() {
    console.log('\n=== Test 13: Shopkeeper Get Profile ===');
    const result = await request('GET', '/shopkeeper/profile', null, shopkeeperToken);
    console.log('Status:', result.status);
    console.log('Response:', result.data);
    return result.status === 200;
}

// Test 14: Shopkeeper Create Offer
async function testShopkeeperCreateOffer() {
    console.log('\n=== Test 14: Shopkeeper Create Offer ===');
    const result = await request('POST', '/shopkeeper/offers', {
        title: '50% Off on Electronics',
        description: 'Limited time offer',
        discountType: 'percentage',
        discountValue: 50
    }, shopkeeperToken);
    console.log('Status:', result.status);
    console.log('Response:', result.data);
    if (result.status === 201) {
        offerId = result.data.offer.id;
        return true;
    }
    return false;
}

// Test 15: Shopkeeper Get Offers
async function testShopkeeperGetOffers() {
    console.log('\n=== Test 15: Shopkeeper Get Offers ===');
    const result = await request('GET', '/shopkeeper/offers', null, shopkeeperToken);
    console.log('Status:', result.status);
    console.log('Response:', result.data);
    return result.status === 200;
}

// Test 16: Shopkeeper Update Offer
async function testShopkeeperUpdateOffer() {
    console.log('\n=== Test 16: Shopkeeper Update Offer ===');
    const result = await request('PUT', `/shopkeeper/offers/${offerId}`, {
        title: '60% Off on Electronics',
        description: 'Extended offer'
    }, shopkeeperToken);
    console.log('Status:', result.status);
    console.log('Response:', result.data);
    return result.status === 200;
}

// Test 17: Customer Get Offers
async function testCustomerGetOffers() {
    console.log('\n=== Test 17: Customer Get Offers ===');
    const result = await request('GET', '/customer/offers', null, customerToken);
    console.log('Status:', result.status);
    console.log('Response:', result.data);
    return result.status === 200;
}

// Test 18: Shopkeeper Delete Offer
async function testShopkeeperDeleteOffer() {
    console.log('\n=== Test 18: Shopkeeper Delete Offer ===');
    const result = await request('DELETE', `/shopkeeper/offers/${offerId}`, null, shopkeeperToken);
    console.log('Status:', result.status);
    console.log('Response:', result.data);
    return result.status === 200;
}

// Run all tests
async function runAllTests() {
    console.log('========================================');
    console.log('Starting Comprehensive API Tests');
    console.log('========================================');
    console.log('Make sure:');
    console.log('1. Server is running on port 3000');
    console.log('2. MongoDB is connected');
    console.log('3. Admin account is seeded (npm run seed:admin)');
    console.log('========================================');

    const tests = [
        { name: 'Customer Signup', fn: testCustomerSignup },
        { name: 'Customer Verify OTP', fn: testCustomerVerifyOtp },
        { name: 'Customer Get Profile', fn: testCustomerGetProfile },
        { name: 'Shopkeeper Signup', fn: testShopkeeperSignup },
        { name: 'Shopkeeper Verify OTP (Pending)', fn: testShopkeeperVerifyOtp },
        { name: 'Admin Login', fn: testAdminLogin },
        { name: 'Admin Verify OTP', fn: testAdminVerifyOtp },
        { name: 'Admin Get Pending Shopkeepers', fn: testAdminGetPendingShopkeepers },
        { name: 'Admin Approve Shopkeeper', fn: testAdminApproveShopkeeper },
        { name: 'Shopkeeper Login After Approval', fn: testShopkeeperLoginAfterApproval },
        { name: 'Shopkeeper Verify OTP After Approval', fn: testShopkeeperVerifyOtpAfterApproval },
        { name: 'Shopkeeper Create Profile', fn: testShopkeeperCreateProfile },
        { name: 'Shopkeeper Get Profile', fn: testShopkeeperGetProfile },
        { name: 'Shopkeeper Create Offer', fn: testShopkeeperCreateOffer },
        { name: 'Shopkeeper Get Offers', fn: testShopkeeperGetOffers },
        { name: 'Shopkeeper Update Offer', fn: testShopkeeperUpdateOffer },
        { name: 'Customer Get Offers', fn: testCustomerGetOffers },
        { name: 'Shopkeeper Delete Offer', fn: testShopkeeperDeleteOffer },
    ];

    let passed = 0;
    let failed = 0;

    for (const test of tests) {
        try {
            const result = await test.fn();
            if (result) {
                passed++;
                console.log(`✅ ${test.name} PASSED`);
            } else {
                failed++;
                console.log(`❌ ${test.name} FAILED`);
            }
        } catch (error) {
            failed++;
            console.log(`❌ ${test.name} ERROR:`, error.message);
        }
        await new Promise(resolve => setTimeout(resolve, 500));
    }

    console.log('\n========================================');
    console.log('Test Results');
    console.log('========================================');
    console.log(`Total: ${tests.length}`);
    console.log(`Passed: ${passed}`);
    console.log(`Failed: ${failed}`);
    console.log('========================================');
}

runAllTests();
