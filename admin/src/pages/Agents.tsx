import React, { useEffect, useState } from 'react';
import { AdminApiService } from '../services/api';
import { AgentSummary, AgentStatus } from '../types';
import { CheckCircle2, AlertTriangle, Search, Radio, RefreshCw, XCircle } from 'lucide-react';
import { adminSocket } from '../services/websocket';
import { Modal } from '../components/Modal';

export const Agents: React.FC = () => {
  const [agents, setAgents] = useState<AgentSummary[]>([]);
  const [loading, setLoading] = useState(true);
  const [filterStatus, setFilterStatus] = useState<string>('ALL');
  const [search, setSearch] = useState('');

  // Rejection modal state
  const [modalOpen, setModalOpen] = useState(false);
  const [selectedAgentId, setSelectedAgentId] = useState<string | null>(null);
  const [pendingStatus, setPendingStatus] = useState<AgentStatus | null>(null);
  const [rejectionReason, setRejectionReason] = useState('');

  useEffect(() => {
    fetchAgents();

    // Listen to real-time events
    const handleStatusUpdate = () => {
      fetchAgents();
    };

    adminSocket.on('agent.status.updated', handleStatusUpdate);
    adminSocket.on('kyc.status.updated', handleStatusUpdate);

    return () => {
      adminSocket.off('agent.status.updated', handleStatusUpdate);
      adminSocket.off('kyc.status.updated', handleStatusUpdate);
    };
  }, [filterStatus]);

  const fetchAgents = async () => {
    setLoading(true);
    try {
      const statusParam = filterStatus === 'ALL' ? undefined : (filterStatus as AgentStatus);
      const res = await AdminApiService.getAgents(statusParam);
      if (res.success) {
        setAgents(res.data);
      }
    } catch (_) {}
    setLoading(false);
  };

  const handleAction = (agentId: string, status: AgentStatus) => {
    if (status === 'REJECTED' || status === 'SUSPENDED') {
      setSelectedAgentId(agentId);
      setPendingStatus(status);
      setRejectionReason('');
      setModalOpen(true);
    } else {
      executeStatusUpdate(agentId, status);
    }
  };

  const executeStatusUpdate = async (agentId: string, status: AgentStatus, reason?: string) => {
    try {
      await AdminApiService.updateAgentStatus(agentId, status, reason);
      setModalOpen(false);
      fetchAgents();
    } catch (e: any) {
      alert(e.message || 'Status update failed');
    }
  };

  const filteredAgents = agents.filter((a) => {
    const nameMatch = (a.fullName || '').toLowerCase().includes(search.toLowerCase());
    const phoneMatch = (a.mobileNumber || '').includes(search);
    return nameMatch || phoneMatch;
  });

  return (
    <div className="space-y-6">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <div className="flex items-center space-x-2">
            <h2 className="text-2xl font-bold text-slate-900 tracking-tight">Agents & Human Partners</h2>
            <span className="flex items-center space-x-1 px-2.5 py-0.5 rounded-full bg-emerald-50 text-emerald-700 text-xs font-semibold border border-emerald-200">
              <Radio className="h-3 w-3 animate-pulse text-emerald-600" />
              <span>Live Socket Stream</span>
            </span>
          </div>
          <p className="text-slate-500 text-sm mt-1">Manage onboarding approvals, status transitions, and agent state in real-time</p>
        </div>

        <div className="flex items-center space-x-3">
          <button
            onClick={fetchAgents}
            className="p-2.5 bg-white border border-slate-200 rounded-xl text-slate-600 hover:text-slate-900 hover:bg-slate-50 transition-colors shadow-sm"
            title="Refresh Table"
          >
            <RefreshCw className="h-4 w-4" />
          </button>

          <div className="relative">
            <Search className="absolute left-3 top-2.5 h-4 w-4 text-slate-400" />
            <input
              type="text"
              placeholder="Search name or phone..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="bg-white border border-slate-200 rounded-xl pl-9 pr-4 py-2 text-sm text-slate-900 focus:outline-none focus:border-emerald-600 focus:ring-2 focus:ring-emerald-600/20 w-64 shadow-sm"
            />
          </div>

          <select
            value={filterStatus}
            onChange={(e) => setFilterStatus(e.target.value)}
            className="bg-white border border-slate-200 rounded-xl px-4 py-2 text-sm text-slate-900 focus:outline-none focus:border-emerald-600 focus:ring-2 focus:ring-emerald-600/20 shadow-sm"
          >
            <option value="ALL">All Statuses</option>
            <option value="PENDING_APPROVAL">Pending Approval</option>
            <option value="APPROVED">Approved</option>
            <option value="REJECTED">Rejected</option>
            <option value="SUSPENDED">Suspended</option>
          </select>
        </div>
      </div>

      <div className="bg-white border border-slate-200 rounded-2xl overflow-hidden shadow-sm">
        <table className="w-full text-left text-sm">
          <thead className="bg-slate-50 text-xs font-semibold text-slate-500 uppercase tracking-wider border-b border-slate-200">
            <tr>
              <th className="p-4">Agent Name</th>
              <th className="p-4">Mobile</th>
              <th className="p-4">Location / Area</th>
              <th className="p-4">Work Platform</th>
              <th className="p-4">KYC State</th>
              <th className="p-4">Account Status</th>
              <th className="p-4 text-right">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100">
            {loading ? (
              <tr>
                <td colSpan={7} className="py-8 text-center text-slate-400">Loading live agents database...</td>
              </tr>
            ) : filteredAgents.length === 0 ? (
              <tr>
                <td colSpan={7} className="py-8 text-center text-slate-400">No agents found matching criteria.</td>
              </tr>
            ) : (
              filteredAgents.map((agent) => (
                <tr key={agent.id} className="hover:bg-slate-50 transition-colors">
                  <td className="p-4 font-semibold text-slate-900">{agent.fullName || 'Unfilled Profile'}</td>
                  <td className="p-4 text-slate-600">+91 {agent.mobileNumber}</td>
                  <td className="p-4 text-slate-600">{agent.areaLocation || 'N/A'}</td>
                  <td className="p-4 text-slate-600">{agent.workPlatform || 'Individual'}</td>
                  <td className="p-4">
                    <span className={`px-2.5 py-1 rounded-full text-xs font-bold ${
                      agent.kycStatus === 'APPROVED' ? 'bg-emerald-50 text-emerald-700 border border-emerald-200' :
                      agent.kycStatus === 'REJECTED' ? 'bg-rose-50 text-rose-700 border border-rose-200' :
                      'bg-amber-50 text-amber-700 border border-amber-200'
                    }`}>
                      {agent.kycStatus}
                    </span>
                  </td>
                  <td className="p-4">
                    <span className={`px-2.5 py-1 rounded-full text-xs font-bold ${
                      agent.status === 'APPROVED' ? 'bg-emerald-50 text-emerald-700 border border-emerald-200' :
                      agent.status === 'PENDING_APPROVAL' ? 'bg-purple-50 text-purple-700 border border-purple-200' :
                      agent.status === 'SUSPENDED' ? 'bg-rose-50 text-rose-700 border border-rose-200' :
                      'bg-amber-50 text-amber-700 border border-amber-200'
                    }`}>
                      {agent.status}
                    </span>
                  </td>
                  <td className="p-4 text-right space-x-2">
                    {agent.status !== 'APPROVED' && (
                      <button
                        onClick={() => handleAction(agent.id, 'APPROVED')}
                        className="px-3 py-1 bg-emerald-600 text-white font-semibold rounded-lg text-xs hover:bg-emerald-700 transition-colors shadow-sm"
                      >
                        Approve
                      </button>
                    )}
                    {agent.status !== 'SUSPENDED' && (
                      <button
                        onClick={() => handleAction(agent.id, 'SUSPENDED')}
                        className="px-3 py-1 bg-rose-50 text-rose-700 border border-rose-200 font-semibold rounded-lg text-xs hover:bg-rose-600 hover:text-white transition-colors"
                      >
                        Suspend
                      </button>
                    )}
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {/* Rejection / Suspension Reason Modal */}
      <Modal
        isOpen={modalOpen}
        onClose={() => setModalOpen(false)}
        title={`Confirm ${pendingStatus === 'SUSPENDED' ? 'Account Suspension' : 'Rejection'}`}
      >
        <div className="space-y-4">
          <p className="text-xs text-slate-500">
            Please enter the official reason for updating this agent's status. This will be transmitted live to their mobile phone.
          </p>
          <div>
            <label className="block text-xs font-semibold text-slate-700 mb-1">Reason / Rationale</label>
            <textarea
              value={rejectionReason}
              onChange={(e) => setRejectionReason(e.target.value)}
              rows={3}
              placeholder="e.g. Document verification failed or terms policy violation"
              className="w-full bg-slate-50 border border-slate-300 rounded-xl p-3 text-xs text-slate-900 focus:outline-none focus:border-rose-500 focus:bg-white"
            />
          </div>

          <div className="flex justify-end space-x-3 pt-2">
            <button
              onClick={() => setModalOpen(false)}
              className="px-4 py-2 bg-slate-100 text-slate-600 rounded-xl text-xs font-semibold hover:bg-slate-200 hover:text-slate-900"
            >
              Cancel
            </button>
            <button
              onClick={() => selectedAgentId && pendingStatus && executeStatusUpdate(selectedAgentId, pendingStatus, rejectionReason)}
              className="px-4 py-2 bg-rose-600 hover:bg-rose-700 text-white rounded-xl text-xs font-semibold shadow-md shadow-rose-600/15"
            >
              Confirm Update & Send Live Notification
            </button>
          </div>
        </div>
      </Modal>
    </div>
  );
};
