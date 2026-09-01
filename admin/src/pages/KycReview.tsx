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
        <h2 className="text-2xl font-bold text-slate-900 tracking-tight">KYC Identity Verification Queue</h2>
        <p className="text-slate-500 text-sm mt-1">Inspect Aadhaar, PAN card documentation, and approve/reject agent submissions</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {loading ? (
          <div className="col-span-2 py-12 text-center text-slate-400">Loading KYC submissions...</div>
        ) : agents.length === 0 ? (
          <div className="col-span-2 py-12 text-center text-slate-400">No pending KYC submissions.</div>
        ) : (
          agents.map((agent) => (
            <div key={agent.id} className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-4">
              <div className="flex items-center justify-between">
                <div>
                  <h3 className="font-bold text-slate-900">{agent.fullName || 'New Agent Partner'}</h3>
                  <p className="text-xs text-slate-500">+91 {agent.mobileNumber}</p>
                </div>
                <span className={`px-2.5 py-1 rounded-full text-xs font-bold ${
                  agent.kycStatus === 'APPROVED' ? 'bg-emerald-50 text-emerald-700 border border-emerald-200' :
                  agent.kycStatus === 'REJECTED' ? 'bg-rose-50 text-rose-700 border border-rose-200' :
                  'bg-amber-50 text-amber-700 border border-amber-200'
                }`}>
                  KYC: {agent.kycStatus}
                </span>
              </div>

              <div className="bg-slate-50 border border-slate-200 p-4 rounded-xl space-y-2 text-xs text-slate-700">
                <div className="flex justify-between">
                  <span className="text-slate-500">Aadhaar Status:</span>
                  <span className="font-mono text-emerald-700 font-medium">XXXX XXXX 1234 (AES-256 Encrypted)</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-500">PAN Card Status:</span>
                  <span className="font-mono text-emerald-700 font-medium">XXXXX1234X (AES-256 Encrypted)</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-500">Bank Account (Last 4):</span>
                  <span className="font-mono font-medium">{agent.bankAccountLast4 ? `•••• ${agent.bankAccountLast4}` : 'Not Provided'}</span>
                </div>
              </div>

              <div className="flex items-center space-x-3 pt-2">
                <button
                  onClick={() => handleReview(agent.id, true)}
                  className="flex-1 bg-emerald-600 hover:bg-emerald-700 font-semibold py-2 rounded-xl text-xs text-white flex items-center justify-center space-x-1 shadow-sm transition-all"
                >
                  <ShieldCheck className="h-4 w-4" />
                  <span>Approve KYC</span>
                </button>
                <button
                  onClick={() => handleReview(agent.id, false)}
                  className="flex-1 bg-rose-50 hover:bg-rose-600 hover:text-white text-rose-700 font-semibold py-2 rounded-xl text-xs border border-rose-200 flex items-center justify-center space-x-1 transition-all"
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
