<template>
  <div>
    <v-row>
      <v-col cols="12">
        <h1 class="text-h4 font-weight-bold mb-4">Vista General</h1>
        <p class="text-subtitle-1 text-grey-darken-1">Resumen de Operaciones de High Table Continental</p>
      </v-col>
    </v-row>

    <!-- Key Metrics Cards -->
    <v-row>
      <v-col cols="12" md="3" sm="6">
        <MetricCard
          title="Contratos Activos"
          :value="overview.activeContracts"
          icon="mdi-file-document-outline"
          color="primary"
        />
      </v-col>
      <v-col cols="12" md="3" sm="6">
        <MetricCard
          title="Eliminaciones de Hoy"
          :value="overview.todayEliminations"
          icon="mdi-target"
          color="error"
        />
      </v-col>
      <v-col cols="12" md="3" sm="6">
        <MetricCard
          title="Ingresos Mensuales"
          :value="formatCurrency(overview.monthlyRevenue)"
          icon="mdi-currency-usd"
          color="success"
        />
      </v-col>
      <v-col cols="12" md="3" sm="6">
        <MetricCard
          title="Asesinos Activos"
          :value="overview.activeAssassins"
          icon="mdi-account-multiple"
          color="info"
        />
      </v-col>
    </v-row>

    <!-- Charts Row -->
    <v-row class="mt-4">
      <v-col cols="12" md="8">
        <v-card elevation="2">
          <v-card-title class="text-h6">Tendencias de Eliminación (30 días)</v-card-title>
          <v-card-text>
            <LineChart :chart-data="eliminationChartData" />
          </v-card-text>
        </v-card>
      </v-col>
      <v-col cols="12" md="4">
        <v-card elevation="2">
          <v-card-title class="text-h6">Resumen Financiero</v-card-title>
          <v-card-text>
            <v-list density="compact">
              <v-list-item>
                <v-list-item-title>Total Pagado</v-list-item-title>
                <v-list-item-subtitle class="text-h6 text-success">
                  {{ formatCurrency(financial.totalPaid) }}
                </v-list-item-subtitle>
              </v-list-item>
              <v-list-item>
                <v-list-item-title>Promedio de Transacción</v-list-item-title>
                <v-list-item-subtitle class="text-h6">
                  {{ formatCurrency(financial.avgTransaction) }}
                </v-list-item-subtitle>
              </v-list-item>
              <v-list-item>
                <v-list-item-title>Pago Más Alto</v-list-item-title>
                <v-list-item-subtitle class="text-h6 text-warning">
                  {{ formatCurrency(financial.highestPayout) }}
                </v-list-item-subtitle>
              </v-list-item>
              <v-list-item>
                <v-list-item-title>Total Transacciones</v-list-item-title>
                <v-list-item-subtitle class="text-h6">
                  {{ financial.totalTransactions }}
                </v-list-item-subtitle>
              </v-list-item>
            </v-list>
          </v-card-text>
        </v-card>
      </v-col>
    </v-row>

    <!-- Top Assassins -->
    <v-row class="mt-4">
      <v-col cols="12">
        <v-card elevation="2">
          <v-card-title class="text-h6">Asesinos con Mejor Desempeño</v-card-title>
          <v-card-text>
            <v-table>
              <thead>
                <tr>
                  <th>Asesino</th>
                  <th>Total Eliminación</th>
                  <th>Total Ganancias</th>
                  <th>Tasa de Éxito</th>
                  <th>Actividad Reciente</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="assassin in topAssassins" :key="assassin.assassinId">
                  <td class="font-weight-medium">{{ assassin.name }}</td>
                  <td>{{ assassin.totalEliminations }}</td>
                  <td class="text-success">{{ formatCurrency(assassin.totalEarnings) }}</td>
                  <td>
                    <v-chip :color="getRateColor(assassin.successRate)" size="small">
                      {{ assassin.successRate }}%
                    </v-chip>
                  </td>
                  <td>{{ assassin.recentEliminations }} ({{ formatCurrency(assassin.recentEarnings) }})</td>
                </tr>
              </tbody>
            </v-table>
          </v-card-text>
        </v-card>
      </v-col>
    </v-row>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue';
import { dashboardAPI } from '../services/api';
import { useSocket } from '../composables/useSocket';
import MetricCard from '../components/MetricCard.vue';
import LineChart from '../components/LineChart.vue';

const overview = ref({
  activeContracts: 0,
  completedContracts: 0,
  todayEliminations: 0,
  monthlyRevenue: 0,
  activeAssassins: 0,
  avgContractValue: 0
});

const trends = ref([]);
const topAssassins = ref([]);
const financial = ref({
  totalPaid: 0,
  totalTransactions: 0,
  avgTransaction: 0,
  highestPayout: 0,
  lowestPayout: 0
});

const { socket } = useSocket();

const eliminationChartData = computed(() => ({
  labels: trends.value.map(t => new Date(t.date).toLocaleDateString()),
  datasets: [
    {
      label: 'Eliminations',
      data: trends.value.map(t => t.eliminations),
      borderColor: '#1a1a1a',
      backgroundColor: 'rgba(26, 26, 26, 0.1)',
      tension: 0.4
    },
    {
      label: 'Revenue',
      data: trends.value.map(t => t.revenue),
      borderColor: '#b8860b',
      backgroundColor: 'rgba(184, 134, 11, 0.1)',
      tension: 0.4,
      yAxisID: 'y1'
    }
  ]
}));

const loadDashboard = async () => {
  try {
    const data = await dashboardAPI.getOverview();
    overview.value = data.overview;
    trends.value = data.trends;
    topAssassins.value = data.topAssassins;
    financial.value = data.financial;
  } catch (error) {
    console.error('Failed to load dashboard:', error);
  }
};

const formatCurrency = (value) => {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 0
  }).format(value || 0);
};

const getRateColor = (rate) => {
  if (rate >= 90) return 'success';
  if (rate >= 70) return 'warning';
  return 'error';
};

onMounted(() => {
  loadDashboard();
  
  // Refresh every 5 seconds to meet SLO
  const interval = setInterval(loadDashboard, 5000);
  
  // Listen for real-time updates
  socket.value?.on('elimination:verified', () => {
    loadDashboard();
  });
  
  return () => clearInterval(interval);
});
</script>
