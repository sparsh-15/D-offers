/**
 * Script to test Super Admin endpoints
 * Usage: node scripts/test-super-admin.js <token>
 * 
 * Get token by:
 * 1. Login as super admin via /api/auth/sendOtp and /api/auth/verifyOtp
 * 2. Copy the token from response
 * 3. Run: node scripts/test-super-admin.js <your-token>
 */

const http = require('http');

const BASE_URL = process.env.BASE_URL || 'http://localhost:3000';
const token = process.argv[2];

if (!token) {
  console.error('❌ Error: Token is required');
  console.log('Usage: node scripts/test-super-admin.js <token>');
  console.log('\nTo get a token:');
  console.log('1. POST /api/auth/sendOtp with { "phone": "your-phone", "role": "super_admin" }');
  console.log('2. POST /api/auth/verifyOtp with { "phone": "your-phone", "otp": "999999", "role": "super_admin" }');
  console.log('3. Copy the token from response');
  process.exit(1);
}

function makeRequest(path, method = 'GET', body = null) {
  return new Promise((resolve, reject) => {
    const url = new URL(path, BASE_URL);
    const options = {
      hostname: url.hostname,
      port: url.port || 3000,
      path: url.pathname + url.search,
      method,
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
    };

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      res.on('end', () => {
        try {
          resolve({
            status: res.statusCode,
            data: JSON.parse(data),
          });
        } catch (e) {
          resolve({
            status: res.statusCode,
            data: data,
          });
        }
      });
    });

    req.on('error', reject);

    if (body) {
      req.write(JSON.stringify(body));
    }

    req.end();
  });
}

async function testEndpoints() {
  console.log('🧪 Testing Super Admin Endpoints\n');
  console.log('Base URL:', BASE_URL);
  console.log('Token:', token.substring(0, 20) + '...\n');

  const tests = [
    {
      name: 'Dashboard Analytics',
      path: '/api/super-admin/analytics',
      method: 'GET',
    },
    {
      name: 'Get All Users',
      path: '/api/super-admin/users?page=1&limit=5',
      method: 'GET',
    },
    {
      name: 'Get All Shops',
      path: '/api/super-admin/shops?page=1&limit=5',
      method: 'GET',
    },
    {
      name: 'Get Audit Logs',
      path: '/api/super-admin/audit-logs?page=1&limit=5',
      method: 'GET',
    },
    {
      name: 'Filter Users by Role',
      path: '/api/super-admin/users?role=shopkeeper&page=1&limit=5',
      method: 'GET',
    },
    {
      name: 'Search Users',
      path: '/api/super-admin/users?search=test&page=1&limit=5',
      method: 'GET',
    },
  ];

  let passed = 0;
  let failed = 0;

  for (const test of tests) {
    try {
      console.log(`📝 Testing: ${test.name}`);
      console.log(`   ${test.method} ${test.path}`);
      
      const result = await makeRequest(test.path, test.method, test.body);
      
      if (result.status === 200) {
        console.log(`   ✅ PASSED (${result.status})`);
        if (result.data.success) {
          console.log(`   📊 Data received:`, Object.keys(result.data.data || {}).join(', '));
        }
        passed++;
      } else if (result.status === 403) {
        console.log(`   ❌ FAILED (${result.status}) - Access Denied`);
        console.log(`   ⚠️  Make sure the token belongs to a super_admin user`);
        failed++;
      } else if (result.status === 401) {
        console.log(`   ❌ FAILED (${result.status}) - Unauthorized`);
        console.log(`   ⚠️  Token is invalid or expired`);
        failed++;
      } else {
        console.log(`   ❌ FAILED (${result.status})`);
        console.log(`   Error:`, result.data.message || result.data);
        failed++;
      }
    } catch (error) {
      console.log(`   ❌ FAILED - ${error.message}`);
      failed++;
    }
    console.log('');
  }

  console.log('═══════════════════════════════════════');
  console.log(`📊 Test Results: ${passed} passed, ${failed} failed`);
  console.log('═══════════════════════════════════════\n');

  if (failed > 0) {
    console.log('💡 Troubleshooting:');
    console.log('1. Verify the user has role "super_admin"');
    console.log('2. Check if token is valid and not expired');
    console.log('3. Ensure server is running on', BASE_URL);
    console.log('4. Check server logs for detailed errors');
  } else {
    console.log('✅ All tests passed! Super Admin system is working correctly.');
  }
}

testEndpoints().catch(console.error);
