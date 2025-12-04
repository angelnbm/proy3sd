<template>
  <v-app>
    <v-app-bar app dark color="grey-darken-4" elevation="2">
      <v-app-bar-nav-icon @click="drawer = !drawer"></v-app-bar-nav-icon>
      <v-toolbar-title class="text-h5 font-weight-bold">
        <v-icon icon="mdi-office-building" class="mr-2"></v-icon>
        Continental
      </v-toolbar-title>
      <v-spacer></v-spacer>
      <v-chip color="success" variant="outlined" class="mr-4">
        <v-icon icon="mdi-circle" size="small" class="mr-1"></v-icon>
        conectado
      </v-chip>
      <v-btn icon="mdi-bell-outline"></v-btn>
      <v-btn icon="mdi-cog-outline"></v-btn>
    </v-app-bar>

    <v-navigation-drawer v-model="drawer" app dark color="grey-darken-3">
      <v-list density="compact" nav>
        <v-list-item
          prepend-icon="mdi-view-dashboard"
          title="Overview"
          value="overview"
          :to="{ name: 'Dashboard' }"
        ></v-list-item>
        <v-list-item
          prepend-icon="mdi-account-multiple"
          title="Assassins"
          value="assassins"
          :to="{ name: 'Assassins' }"
        ></v-list-item>
        <v-list-item
          prepend-icon="mdi-file-document"
          title="Contracts"
          value="contracts"
          :to="{ name: 'Contracts' }"
        ></v-list-item>
        <v-list-item
          prepend-icon="mdi-chart-line"
          title="Analytics"
          value="analytics"
          :to="{ name: 'Analytics' }"
        ></v-list-item>
        <v-list-item
          prepend-icon="mdi-file-chart"
          title="Reports"
          value="reports"
          :to="{ name: 'Reports' }"
        ></v-list-item>
      </v-list>
    </v-navigation-drawer>

    <v-main class="bg-grey-lighten-4">
      <v-container fluid>
        <router-view></router-view>
      </v-container>
    </v-main>

    <v-snackbar v-model="snackbar" :color="snackbarColor" :timeout="3000">
      {{ snackbarText }}
      <template v-slot:actions>
        <v-btn variant="text" @click="snackbar = false">Close</v-btn>
      </template>
    </v-snackbar>
  </v-app>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue';
import { useSocket } from './composables/useSocket';

const drawer = ref(true);
const snackbar = ref(false);
const snackbarText = ref('');
const snackbarColor = ref('success');

const { socket, connect, disconnect } = useSocket();

onMounted(() => {
  connect();
  
  // Listen for elimination events
  socket.value?.on('elimination:verified', (data) => {
    snackbarText.value = `New elimination verified: Contract ${data.contractId}`;
    snackbarColor.value = 'success';
    snackbar.value = true;
  });
});

onUnmounted(() => {
  disconnect();
});
</script>

<style scoped>
.v-app-bar-title {
  letter-spacing: 0.5px;
}
</style>
