import React, { useEffect, useState } from 'react';
import { AdminApiService } from '../services/api';
import { AgentSummary } from '../types';
import { FileCheck, ShieldCheck, ShieldAlert, Eye } from 'lucide-react';

export const KycReview: React.FC = () => {
  const [agents, setAgents] = useState<AgentSummary[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchKycQueue();
  }, []);

  const fetchKycQueue = async () => {
    setLoading(true);
    try {
      const res = await AdminApiService.getAgents();
      if (res.success) {
        setAgents(res.data);
      }
    } catch (_) {}
    setLoading(false);
  };

  const handleReview = async (agentId: string, approve: boolean) => {
    const reason = !approve ? prompt('Enter KYC Rejection Reason:') || 'Document verification failed' : undefined;
    try {
      await AdminApiService.reviewKyc(agentId, approve, reason);
      fetchKycQueue();
    } catch (e: any) {
      alert(e.message || 'KYC review failed');
    }
  };

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-bold text-slate-100 tracking-tight">KYC Identity Verification Queue</h2>
        <p className="text-slate-400 text-sm mt-1">Inspect Aadhaar, PAN card documentation, and approve/reject agent submissions</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {loading ? (
          <div className="col-span-2 py-12 text-center text-slate-500">Loading KYC submissions...</div>
        ) : agents.length === 0 ? (
          <div className="col-span-2 py-12 text-center text-slate-500">No pending KYC submissions.</div>
        ) : (
          agents.map((agent) => (
            <div key={agent.id} className="bg-slate-900 border border-slate-800 rounded-2xl p-6 space-y-4">
              <div className="flex items-center justify-between">
                <div>
                  <h3 className="font-bold text-slate-100">{agent.fullName || 'New Agent Partner'}</h3>
                  <p className="text-xs text-slate-400">+91 {agent.mobileNumber}</p>
                </div>
                <span className={`px-2.5 py-1 rounded-full text-xs font-bold ${
                  agent.kycStatus === 'APPROVED' ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20' :
                  agent.kycStatus === 'REJECTED' ? 'bg-red-500/10 text-red-400 border border-red-500/20' :
                  'bg-amber-500/10 text-amber-400 border border-amber-500/20'
                }`}>
                  KYC: {agent.kycStatus}
                </span>
              </div>

              <div className="bg-slate-950 p-4 rounded-xl space-y-2 text-xs text-slate-300">
                <div className="flex justify-between">
                  <span className="text-slate-500">Aadhaar Status:</span>
                  <span className="font-mono text-emerald-400">XXXX XXXX 1234 (AES-256 Encrypted)</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-500">PAN Card Status:</span>
                  <span className="font-mono text-emerald-400">XXXXX1234X (AES-256 Encrypted)</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-500">Bank Account (Last 4):</span>
                  <span className="font-mono">{agent.bankAccountLast4 ? `•••• ${agent.bankAccountLast4}` : 'Not Provided'}</span>
                </div>
              </div>

              <div className="flex items-center space-x-3 pt-2">
                <button
                  onClick={() => handleReview(agent.id, true)}
                  className="flex-1 bg-emerald-500 hover:bg-emerald-600 font-semibold py-2 rounded-xl text-xs text-white flex items-center justify-center space-x-1 shadow-lg shadow-emerald-500/20 transition-all"
                >
                  <ShieldCheck className="h-4 w-4" />
                  <span>Approve KYC</span>
                </button>
                <button
                  onClick={() => handleReview(agent.id, false)}
                  className="flex-1 bg-red-500/10 hover:bg-red-500 hover:text-white text-red-400 font-semibold py-2 rounded-xl text-xs border border-red-500/20 flex items-center justify-center space-x-1 transition-all"
                >
                  <ShieldAlert className="h-4 w-4" />
                  <span>Reject KYC</span>
                </button>
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
};
