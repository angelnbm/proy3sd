<template>
  <div>
    <h1 class="text-h4 font-weight-bold mb-4">Estadísticas</h1>
    
    <v-row>
      <v-col cols="12" md="6">
        <v-card elevation="2">
          <v-card-title>Métricas de Eliminación</v-card-title>
          <v-card-text>
            <v-select
              v-model="eliminationPeriod"
              :items="['week', 'month', 'year']"
              label="Periodo"
              @update:model-value="loadEliminationMetrics"
            ></v-select>
            <div v-if="eliminationMetrics">
              <p>Total: {{ eliminationMetrics.totalEliminations }}</p>
              <p>Revenue: {{ formatCurrency(eliminationMetrics.totalRevenue) }}</p>
              <p>Avg/Day: {{ eliminationMetrics.averagePerDay.toFixed(2) }}</p>
            </div>
          </v-card-text>
        </v-card>
      </v-col>
      
      <v-col cols="12" md="6">
        <v-card elevation="2">
          <v-card-title>Métricas Financieras</v-card-title>
          <v-card-text>
            <v-select
              v-model="financialPeriod"
              :items="['week', 'month', 'year']"
              label="Periodo"
              @update:model-value="loadFinancialMetrics"
            ></v-select>
            <div v-if="financialMetrics">
              <p>Total Paid: {{ formatCurrency(financialMetrics.totalPaid) }}</p>
              <p>Transactions: {{ financialMetrics.totalTransactions }}</p>
              <p>Avg: {{ formatCurrency(financialMetrics.avgTransaction) }}</p>
            </div>
          </v-card-text>
        </v-card>
      </v-col>
    </v-row>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { metricsAPI } from '../services/api';

const eliminationPeriod = ref('month');
const financialPeriod = ref('month');
const eliminationMetrics = ref(null);
const financialMetrics = ref(null);

const loadEliminationMetrics = async () => {
  try {
    const data = await metricsAPI.getEliminations({ period: eliminationPeriod.value });
    eliminationMetrics.value = data;
  } catch (error) {
    console.error('Failed to load elimination metrics:', error);
  }
};

const loadFinancialMetrics = async () => {
  try {
    const data = await metricsAPI.getFinancials({ period: financialPeriod.value });
    financialMetrics.value = data;
  } catch (error) {
    console.error('Failed to load financial metrics:', error);
  }
};

const formatCurrency = (value) => {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD'
  }).format(value || 0);
};

onMounted(() => {
  loadEliminationMetrics();
  loadFinancialMetrics();
});
</script>
