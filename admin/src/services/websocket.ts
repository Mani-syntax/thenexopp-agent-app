import { io, Socket } from 'socket.io-client';

const WS_URL = import.meta.env.VITE_WS_URL || (window.location.hostname === 'localhost' ? 'http://localhost:3000/ws' : 'https://api.thenexopp.com/ws');

export class AdminWebSocketService {
  private socket: Socket | null = null;
  private listeners: Map<string, Array<(data: any) => void>> = new Map();

  connect(token: string) {
    if (this.socket) {
      this.socket.disconnect();
    }

    this.socket = io(WS_URL, {
      transports: ['polling'],
      upgrade: false,
      auth: { token },
      query: { token },
      autoConnect: true,
      reconnection: true,
      reconnectionAttempts: 10,
      reconnectionDelay: 2000,
    });

    this.socket.on('connect', () => {
      console.log('[Admin Socket.io] Connected to server Gateway');
      this.notify('connection_status', { connected: true });
    });

    this.socket.on('connect_error', (err) => {
      // Graceful retry without crashing
      this.notify('connection_status', { connected: false });
    });

    this.socket.on('disconnect', () => {
      console.log('[Admin Socket.io] Disconnected');
      this.notify('connection_status', { connected: false });
    });

    // Subscribed Events
    const events = [
      'agent.status.updated',
      'kyc.status.updated',
      'property.status.updated',
      'payment.created',
      'agent.registered',
    ];

    events.forEach((event) => {
      this.socket?.on(event, (data) => {
        this.notify(event, data);
      });
    });
  }

  on(event: string, callback: (data: any) => void) {
    if (!this.listeners.has(event)) {
      this.listeners.set(event, []);
    }
    this.listeners.get(event)!.push(callback);
  }

  off(event: string, callback: (data: any) => void) {
    if (!this.listeners.has(event)) return;
    const callbacks = this.listeners.get(event)!.filter((cb) => cb !== callback);
    this.listeners.set(event, callbacks);
  }

  private notify(event: string, data: any) {
    const callbacks = this.listeners.get(event);
    if (callbacks) {
      callbacks.forEach((cb) => cb(data));
    }
  }

  disconnect() {
    this.socket?.disconnect();
    this.socket = null;
  }
}

export const adminSocket = new AdminWebSocketService();
