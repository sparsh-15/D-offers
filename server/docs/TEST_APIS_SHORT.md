# Test APIs (Short)

## 1) Bulk User Creation (Shopkeeper + Customer)

- Method: `POST`
- URL: `/api/subscription-governance/test-data/users/bulk`
- Full local URL: `http://localhost:3000/api/subscription-governance/test-data/users/bulk`
- Auth: Not required (public test endpoint)

### Request Body

```json
{
  "users": {
    "shopkeeper": [
      {
        "name": "Shopkeeper A",
        "phone": "9500000101",
        "email": "shop.a@test.local",
        "password": "pass@123",
        "city": "Bhopal",
        "state": "Madhya Pradesh",
        "region": "Central",
        "territory": "Bhopal Urban",
        "pincode": "462001",
        "address": "Zone 1",
        "gender": "male",
        "dob": "1992-05-12",
        "occupation": "Retailer",
        "aboutMe": "Running grocery business",
        "workingHours": "9AM-9PM",
        "shopRegistrationNumber": "SRN-1001",
        "gstNumber": "23ABCDE1234F1Z5",
        "electricityConsumerNumber": "ECN-778899",
        "aadhaarNumber": "XXXX-XXXX-1234",
        "panNumber": "ABCDE1234F",
        "shopRegistrationDocumentUrl": "https://cdn.test/docs/shop-reg-a.pdf",
        "gstDocumentUrl": "https://cdn.test/docs/gst-a.pdf",
        "electricityBillDocumentUrl": "https://cdn.test/docs/bill-a.pdf",
        "aadhaarDocumentUrl": "https://cdn.test/docs/aadhaar-a.pdf",
        "panDocumentUrl": "https://cdn.test/docs/pan-a.pdf",
        "maxCouponDiscountPercent": 45,
        "approvalStatus": "approved",
        "permissions": ["shopkeeper"],
        "isActive": true,
        "shopProfile": {
          "shopName": "A Mart",
          "category": "grocery",
          "city": "Bhopal",
          "pincode": "462001",
          "address": "Zone 1"
        }
      },
      {
        "name": "Shopkeeper B",
        "phone": "9500000102",
        "email": "shop.b@test.local",
        "password": "pass@123",
        "city": "Bhopal",
        "state": "Madhya Pradesh",
        "pincode": "462003",
        "address": "Zone 2",
        "approvalStatus": "approved",
        "permissions": ["shopkeeper"],
        "isActive": true,
        "shopProfile": {
          "shopName": "B Electronics",
          "category": "electronics",
          "city": "Bhopal",
          "pincode": "462003",
          "address": "Zone 2"
        }
      }
    ],
    "customer": [
      {
        "name": "Customer A",
        "phone": "9600000101",
        "email": "cust.a@test.local",
        "password": "pass@123",
        "city": "Bhopal",
        "state": "Madhya Pradesh",
        "pincode": "462001",
        "address": "MP Nagar",
        "gender": "female",
        "dob": "1998-08-20",
        "occupation": "Student",
        "aboutMe": "Loves offers",
        "approvalStatus": "approved",
        "permissions": ["customer"],
        "isActive": true
      },
      {
        "name": "Customer B",
        "phone": "9600000102",
        "email": "cust.b@test.local",
        "password": "pass@123",
        "city": "Bhopal",
        "state": "Madhya Pradesh",
        "pincode": "462003",
        "address": "Arera Colony",
        "approvalStatus": "approved",
        "permissions": ["customer"],
        "isActive": true
      }
    ]
  }
}
```

### Allowed User Fields

- Common (`shopkeeper` and `customer`):
  - `name`, `phone`, `email`, `password`, `city`, `state`, `pincode`, `address`, `gender`, `dob`, `occupation`, `aboutMe`, `approvalStatus`, `permissions`, `isActive`
- Additional for shopkeeper:
  - `region`, `territory`, `workingHours`, `maxCouponDiscountPercent`
  - `shopRegistrationNumber`, `gstNumber`, `electricityConsumerNumber`, `aadhaarNumber`, `panNumber`
  - `shopRegistrationDocumentUrl`, `gstDocumentUrl`, `electricityBillDocumentUrl`, `aadhaarDocumentUrl`, `panDocumentUrl`
  - `shopProfile` object: `shopName`, `category`, `city`, `pincode`, `address`

### Response (sample)

```json
{
  "success": true,
  "message": "Bulk users processed (shopkeeper + customer)",
  "bodyFormat": {
    "users": {
      "shopkeeper": "[{ name, phone, email?, city?, state?, pincode?, address?, shopProfile? }]",
      "customer": "[{ name, phone, email?, city?, state?, pincode?, address? }]"
    }
  },
  "data": {
    "roles": {
      "shopkeeper": { "requested": 2, "created": 2, "skipped": 0, "failed": 0 },
      "customer": { "requested": 2, "created": 2, "skipped": 0, "failed": 0 }
    },
    "geoSummary": {
      "city": "Bhopal",
      "pincode": "462001",
      "cityDistribution": { "Bhopal": 4 },
      "pincodeDistribution": { "462001": 2, "462003": 2 }
    },
    "createdSample": [
      { "id": "...", "role": "shopkeeper", "phone": "9500000001", "city": "Bhopal", "pincode": "462001" }
    ],
    "errors": []
  }
}
```

