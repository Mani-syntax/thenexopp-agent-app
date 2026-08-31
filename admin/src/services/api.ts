import axios from 'axios';
import { AgentSummary, AgentStatus } from '../types';

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || (window.location.hostname === 'localhost' ? 'http://localhost:3000/api/v1' : 'https://api.thenexopp.com/api/v1');

export const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Add bearer token interceptor
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('admin_token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

export const AdminApiService = {
  // Authentication
  async login(mobileNumber: string, otp: string) {
    const res = await api.post('/auth/verify-otp', { mobileNumber, otp, deviceId: 'Admin-Web-Portal' });
    if (res.data.success) {
      localStorage.setItem('admin_token', res.data.data.accessToken);
    }
    return res.data;
  },

  logout() {
    localStorage.removeItem('admin_token');
  },

  // Agents
  async getAgents(status?: AgentStatus): Promise<{ success: boolean; data: AgentSummary[] }> {
    const res = await api.get('/admin/agents', { params: { status } });
    return res.data;
  },

  async reviewKyc(agentId: string, approve: boolean, rejectionReason?: string) {
    const res = await api.put(`/admin/agents/${agentId}/kyc`, { approve, rejectionReason });
    return res.data;
  },

  async updateAgentStatus(agentId: string, status: AgentStatus, rejectionReason?: string) {
    const res = await api.put(`/admin/agents/${agentId}/status`, { status, rejectionReason });
    return res.data;
  },

  // Properties
  async reviewProperty(propertyId: string, approve: boolean, rejectionReason?: string) {
    const res = await api.put(`/admin/properties/${propertyId}/review`, { approve, rejectionReason });
    return res.data;
  },

  // Earnings & Financials
  async createEarning(agentId: string, title: string, amount: number, propertyId?: string) {
    const res = await api.post('/admin/earnings', { agentId, title, amount, propertyId });
    return res.data;
  },

  async recordPayment(agentId: string, amount: number, transactionId: string, paymentMethod = 'UPI', earningId?: string, paymentProofKey?: string) {
    const res = await api.post('/admin/payments', {
      agentId,
      amount,
      transactionId,
      paymentMethod,
      earningId,
      paymentProofKey,
    });
    return res.data;
  },
};
