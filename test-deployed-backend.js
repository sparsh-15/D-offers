const https = require('https');

const BASE_URL = 'https://d-offers.onrender.com';

function makeRequest(method, path, body = null) {
    return new Promise((resolve, reject) => {
        const url = new URL(`${BASE_URL}${path}`);
        const options = {
            hostname: url.hostname,
            path: url.pathname + url.search,
            method: method,
            headers: { 'Content-Type': 'application/json' },
        };

        const req = https.request(options, (res) => {
            let data = '';
            res.on('data', (chunk) => { data += chunk; });
            res.on('end', () => {
                try {
                    const parsed = data ? JSON.parse(data) : {};
                    console.log(`Status: ${res.statusCode}`);
                    if (res.statusCode >= 200 && res.statusCode < 300) {
                        resolve(parsed);
                    } else {
                        reject(new Error(parsed.message || `Status ${res.statusCode}`));
                    }
                } catch (e) {
                    reject(new Error(`Failed to parse: ${data}`));
                }
            });
        });
        req.on('error', reject);
        if (body) req.write(JSON.stringify(body));
        req.end();
    });
}

async function testDeployedBackend() {
    console.log('🧪 Testing Deployed Backend: https://d-offers.onrender.com\n');

    try {
        // Test 1: Health check / root endpoint
        console.log('1️⃣ Testing root endpoint...');
        try {
            const rootRes = await makeRequest('GET', '/');
            console.log('✅ Root endpoint working');
            console.log('   Response:', rootRes);
        } catch (e) {
            console.log('⚠️  Root endpoint:', e.message);
        }
        console.log('');

        // Test 2: Send OTP (this should work without auth)
        console.log('2️⃣ Testing POST /api/auth/send-otp...');
        try {
            const otpRes = await makeRequest('POST', '/api/auth/send-otp', {
                phone: '9999999999',
                role: 'admin',
            });
            console.log('✅ Send OTP endpoint working');
            console.log('   Response:', otpRes);
        } catch (e) {
            console.log('❌ Send OTP failed:', e.message);
        }
        console.log('');

        // Test 3: Verify OTP and get token
        console.log('3️⃣ Testing POST /api/auth/verify-otp...');
        try {
            const verifyRes = await makeRequest('POST', '/api/auth/verify-otp', {
                phone: '9999999999',
                otp: '999999',
            });
            console.log('✅ Verify OTP endpoint working');
            console.log('   Token received:', verifyRes.token ? 'Yes' : 'No');

            if (verifyRes.token) {
                // Test 4: Test authenticated endpoint
                console.log('');
                console.log('4️⃣ Testing GET /api/auth/me (authenticated)...');
                try {
                    const meRes = await makeRequestWithAuth('GET', '/api/auth/me', verifyRes.token);
                    console.log('✅ Authenticated endpoint working');
                    console.log('   User:', meRes.user);
                } catch (e) {
                    console.log('❌ Auth endpoint failed:', e.message);
                }
            }
        } catch (e) {
            console.log('❌ Verify OTP failed:', e.message);
        }
        console.log('');

        console.log('✅ Backend testing complete!');
        console.log('\n📝 Summary:');
        console.log('   Backend URL: https://d-offers.onrender.com');
        console.log('   API Base: https://d-offers.onrender.com/api');
        console.log('   Status: Check results above');

    } catch (error) {
        console.error('❌ Unexpected error:', error.message);
    }
}

function makeRequestWithAuth(method, path, token) {
    return new Promise((resolve, reject) => {
        const url = new URL(`${BASE_URL}${path}`);
        const options = {
            hostname: url.hostname,
            path: url.pathname + url.search,
            method: method,
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`,
            },
        };

        const req = https.request(options, (res) => {
            let data = '';
            res.on('data', (chunk) => { data += chunk; });
            res.on('end', () => {
                try {
                    const parsed = data ? JSON.parse(data) : {};
                    if (res.statusCode >= 200 && res.statusCode < 300) {
                        resolve(parsed);
                    } else {
                        reject(new Error(parsed.message || `Status ${res.statusCode}`));
                    }
                } catch (e) {
                    reject(new Error(`Failed to parse: ${data}`));
                }
            });
        });
        req.on('error', reject);
        req.end();
    });
}

testDeployedBackend();
