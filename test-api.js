// Quick API test script
const baseUrl = 'http://localhost:3000/api';

async function testSignup() {
    console.log('\n=== Testing Signup ===');
    try {
        const response = await fetch(`${baseUrl}/auth/signup`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                role: 'customer',
                phone: '9876543210',
                name: 'Test Customer',
                pincode: '110001',
                address: 'Test Address'
            })
        });
        const data = await response.json();
        console.log('Signup Response:', response.status, data);
        return data;
    } catch (error) {
        console.error('Signup Error:', error.message);
    }
}

async function testSendOtp() {
    console.log('\n=== Testing Send OTP (Login) ===');
    try {
        const response = await fetch(`${baseUrl}/auth/send-otp`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                role: 'customer',
                phone: '9876543210'
            })
        });
        const data = await response.json();
        console.log('Send OTP Response:', response.status, data);
        return data;
    } catch (error) {
        console.error('Send OTP Error:', error.message);
    }
}

async function testVerifyOtp() {
    console.log('\n=== Testing Verify OTP ===');
    try {
        const response = await fetch(`${baseUrl}/auth/verify-otp`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                role: 'customer',
                phone: '9876543210',
                otp: '999999' // Master OTP
            })
        });
        const data = await response.json();
        console.log('Verify OTP Response:', response.status, data);
        return data;
    } catch (error) {
        console.error('Verify OTP Error:', error.message);
    }
}

async function testGetLastOtp() {
    console.log('\n=== Testing Get Last OTP (Dev) ===');
    try {
        const response = await fetch(`${baseUrl}/auth/dev/last-otp?phone=9876543210`);
        const data = await response.json();
        console.log('Last OTP Response:', response.status, data);
        return data;
    } catch (error) {
        console.error('Last OTP Error:', error.message);
    }
}

async function runTests() {
    console.log('Starting API Tests...');
    console.log('Make sure the server is running on port 3000');

    await testSignup();
    await new Promise(resolve => setTimeout(resolve, 1000));

    await testGetLastOtp();
    await new Promise(resolve => setTimeout(resolve, 1000));

    await testVerifyOtp();
    await new Promise(resolve => setTimeout(resolve, 1000));

    // Test login for existing user
    await testSendOtp();
    await new Promise(resolve => setTimeout(resolve, 1000));

    await testGetLastOtp();

    console.log('\n=== Tests Complete ===');
}

runTests();
