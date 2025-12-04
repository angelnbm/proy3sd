<template>
  <v-card elevation="2" class="metric-card">
    <v-card-text>
      <div class="d-flex justify-space-between align-center">
        <div>
          <p class="text-subtitle-2 text-grey-darken-1 mb-1">{{ title }}</p>
          <h2 class="text-h4 font-weight-bold">{{ value }}</h2>
        </div>
        <v-avatar :color="color" size="56">
          <v-icon :icon="icon" size="32" color="white"></v-icon>
        </v-avatar>
      </div>
    </v-card-text>
  </v-card>
</template>

<script setup>
defineProps({
  title: String,
  value: [String, Number],
  icon: String,
  color: String
});
</script>

<style scoped>
.metric-card {
  height: 100%;
  transition: transform 0.2s;
}

</style>
