import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { AdminApiService } from '../services/api';
import { AgentSummary, AgentStatus, PropertyListing } from '../types';
import {
  CheckCircle2,
  AlertTriangle,
  Search,
  Radio,
  RefreshCw,
  XCircle,
  Building2,
  ExternalLink,
  MapPin,
  Clock,
  Layers,
  Phone,
  Eye,
  Layers3,
} from 'lucide-react';
import { adminSocket } from '../services/websocket';
import { Modal } from '../components/Modal';

export const Agents: React.FC = () => {
  const navigate = useNavigate();
  const [agents, setAgents] = useState<AgentSummary[]>([]);
  const [loading, setLoading] = useState(true);
  const [filterStatus, setFilterStatus] = useState<string>('ALL');
  const [search, setSearch] = useState('');

  // Rejection modal state
  const [modalOpen, setModalOpen] = useState(false);
  const [selectedAgentId, setSelectedAgentId] = useState<string | null>(null);
  const [pendingStatus, setPendingStatus] = useState<AgentStatus | null>(null);
  const [rejectionReason, setRejectionReason] = useState('');

  // Agent Listings Modal State
  const [selectedAgentForListings, setSelectedAgentForListings] = useState<AgentSummary | null>(null);
  const [agentProperties, setAgentProperties] = useState<PropertyListing[]>([]);
  const [loadingAgentProperties, setLoadingAgentProperties] = useState(false);

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

  // Open Agent Listings
  const handleOpenAgentListings = async (agent: AgentSummary) => {
    setSelectedAgentForListings(agent);
    setLoadingAgentProperties(true);
    try {
      const res = await AdminApiService.getProperties({ agentId: agent.id });
      if (res.success) {
        setAgentProperties(res.data);
      }
    } catch (_) {}
    setLoadingAgentProperties(false);
  };

  const handleReviewPropertyFromModal = async (propertyId: string, approve: boolean) => {
    const reason = !approve ? prompt('Enter rejection reason:') || 'Property criteria not met' : undefined;
    try {
      await AdminApiService.reviewProperty(propertyId, approve, reason);
      if (selectedAgentForListings) {
        handleOpenAgentListings(selectedAgentForListings);
      }
      fetchAgents();
    } catch (e: any) {
      alert(e.message || 'Property review action failed');
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
          <p className="text-slate-500 text-sm mt-1">
            Click any agent to inspect their full property portfolio, performance stats, and payout history
          </p>
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
              <th className="p-4">Mobile & Area</th>
              <th className="p-4">Listings Performance</th>
              <th className="p-4">Money Transferred (₹)</th>
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
                <tr
                  key={agent.id}
                  className="hover:bg-slate-50 transition-colors cursor-pointer group"
                  onClick={() => handleOpenAgentListings(agent)}
                >
                  <td className="p-4">
                    <div className="flex items-center space-x-3">
                      <div className="h-9 w-9 rounded-xl bg-slate-100 group-hover:bg-emerald-100 group-hover:text-emerald-800 text-slate-700 font-extrabold flex items-center justify-center text-xs transition-colors">
                        {agent.fullName ? agent.fullName.charAt(0).toUpperCase() : 'A'}
                      </div>
                      <div>
                        <span className="font-bold text-slate-900 group-hover:text-emerald-700 block transition-colors">
                          {agent.fullName || 'Unfilled Profile'}
                        </span>
                        <span className="text-xs text-slate-400">ID: {agent.id.substring(0, 8)}...</span>
                      </div>
                    </div>
                  </td>
                  <td className="p-4">
                    <div className="text-slate-900 font-semibold">+91 {agent.mobileNumber}</div>
                    <div className="text-xs text-slate-500">{agent.areaLocation || 'N/A'} • {agent.workPlatform || 'Individual'}</div>
                  </td>
                  <td className="p-4">
                    <div className="flex items-center space-x-2">
                      <button
                        onClick={(e) => {
                          e.stopPropagation();
                          handleOpenAgentListings(agent);
                        }}
                        className="font-extrabold text-slate-900 text-sm hover:underline flex items-center space-x-1"
                      >
                        <Building2 className="h-3.5 w-3.5 text-emerald-600" />
                        <span>{agent.totalListings || 0} Total</span>
                      </button>
                      <span className="text-slate-300">•</span>
                      <span className="px-2 py-0.5 rounded-md bg-emerald-50 text-emerald-700 text-xs font-bold border border-emerald-200" title="Accepted / Approved">
                        {agent.acceptedListings || 0} Accepted
                      </span>
                      {(agent.rejectedListings || 0) > 0 && (
                        <span className="px-2 py-0.5 rounded-md bg-rose-50 text-rose-700 text-xs font-bold border border-rose-200" title="Rejected">
                          {agent.rejectedListings} Rejected
                        </span>
                      )}
                    </div>
                  </td>
                  <td className="p-4">
                    <div className="font-extrabold text-emerald-700 text-base">
                      ₹{Number(agent.totalPaid || 0).toLocaleString('en-IN')}
                    </div>
                    {(agent.pendingEarnings || 0) > 0 && (
                      <div className="text-[11px] text-amber-600 font-semibold">
                        ₹{Number(agent.pendingEarnings).toLocaleString('en-IN')} Pending
                      </div>
                    )}
                  </td>
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
                  <td className="p-4 text-right space-x-2" onClick={(e) => e.stopPropagation()}>
                    <button
                      onClick={() => handleOpenAgentListings(agent)}
                      className="px-2.5 py-1.5 bg-slate-100 hover:bg-slate-200 text-slate-700 font-semibold rounded-lg text-xs transition-colors inline-flex items-center space-x-1"
                      title="View all properties by this agent"
                    >
                      <Building2 className="h-3 w-3" />
                      <span>Listings</span>
                    </button>
                    {agent.status !== 'APPROVED' && (
                      <button
                        onClick={() => handleAction(agent.id, 'APPROVED')}
                        className="px-3 py-1.5 bg-emerald-600 text-white font-semibold rounded-lg text-xs hover:bg-emerald-700 transition-colors shadow-sm"
                      >
                        Approve
                      </button>
                    )}
                    {agent.status !== 'SUSPENDED' && (
                      <button
                        onClick={() => handleAction(agent.id, 'SUSPENDED')}
                        className="px-3 py-1.5 bg-rose-50 text-rose-700 border border-rose-200 font-semibold rounded-lg text-xs hover:bg-rose-600 hover:text-white transition-colors"
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

      {/* Selected Agent Listings Modal */}
      {selectedAgentForListings && (
        <Modal
          isOpen={!!selectedAgentForListings}
          onClose={() => setSelectedAgentForListings(null)}
          title={`Properties Listed by ${selectedAgentForListings.fullName || 'Agent'}`}
        >
          <div className="space-y-6">
            {/* Agent Summary Banner */}
            <div className="bg-slate-50 border border-slate-200 rounded-2xl p-4 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
              <div className="flex items-center space-x-3">
                <div className="h-12 w-12 rounded-2xl bg-emerald-600 text-white font-extrabold flex items-center justify-center text-lg shadow-sm">
                  {selectedAgentForListings.fullName ? selectedAgentForListings.fullName.charAt(0).toUpperCase() : 'A'}
                </div>
                <div>
                  <h3 className="font-bold text-base text-slate-900">{selectedAgentForListings.fullName || 'Agent Partner'}</h3>
                  <div className="text-xs text-slate-500 flex items-center space-x-2 mt-0.5">
                    <span>+91 {selectedAgentForListings.mobileNumber}</span>
                    <span>•</span>
                    <span>{selectedAgentForListings.areaLocation || 'Bangalore'}</span>
                    <span>•</span>
                    <span className="font-bold text-emerald-700">₹{Number(selectedAgentForListings.totalPaid || 0).toLocaleString('en-IN')} Paid</span>
                  </div>
                </div>
              </div>

              <div className="flex items-center space-x-2">
                <button
                  onClick={() => {
                    navigate(`/properties?agentId=${selectedAgentForListings.id}`);
                  }}
                  className="px-3 py-1.5 bg-emerald-600 hover:bg-emerald-700 text-white rounded-xl text-xs font-semibold flex items-center space-x-1.5 shadow-sm transition-colors"
                >
                  <span>Open in Property Page</span>
                  <ExternalLink className="h-3.5 w-3.5" />
                </button>
              </div>
            </div>

            {/* Listings Grid */}
            <div>
              <div className="flex items-center justify-between mb-3">
                <h4 className="font-bold text-sm text-slate-900">
                  Agent Listings Catalog ({agentProperties.length})
                </h4>
                <div className="text-xs font-semibold text-slate-500 space-x-2">
                  <span className="text-emerald-700">{agentProperties.filter((p) => p.status === 'APPROVED').length} Approved</span>
                  <span>•</span>
                  <span className="text-amber-600">{agentProperties.filter((p) => p.status === 'SUBMITTED' || p.status === 'UNDER_REVIEW').length} Under Review</span>
                  <span>•</span>
                  <span className="text-rose-600">{agentProperties.filter((p) => p.status === 'REJECTED').length} Rejected</span>
                </div>
              </div>

              {loadingAgentProperties ? (
                <div className="py-12 text-center text-slate-400 text-xs">Loading agent properties...</div>
              ) : agentProperties.length === 0 ? (
                <div className="py-12 text-center text-slate-400 bg-slate-50 border border-slate-200 rounded-2xl">
                  <Building2 className="h-8 w-8 mx-auto text-slate-300 mb-2" />
                  <p className="font-semibold text-slate-700 text-sm">No Properties Submitted Yet</p>
                  <p className="text-xs text-slate-400 mt-0.5">This agent has not posted any properties yet.</p>
                </div>
              ) : (
                <div className="space-y-3 max-h-[50vh] overflow-y-auto pr-1">
                  {agentProperties.map((prop) => {
                    const primaryImg = prop.images?.find((i) => i.isPrimary) || prop.images?.[0];
                    return (
                      <div
                        key={prop.id}
                        className="bg-white border border-slate-200 rounded-xl p-3 shadow-sm flex flex-col sm:flex-row sm:items-center justify-between gap-3 hover:border-slate-300 transition-all"
                      >
                        <div className="flex items-center space-x-3 min-w-0">
                          {primaryImg?.url ? (
                            <img
                              src={primaryImg.url}
                              alt={prop.title}
                              className="h-16 w-16 rounded-lg object-cover shrink-0 border border-slate-200"
                            />
                          ) : (
                            <div className="h-16 w-16 rounded-lg bg-slate-100 flex items-center justify-center text-slate-400 shrink-0">
                              <Building2 className="h-6 w-6" />
                            </div>
                          )}

                          <div className="min-w-0">
                            <div className="flex items-center space-x-2">
                              <span className="px-2 py-0.5 bg-slate-100 text-slate-700 rounded text-[10px] font-bold">
                                {prop.category.replace('_', ' ')}
                              </span>
                              <span
                                className={`px-2 py-0.5 rounded text-[10px] font-extrabold ${
                                  prop.status === 'APPROVED'
                                    ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                                    : prop.status === 'REJECTED'
                                    ? 'bg-rose-50 text-rose-700 border border-rose-200'
                                    : 'bg-amber-50 text-amber-700 border border-amber-200'
                                }`}
                              >
                                {prop.status}
                              </span>
                            </div>

                            <h4 className="font-bold text-sm text-slate-900 truncate mt-1">{prop.title}</h4>

                            <div className="flex items-center space-x-3 text-xs text-slate-500 mt-0.5">
                              <span className="font-extrabold text-emerald-700">₹{Number(prop.price).toLocaleString('en-IN')}</span>
                              <span>•</span>
                              <span className="truncate flex items-center space-x-1">
                                <MapPin className="h-3 w-3 text-slate-400 inline" />
                                <span>{prop.location}</span>
                              </span>
                              <span>•</span>
                              <span className="text-[11px] text-slate-400">
                                {new Date(prop.createdAt).toLocaleDateString('en-IN', { day: 'numeric', month: 'short' })}
                              </span>
                            </div>
                          </div>
                        </div>

                        {/* Action buttons */}
                        <div className="flex items-center space-x-2 shrink-0 self-end sm:self-center">
                          {prop.status !== 'APPROVED' && (
                            <button
                              onClick={() => handleReviewPropertyFromModal(prop.id, true)}
                              className="px-3 py-1.5 bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg text-xs font-semibold shadow-sm"
                            >
                              Approve
                            </button>
                          )}
                          {prop.status !== 'REJECTED' && (
                            <button
                              onClick={() => handleReviewPropertyFromModal(prop.id, false)}
                              className="px-3 py-1.5 bg-rose-50 hover:bg-rose-600 hover:text-white text-rose-700 border border-rose-200 rounded-lg text-xs font-semibold"
                            >
                              Reject
                            </button>
                          )}
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}
            </div>
          </div>
        </Modal>
      )}

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
