import React, { createContext, useContext, useEffect, useState } from 'react';
import { adminSocket } from '../services/websocket';
import { AdminApiService } from '../services/api';

interface AuthContextType {
  token: string | null;
  isAuthenticated: boolean;
  socketConnected: boolean;
  login: (mobileNumber: string, otp: string) => Promise<void>;
  logout: () => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [token, setToken] = useState<string | null>(localStorage.getItem('admin_token'));
  const [socketConnected, setSocketConnected] = useState(false);

  useEffect(() => {
    if (token) {
      adminSocket.connect(token);
    } else {
      adminSocket.disconnect();
    }

    const handleConnectionStatus = (data: { connected: boolean }) => {
      setSocketConnected(data.connected);
    };

    adminSocket.on('connection_status', handleConnectionStatus);

    return () => {
      adminSocket.off('connection_status', handleConnectionStatus);
    };
  }, [token]);

  const login = async (mobileNumber: string, otp: string) => {
    const res = await AdminApiService.login(mobileNumber, otp);
    if (res.success && res.data.accessToken) {
      const newToken = res.data.accessToken;
      setToken(newToken);
      localStorage.setItem('admin_token', newToken);
    } else {
      throw new Error(res.message || 'Authentication failed');
    }
  };

  const logout = () => {
    AdminApiService.logout();
    setToken(null);
    setSocketConnected(false);
    adminSocket.disconnect();
  };

  return (
    <AuthContext.Provider
      value={{
        token,
        isAuthenticated: !!token,
        socketConnected,
        login,
        logout,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
