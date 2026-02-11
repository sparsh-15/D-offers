// Test script to verify city is being saved correctly
const baseUrl = 'http://localhost:3000/api';

async function testSignupWithCity() {
    console.log('\n=== Testing Signup with City ===');

    // Test 1: Signup with city provided
    console.log('\n1. Testing signup with city parameter...');
    try {
        const response = await fetch(`${baseUrl}/auth/signup`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                role: 'customer',
                phone: '9999999998',
                name: 'Test User With City',
                pincode: '483001',
                city: 'Jabalpur City',
                address: 'Test Address'
            })
        });
        const data = await response.json();
        console.log('Status:', response.status);
        console.log('Response:', data);

        if (response.status === 200) {
            console.log('✅ Signup successful');

            // Verify OTP and check user data
            console.log('\n2. Verifying OTP and checking user data...');
            const verifyResponse = await fetch(`${baseUrl}/auth/verify-otp`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    role: 'customer',
                    phone: '9999999998',
                    otp: '999999'
                })
            });
            const verifyData = await verifyResponse.json();
            console.log('Verify Status:', verifyResponse.status);
            console.log('Verify Response:', verifyData);

            if (verifyResponse.status === 200) {
                const token = verifyData.token;

                // Get user profile
                console.log('\n3. Fetching user profile...');
                const profileResponse = await fetch(`${baseUrl}/auth/me`, {
                    headers: {
                        'Authorization': `Bearer ${token}`
                    }
                });
                const profileData = await profileResponse.json();
                console.log('Profile Status:', profileResponse.status);
                console.log('Profile Data:', JSON.stringify(profileData, null, 2));

                if (profileData.user && profileData.user.city) {
                    console.log('\n✅ SUCCESS! City is saved:', profileData.user.city);
                    console.log('Expected: Jabalpur City');
                    console.log('Actual:', profileData.user.city);

                    if (profileData.user.city === 'Jabalpur City') {
                        console.log('✅ City matches exactly!');
                    } else {
                        console.log('⚠️ City does not match expected value');
                    }
                } else {
                    console.log('\n❌ FAILED! City is empty or missing');
                }
            }
        }
    } catch (error) {
        console.error('❌ Error:', error.message);
    }

    // Test 2: Signup without city (should auto-fill from pincode)
    console.log('\n\n=== Testing Signup without City (Auto-fill) ===');
    try {
        const response = await fetch(`${baseUrl}/auth/signup`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                role: 'customer',
                phone: '9999999997',
                name: 'Test User Without City',
                pincode: '110001',
                address: 'Test Address'
            })
        });
        const data = await response.json();
        console.log('Status:', response.status);
        console.log('Response:', data);

        if (response.status === 200) {
            console.log('✅ Signup successful');

            // Verify OTP and check user data
            const verifyResponse = await fetch(`${baseUrl}/auth/verify-otp`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    role: 'customer',
                    phone: '9999999997',
                    otp: '999999'
                })
            });
            const verifyData = await verifyResponse.json();

            if (verifyResponse.status === 200) {
                const token = verifyData.token;

                // Get user profile
                const profileResponse = await fetch(`${baseUrl}/auth/me`, {
                    headers: {
                        'Authorization': `Bearer ${token}`
                    }
                });
                const profileData = await profileResponse.json();
                console.log('Profile Data:', JSON.stringify(profileData, null, 2));

                if (profileData.user && profileData.user.city) {
                    console.log('\n✅ SUCCESS! City is auto-filled:', profileData.user.city);
                } else {
                    console.log('\n❌ FAILED! City is empty or missing');
                }
            }
        }
    } catch (error) {
        console.error('❌ Error:', error.message);
    }
}

console.log('========================================');
console.log('Testing City Field Fix');
console.log('========================================');
console.log('Make sure server is running on port 3000');
console.log('========================================\n');

testSignupWithCity();
