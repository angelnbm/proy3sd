<template>
  <div>
    <h1 class="text-h4 font-weight-bold mb-4">Reportes Ejecutivos</h1>
    
    <v-card elevation="2">
      <v-card-title>Generar Reporte</v-card-title>
      <v-card-text>
        <v-row>
          <v-col cols="12" md="6">
            <v-select
              v-model="reportPeriod"
              :items="['week', 'month', 'year']"
              label="Period"
            ></v-select>
          </v-col>
          <v-col cols="12" md="6">
            <v-select
              v-model="reportFormat"
              :items="['json', 'csv']"
              label="Format"
            ></v-select>
          </v-col>
        </v-row>
        
        <v-btn color="primary" @click="generateReport" :loading="loading">
          Generate Report
        </v-btn>
      </v-card-text>
    </v-card>
    
    <v-card elevation="2" class="mt-4" v-if="reportData">
      <v-card-title>Report Summary</v-card-title>
      <v-card-text>
        <p><strong>Generated At:</strong> {{ reportData.generatedAt }}</p>
        <p><strong>Period:</strong> {{ reportData.period }}</p>
        <p><strong>Total Eliminations:</strong> {{ reportData.summary.totalEliminations }}</p>
        <p><strong>Total Revenue:</strong> {{ formatCurrency(reportData.summary.totalRevenue) }}</p>
        <p><strong>Average Daily:</strong> {{ reportData.summary.averageDaily.toFixed(2) }}</p>
      </v-card-text>
    </v-card>
  </div>
</template>

<script setup>
import { ref } from 'vue';
import { dashboardAPI } from '../services/api';

const reportPeriod = ref('month');
const reportFormat = ref('json');
const loading = ref(false);
const reportData = ref(null);

const generateReport = async () => {
  loading.value = true;
  try {
    const data = await dashboardAPI.getReports({
      period: reportPeriod.value,
      format: reportFormat.value
    });
    reportData.value = data;
  } catch (error) {
    console.error('Failed to generate report:', error);
  } finally {
    loading.value = false;
  }
};

const formatCurrency = (value) => {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD'
  }).format(value || 0);
};
</script>
