import React, { useEffect, useState } from 'react';
import { Users, FileCheck, Building2, Wallet, ArrowUpRight, Clock, ShieldCheck } from 'lucide-react';
import { AdminApiService } from '../services/api';
import { AgentSummary } from '../types';
import { Link } from 'react-router-dom';

export const Dashboard: React.FC = () => {
  const [agents, setAgents] = useState<AgentSummary[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    try {
      const res = await AdminApiService.getAgents();
      if (res.success) {
        setAgents(res.data);
      }
    } catch (_) {}
    setLoading(false);
  };

  const pendingKycCount = agents.filter((a) => a.kycStatus === 'UNDER_REVIEW' || a.status === 'KYC_INCOMPLETE').length;
  const pendingApprovalCount = agents.filter((a) => a.status === 'PENDING_APPROVAL').length;
  const approvedAgentsCount = agents.filter((a) => a.status === 'APPROVED').length;

  return (
    <div className="space-y-8">
      <div>
        <h2 className="text-2xl font-bold text-slate-900 tracking-tight">Executive Dashboard</h2>
        <p className="text-slate-500 text-sm mt-1">Real-time overview of TheNexopp Agent Network & Operations</p>
      </div>

      {/* Metrics Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <div className="bg-white border border-slate-200 p-6 rounded-2xl shadow-sm space-y-4">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-500 uppercase tracking-wider">Total Agents</span>
            <div className="p-2 bg-blue-50 text-blue-600 rounded-xl border border-blue-100">
              <Users className="h-5 w-5" />
            </div>
          </div>
          <div className="text-3xl font-extrabold text-slate-900">{agents.length}</div>
          <p className="text-xs text-slate-500 flex items-center space-x-1">
            <span className="text-emerald-700 font-semibold">{approvedAgentsCount} Active Approved</span>
          </p>
        </div>

        <div className="bg-white border border-slate-200 p-6 rounded-2xl shadow-sm space-y-4">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-500 uppercase tracking-wider">Pending KYC</span>
            <div className="p-2 bg-amber-50 text-amber-600 rounded-xl border border-amber-100">
              <FileCheck className="h-5 w-5" />
            </div>
          </div>
          <div className="text-3xl font-extrabold text-amber-600">{pendingKycCount}</div>
          <Link to="/kyc" className="text-xs text-amber-700 hover:underline flex items-center space-x-1 font-semibold">
            <span>Review Submissions</span>
            <ArrowUpRight className="h-3 w-3" />
          </Link>
        </div>

        <div className="bg-white border border-slate-200 p-6 rounded-2xl shadow-sm space-y-4">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-500 uppercase tracking-wider">Pending Approvals</span>
            <div className="p-2 bg-purple-50 text-purple-600 rounded-xl border border-purple-100">
              <Clock className="h-5 w-5" />
            </div>
          </div>
          <div className="text-3xl font-extrabold text-purple-700">{pendingApprovalCount}</div>
          <Link to="/agents" className="text-xs text-purple-700 hover:underline flex items-center space-x-1 font-semibold">
            <span>Approve Agents</span>
            <ArrowUpRight className="h-3 w-3" />
          </Link>
        </div>

        <div className="bg-white border border-slate-200 p-6 rounded-2xl shadow-sm space-y-4">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-500 uppercase tracking-wider">WebSocket Gateway</span>
            <div className="p-2 bg-emerald-50 text-emerald-600 rounded-xl border border-emerald-100">
              <ShieldCheck className="h-5 w-5" />
            </div>
          </div>
          <div className="text-3xl font-extrabold text-emerald-600">Connected</div>
          <p className="text-xs text-emerald-700 font-medium">Live Syncing to Mobile Phones</p>
        </div>
      </div>

      {/* Recent Agents Table */}
      <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-4">
        <div className="flex items-center justify-between">
          <h3 className="font-bold text-lg text-slate-900">Recent Registered Agents</h3>
          <Link to="/agents" className="text-xs font-semibold text-emerald-700 hover:underline">
            View All Agents
          </Link>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead>
              <tr className="text-xs font-semibold text-slate-500 border-b border-slate-200 uppercase tracking-wider bg-slate-50/50">
                <th className="p-3">Agent</th>
                <th className="p-3">Mobile</th>
                <th className="p-3">Work Platform</th>
                <th className="p-3">Status</th>
                <th className="p-3">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {loading ? (
                <tr>
                  <td colSpan={5} className="py-6 text-center text-slate-400">Loading recent agents...</td>
                </tr>
              ) : agents.length === 0 ? (
                <tr>
                  <td colSpan={5} className="py-6 text-center text-slate-400">No agents registered yet.</td>
                </tr>
              ) : (
                agents.slice(0, 5).map((agent) => (
                  <tr key={agent.id} className="hover:bg-slate-50 transition-colors">
                    <td className="py-4 px-3 font-semibold text-slate-900">{agent.fullName || 'New Partner'}</td>
                    <td className="py-4 px-3 text-slate-600">+91 {agent.mobileNumber}</td>
                    <td className="py-4 px-3 text-slate-600">{agent.workPlatform || 'Individual'}</td>
                    <td className="py-4 px-3">
                      <span className={`px-2.5 py-1 rounded-full text-xs font-bold ${
                        agent.status === 'APPROVED' ? 'bg-emerald-50 text-emerald-700 border border-emerald-200' :
                        agent.status === 'PENDING_APPROVAL' ? 'bg-purple-50 text-purple-700 border border-purple-200' :
                        'bg-amber-50 text-amber-700 border border-amber-200'
                      }`}>
                        {agent.status}
                      </span>
                    </td>
                    <td className="py-4 px-3">
                      <Link to="/agents" className="text-xs text-emerald-700 hover:underline font-semibold">
                        Inspect
                      </Link>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};
