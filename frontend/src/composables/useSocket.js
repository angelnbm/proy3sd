import { ref } from 'vue';
import { io } from 'socket.io-client';

const socket = ref(null);

export function useSocket() {
  const connect = () => {
    if (!socket.value) {
      socket.value = io('http://localhost:3000', {
        transports: ['websocket'],
        autoConnect: true
      });

      socket.value.on('connect', () => {
        console.log('WebSocket connected');
      });

      socket.value.on('disconnect', () => {
        console.log('WebSocket disconnected');
      });
    }
  };

  const disconnect = () => {
    if (socket.value) {
      socket.value.disconnect();
      socket.value = null;
    }
  };

  return {
    socket,
    connect,
    disconnect
  };
}