## Notes

- Endpoint is idempotent by `phone`:
  - same phone on re-run => counted in `skipped`
  - new phone => counted in `created`

## 2) Bulk Subscribe Existing Shopkeepers To Existing Plans

- Method: `POST`
- URL: `/api/subscription-governance/test-data/subscriptions/bulk`
- Full local URL: `http://localhost:3000/api/subscription-governance/test-data/subscriptions/bulk`
- Auth: Not required (public test endpoint)

### Request Body

```json
{
  "subscriptions": [
    {
      "shopkeeperPhone": "9500000101",
      "planName": "basic",
      "durationMonths": 1,
      "paymentMethod": "upi",
      "transactionId": "TXN-1001",
      "notes": "manual test mapping"
    },
    {
      "shopkeeperId": "11111111-1111-1111-1111-111111111111",
      "planTier": "silver",
      "durationMonths": 3,
      "autoRenew": false
    }
  ]
}
```

## 3) Bulk Create Offers From Shopkeepers

- Method: `POST`
- URL: `/api/subscription-governance/test-data/offers/bulk`
- Full local URL: `http://localhost:3000/api/subscription-governance/test-data/offers/bulk`
- Auth: Not required (public test endpoint)

### Request Body

```json
{
  "offers": [
    {
      "shopkeeperPhone": "9500005001",
      "title": "Flat 20% Off on Grocery",
      "description": "Weekend special",
      "category": "grocery",
      "discountType": "percentage",
      "discountValue": 20,
      "photos": [
        "https://placehold.co/1200x628?text=Offer+1"
      ],
      "termsAndConditions": "Valid once per customer",
      "validFrom": "2026-04-02T00:00:00.000Z",
      "validTo": "2026-04-20T00:00:00.000Z"
    },
    {
      "shopkeeperPhone": "9500005002",
      "title": "Rs 200 Off on Electronics",
      "description": "Limited stock",
      "category": "electronics",
      "discountType": "fixed",
      "discountValue": 200,
      "validTo": "2026-04-25T00:00:00.000Z"
    }
  ]
}
```

### Response (sample)

```json
{
  "success": true,
  "message": "Bulk offers processed",
  "bodyFormat": {
    "offers": "[{ shopkeeperId? | shopkeeperPhone?, title, description?, category?, discountType?(percentage|fixed), discountValue, photos?, termsAndConditions?, validFrom?, validTo?, status?, forceNew? }]"
  },
  "data": {
    "requested": 2,
    "created": 2,
    "skipped": 0,
    "failed": 0,
    "items": [
      {
        "shopkeeperId": "...",
        "shopkeeperPhone": "9500005001",
        "offerId": "...",
        "title": "Flat 20% Off on Grocery",
        "status": "created"
      }
    ],
    "errors": []
  }
}
```

### Curl (Windows)

```bash
curl.exe -X POST "http://localhost:3000/api/subscription-governance/test-data/offers/bulk" ^
  -H "Content-Type: application/json" ^
  -d "{\"offers\":[{\"shopkeeperPhone\":\"9500005001\",\"title\":\"Flat 20% Off on Grocery\",\"category\":\"grocery\",\"discountType\":\"percentage\",\"discountValue\":20},{\"shopkeeperPhone\":\"9500005002\",\"title\":\"Rs 200 Off on Electronics\",\"category\":\"electronics\",\"discountType\":\"fixed\",\"discountValue\":200}]}"
```

### Response (sample)

```json
{
  "success": true,
  "message": "Bulk subscriptions processed",
  "bodyFormat": {
    "subscriptions": "[{ shopkeeperId? | shopkeeperPhone?, planId? | planName? | planTier?, durationMonths?, startDate?, autoRenew?, paymentMethod?, transactionId?, notes?, forceNew? }]"
  },
  "data": {
    "requested": 2,
    "created": 1,
    "skipped": 1,
    "failed": 0,
    "items": [
      {
        "shopkeeperId": "...",
        "shopkeeperPhone": "9500000101",
        "planId": "...",
        "planName": "basic",
        "subscriptionId": "...",
        "status": "created"
      },
      {
        "shopkeeperId": "...",
        "shopkeeperPhone": "9500000102",
        "planId": "...",
        "planName": "silver_all",
        "subscriptionId": "...",
        "status": "skipped",
        "reason": "already_has_active_subscription"
      }
    ],
    "errors": []
  }
}
```
