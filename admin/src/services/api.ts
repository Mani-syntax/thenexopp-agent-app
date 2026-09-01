import axios from 'axios';
import { AgentSummary, AgentStatus, PropertyListing, PropertyStatus, PaymentRecord, PaymentAnalytics } from '../types';

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
  async login(username: string, password: string) {
    const res = await api.post('/auth/admin/login', { username, password });
    if (res.data.success) {
      localStorage.setItem('admin_token', res.data.data.accessToken);
    }
    return res.data;
  },

  logout() {
    localStorage.removeItem('admin_token');
  },

  // Agents
  async getAgents(status?: AgentStatus, search?: string): Promise<{ success: boolean; data: AgentSummary[] }> {
    const res = await api.get('/admin/agents', { params: { status, search } });
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
  async getProperties(params?: {
    status?: PropertyStatus;
    startDate?: string;
    endDate?: string;
    agentId?: string;
    search?: string;
  }): Promise<{ success: boolean; data: PropertyListing[] }> {
    const res = await api.get('/admin/properties', { params });
    return res.data;
  },

  async reviewProperty(propertyId: string, approve: boolean, rejectionReason?: string) {
    const res = await api.put(`/admin/properties/${propertyId}/review`, { approve, rejectionReason });
    return res.data;
  },

  // Earnings & Financials
  async getPayments(params?: {
    startDate?: string;
    endDate?: string;
    agentId?: string;
    search?: string;
  }): Promise<{ success: boolean; analytics: PaymentAnalytics; data: PaymentRecord[] }> {
    const res = await api.get('/admin/payments', { params });
    return res.data;
  },

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

