<template>
  <div>
    <h1 class="text-h4 font-weight-bold mb-4">Desempeño de Asesinos</h1>
    <v-card elevation="2">
      <v-card-title>Eficiencia de Asesinos Activos</v-card-title>
      <v-card-text>
        <v-data-table
          :headers="headers"
          :items="assassins"
          :items-per-page="20"
          class="elevation-1"
        >
          <template v-slot:item.successRate="{ item }">
            <v-chip :color="getRateColor(item.successRate)" size="small">
              {{ item.successRate }}%
            </v-chip>
          </template>
          <template v-slot:item.efficiency="{ item }">
            <v-progress-linear
              :model-value="item.efficiency"
              :color="getEfficiencyColor(item.efficiency)"
              height="20"
            >
              {{ item.efficiency }}
            </v-progress-linear>
          </template>
        </v-data-table>
      </v-card-text>
    </v-card>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { metricsAPI } from '../services/api';

const assassins = ref([]);

const headers = [
  { title: 'Assassin ID', key: 'assassinId' },
  { title: 'Name', key: 'name' },
  { title: 'Total Eliminations', key: 'totalEliminations' },
  { title: 'Total Earnings', key: 'totalEarnings' },
  { title: 'Success Rate', key: 'successRate' },
  { title: 'Efficiency Score', key: 'efficiency' }
];

const loadAssassins = async () => {
  try {
    const data = await metricsAPI.getAssassins();
    assassins.value = data.assassins;
  } catch (error) {
    console.error('Failed to load assassins:', error);
  }
};

const getRateColor = (rate) => {
  if (rate >= 90) return 'success';
  if (rate >= 70) return 'warning';
  return 'error';
};

const getEfficiencyColor = (score) => {
  if (score >= 80) return 'success';
  if (score >= 60) return 'info';
  return 'warning';
};

onMounted(loadAssassins);
</script>
