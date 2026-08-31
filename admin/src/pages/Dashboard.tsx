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
        <h2 className="text-2xl font-bold text-slate-100 tracking-tight">Executive Dashboard</h2>
        <p className="text-slate-400 text-sm mt-1">Real-time overview of TheNexopp Agent Network & Operations</p>
      </div>

      {/* Metrics Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <div className="bg-slate-900 border border-slate-800 p-6 rounded-2xl space-y-4">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Total Agents</span>
            <div className="p-2 bg-blue-500/10 text-blue-400 rounded-xl">
              <Users className="h-5 w-5" />
            </div>
          </div>
          <div className="text-3xl font-extrabold text-slate-100">{agents.length}</div>
          <p className="text-xs text-slate-400 flex items-center space-x-1">
            <span className="text-emerald-400 font-semibold">{approvedAgentsCount} Active Approved</span>
          </p>
        </div>

        <div className="bg-slate-900 border border-slate-800 p-6 rounded-2xl space-y-4">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Pending KYC</span>
            <div className="p-2 bg-amber-500/10 text-amber-400 rounded-xl">
              <FileCheck className="h-5 w-5" />
            </div>
          </div>
          <div className="text-3xl font-extrabold text-amber-400">{pendingKycCount}</div>
          <Link to="/kyc" className="text-xs text-amber-400 hover:underline flex items-center space-x-1">
            <span>Review Submissions</span>
            <ArrowUpRight className="h-3 w-3" />
          </Link>
        </div>

        <div className="bg-slate-900 border border-slate-800 p-6 rounded-2xl space-y-4">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Pending Approvals</span>
            <div className="p-2 bg-purple-500/10 text-purple-400 rounded-xl">
              <Clock className="h-5 w-5" />
            </div>
          </div>
          <div className="text-3xl font-extrabold text-purple-400">{pendingApprovalCount}</div>
          <Link to="/agents" className="text-xs text-purple-400 hover:underline flex items-center space-x-1">
            <span>Approve Agents</span>
            <ArrowUpRight className="h-3 w-3" />
          </Link>
        </div>

        <div className="bg-slate-900 border border-slate-800 p-6 rounded-2xl space-y-4">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">WebSocket Gateway</span>
            <div className="p-2 bg-emerald-500/10 text-emerald-400 rounded-xl">
              <ShieldCheck className="h-5 w-5" />
            </div>
          </div>
          <div className="text-3xl font-extrabold text-emerald-400">Connected</div>
          <p className="text-xs text-emerald-400">Live Syncing to Mobile Phones</p>
        </div>
      </div>

      {/* Recent Agents Table */}
      <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6 space-y-4">
        <div className="flex items-center justify-between">
          <h3 className="font-bold text-lg text-slate-100">Recent Registered Agents</h3>
          <Link to="/agents" className="text-xs font-semibold text-emerald-400 hover:underline">
            View All Agents
          </Link>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead>
              <tr className="text-xs font-semibold text-slate-400 border-b border-slate-800 uppercase tracking-wider">
                <th className="pb-3">Agent</th>
                <th className="pb-3">Mobile</th>
                <th className="pb-3">Work Platform</th>
                <th className="pb-3">Status</th>
                <th className="pb-3">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-800">
              {loading ? (
                <tr>
                  <td colSpan={5} className="py-6 text-center text-slate-500">Loading recent agents...</td>
                </tr>
              ) : agents.length === 0 ? (
                <tr>
                  <td colSpan={5} className="py-6 text-center text-slate-500">No agents registered yet.</td>
                </tr>
              ) : (
                agents.slice(0, 5).map((agent) => (
                  <tr key={agent.id} className="hover:bg-slate-800/40 transition-colors">
                    <td className="py-4 font-semibold text-slate-200">{agent.fullName || 'New Partner'}</td>
                    <td className="py-4 text-slate-400">+91 {agent.mobileNumber}</td>
                    <td className="py-4 text-slate-400">{agent.workPlatform || 'Individual'}</td>
                    <td className="py-4">
                      <span className={`px-2.5 py-1 rounded-full text-xs font-bold ${
                        agent.status === 'APPROVED' ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20' :
                        agent.status === 'PENDING_APPROVAL' ? 'bg-purple-500/10 text-purple-400 border border-purple-500/20' :
                        'bg-amber-500/10 text-amber-400 border border-amber-500/20'
                      }`}>
                        {agent.status}
                      </span>
                    </td>
                    <td className="py-4">
                      <Link to="/agents" className="text-xs text-emerald-400 hover:underline font-semibold">
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
