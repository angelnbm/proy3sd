import { createRouter, createWebHistory } from 'vue-router';
import Dashboard from '../views/Dashboard.vue';
import Assassins from '../views/Assassins.vue';
import Contracts from '../views/Contracts.vue';
import Analytics from '../views/Analytics.vue';
import Reports from '../views/Reports.vue';

const routes = [
  {
    path: '/',
    name: 'Dashboard',
    component: Dashboard
  },
  {
    path: '/assassins',
    name: 'Assassins',
    component: Assassins
  },
  {
    path: '/contracts',
    name: 'Contracts',
    component: Contracts
  },
  {
    path: '/analytics',
    name: 'Analytics',
    component: Analytics
  },
  {
    path: '/reports',
    name: 'Reports',
    component: Reports
  }
];

const router = createRouter({
  history: createWebHistory(),
  routes
});

export default router;
