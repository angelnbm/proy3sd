import axios from 'axios';

const api = axios.create({
  baseURL: '/api/v1',
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json'
  }
});

// Request interceptor
api.interceptors.request.use(
  (config) => {
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Response interceptor
api.interceptors.response.use(
  (response) => {
    return response.data;
  },
  (error) => {
    console.error('API Error:', error);
    return Promise.reject(error);
  }
);

// Dashboard API
export const dashboardAPI = {
  getOverview: () => api.get('/dashboard/overview'),
  getReports: (params) => api.get('/dashboard/reports', { params }),
  createAlert: (data) => api.post('/dashboard/alerts', data)
};

// Metrics API
export const metricsAPI = {
  getEliminations: (params) => api.get('/metrics/eliminations', { params }),
  getFinancials: (params) => api.get('/metrics/financials', { params }),
  getAssassins: () => api.get('/metrics/assassins')
};

export default api;
