# API Documentation - Continental Dashboard

## Base URL
```
http://lxc-301:3000/api/v1
```

## Authentication
Currently no authentication required. Add JWT or API key authentication as needed.

---

## Endpoints

### Dashboard

#### GET /dashboard/overview
Returns comprehensive dashboard overview with all key metrics.

**Response:**
```json
{
  "timestamp": "2024-12-04T10:30:00.000Z",
  "overview": {
    "activeContracts": 15,
    "completedContracts": 234,
    "todayEliminations": 3,
    "monthlyRevenue": 1250000,
    "activeAssassins": 42,
    "avgContractValue": 75000
  },
  "trends": [
    {
      "date": "2024-11-04",
      "eliminations": 5,
      "revenue": 375000
    }
  ],
  "topAssassins": [
    {
      "assassinId": "ASN-001",
      "name": "John Wick",
      "totalEliminations": 47,
      "totalEarnings": 2350000,
      "successRate": 98.5,
      "recentEliminations": 3,
      "recentEarnings": 225000
    }
  ],
  "financial": {
    "totalPaid": 1250000,
    "totalTransactions": 23,
    "avgTransaction": 54347.83,
    "highestPayout": 150000,
    "lowestPayout": 25000
  }
}
```

**SLO:** < 2 seconds response time

---

#### GET /dashboard/reports
Generate executive reports for specified period.

**Query Parameters:**
- `period` (string): `week` | `month` | `year` - Default: `month`
- `format` (string): `json` | `csv` - Default: `json`

**Response (JSON):**
```json
{
  "generatedAt": "2024-12-04T10:30:00.000Z",
  "period": "month",
  "summary": {
    "totalEliminations": 78,
    "totalRevenue": 3900000,
    "averageDaily": 2.6
  },
  "trends": [...],
  "assassins": [...],
  "financial": {...}
}
```

**Response (CSV):**
```csv
Date,Eliminations,Revenue
2024-11-04,5,375000
2024-11-05,3,225000
...
```

---

#### POST /dashboard/alerts
Configure dashboard alerts and notifications.

**Request Body:**
```json
{
  "type": "elimination_threshold",
  "threshold": 10,
  "notification": {
    "email": "hightable@continental.com",
    "webhook": "https://slack.com/webhook/...",
    "slack": "#high-table-alerts"
  }
}
```

**Alert Types:**
- `elimination_threshold` - Alert when eliminations exceed threshold
- `revenue_drop` - Alert when revenue drops below threshold
- `assassin_inactive` - Alert when assassin inactive for X days
- `contract_delay` - Alert when contract takes too long

**Response:**
```json
{
  "success": true,
  "alert": {
    "id": "alert-1701686400000",
    "type": "elimination_threshold",
    "threshold": 10,
    "notification": {...},
    "createdAt": "2024-12-04T10:30:00.000Z",
    "status": "active"
  }
}
```

---

### Metrics

#### GET /metrics/eliminations
Returns elimination metrics and trends.

**Query Parameters:**
- `period` (string): `week` | `month` | `year` - Default: `month`

**Response:**
```json
{
  "period": "month",
  "totalEliminations": 78,
  "totalRevenue": 3900000,
  "averagePerDay": 2.6,
  "trends": [
    {
      "date": "2024-11-04",
      "count": 5,
      "revenue": 375000
    }
  ]
}
```

---

#### GET /metrics/financials
Returns financial metrics summary.

**Query Parameters:**
- `period` (string): `week` | `month` | `year` - Default: `month`

**Response:**
```json
{
  "period": "month",
  "totalPaid": 3900000,
  "totalTransactions": 78,
  "avgTransaction": 50000,
  "highestPayout": 150000,
  "lowestPayout": 25000
}
```

---

#### GET /metrics/assassins
Returns assassin efficiency metrics.

**Response:**
```json
{
  "totalAssassins": 42,
  "assassins": [
    {
      "assassinId": "ASN-001",
      "name": "John Wick",
      "totalEliminations": 47,
      "totalEarnings": 2350000,
      "successRate": 98.5,
      "recentEliminations": 3,
      "recentEarnings": 225000,
      "efficiency": 95.8
    }
  ]
}
```

**Efficiency Score Calculation:**
- Success Rate: 40%
- Volume (normalized): 30%
- Recent Activity: 30%

---

## WebSocket Events

### Connection
```javascript
const socket = io('http://lxc-301:3000');
```

### Events

#### elimination:verified
Emitted when a new elimination is verified and processed.

**Payload:**
```json
{
  "contractId": "CNT-2024-001",
  "assassinId": "ASN-001",
  "targetId": "TGT-789",
  "timestamp": "2024-12-04T10:30:00.000Z",
  "status": "completed"
}
```

---

## Error Responses

### 400 Bad Request
```json
{
  "success": false,
  "error": "Validation failed",
  "details": "type must be one of [elimination_threshold, revenue_drop, assassin_inactive, contract_delay]"
}
```

### 500 Internal Server Error
```json
{
  "success": false,
  "error": "Internal server error"
}
```

---

## Rate Limiting

Current implementation: None
Recommended: 100 requests per minute per IP

---

## Performance SLOs

- **Dashboard Overview**: < 2 seconds
- **Metrics Update**: < 5 seconds
- **Report Generation**: < 3 seconds
- **API Response Time**: < 500ms (avg)
- **WebSocket Latency**: < 100ms

---

## Example Usage

### cURL

```bash
# Get dashboard overview
curl http://lxc-301:3000/api/v1/dashboard/overview

# Generate monthly report
curl "http://lxc-301:3000/api/v1/dashboard/reports?period=month&format=json"

# Create alert
curl -X POST http://lxc-301:3000/api/v1/dashboard/alerts \
  -H "Content-Type: application/json" \
  -d '{
    "type": "elimination_threshold",
    "threshold": 10,
    "notification": {
      "email": "alerts@continental.com"
    }
  }'
```

### JavaScript

```javascript
import axios from 'axios';

const api = axios.create({
  baseURL: 'http://lxc-301:3000/api/v1'
});

// Get overview
const overview = await api.get('/dashboard/overview');

// Get assassin metrics
const assassins = await api.get('/metrics/assassins');
```
