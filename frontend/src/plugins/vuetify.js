import 'vuetify/styles';
import { createVuetify } from 'vuetify';
import * as components from 'vuetify/components';
import * as directives from 'vuetify/directives';
import '@mdi/font/css/materialdesignicons.css';

const continentalTheme = {
  dark: false,
  colors: {
    primary: '#1a1a1a',
    secondary: '#b8860b',
    accent: '#82B1FF',
    error: '#FF5252',
    info: '#2196F3',
    success: '#4CAF50',
    warning: '#FFC107',
    background: '#f5f5f5',
    surface: '#ffffff'
  }
};

export default createVuetify({
  components,
  directives,
  theme: {
    defaultTheme: 'continentalTheme',
    themes: {
      continentalTheme
    }
  },
  icons: {
    defaultSet: 'mdi'
  }
});
