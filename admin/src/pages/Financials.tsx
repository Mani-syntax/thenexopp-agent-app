import React, { useState } from 'react';
import { AdminApiService } from '../services/api';
import { Wallet, DollarSign, Send, CheckCircle2 } from 'lucide-react';

export const Financials: React.FC = () => {
  const [tab, setTab] = useState<'earning' | 'payout'>('earning');

  // Earning form state
  const [earningAgentId, setEarningAgentId] = useState('');
  const [earningTitle, setEarningTitle] = useState('');
  const [earningAmount, setEarningAmount] = useState('');

  // Payout form state
  const [payoutAgentId, setPayoutAgentId] = useState('');
  const [payoutAmount, setPayoutAmount] = useState('');
  const [txnId, setTxnId] = useState('');
  const [paymentMethod, setPaymentMethod] = useState('UPI');

  const [loading, setLoading] = useState(false);
  const [successMsg, setSuccessMsg] = useState('');

  const handleAddEarning = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setSuccessMsg('');

    try {
      await AdminApiService.createEarning(earningAgentId.trim(), earningTitle.trim(), Number(earningAmount));
      setSuccessMsg(`Successfully credited ₹${Number(earningAmount).toLocaleString('en-IN')} to agent!`);
      setEarningAgentId('');
      setEarningTitle('');
      setEarningAmount('');
    } catch (err: any) {
      alert(err.message || 'Failed to add earning');
    } finally {
      setLoading(false);
    }
  };

  const handleRecordPayout = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setSuccessMsg('');

    try {
      await AdminApiService.recordPayment(payoutAgentId.trim(), Number(payoutAmount), txnId.trim(), paymentMethod);
      setSuccessMsg(`Successfully recorded payout transaction ${txnId}!`);
      setPayoutAgentId('');
      setPayoutAmount('');
      setTxnId('');
    } catch (err: any) {
      alert(err.message || 'Failed to record payment');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-6 max-w-3xl">
      <div>
        <h2 className="text-2xl font-bold text-slate-100 tracking-tight">Earnings & Payout Ledger</h2>
        <p className="text-slate-400 text-sm mt-1">Issue agent commissions, record payout transactions, and attach receipts</p>
      </div>

      {successMsg && (
        <div className="bg-emerald-500/10 border border-emerald-500/30 text-emerald-400 p-4 rounded-xl text-sm font-medium flex items-center space-x-2">
          <CheckCircle2 className="h-5 w-5" />
          <span>{successMsg}</span>
        </div>
      )}

      {/* Tabs */}
      <div className="flex border-b border-slate-800 space-x-8">
        <button
          onClick={() => { setTab('earning'); setSuccessMsg(''); }}
          className={`pb-3 font-semibold text-sm transition-colors border-b-2 ${
            tab === 'earning' ? 'border-emerald-500 text-emerald-400' : 'border-transparent text-slate-400 hover:text-slate-200'
          }`}
        >
          Credit Agent Commission
        </button>
        <button
          onClick={() => { setTab('payout'); setSuccessMsg(''); }}
          className={`pb-3 font-semibold text-sm transition-colors border-b-2 ${
            tab === 'payout' ? 'border-emerald-500 text-emerald-400' : 'border-transparent text-slate-400 hover:text-slate-200'
          }`}
        >
          Record Payout Transaction
        </button>
      </div>

      {tab === 'earning' ? (
        <form onSubmit={handleAddEarning} className="bg-slate-900 border border-slate-800 rounded-2xl p-6 space-y-4">
          <div>
            <label className="block text-xs font-semibold text-slate-400 mb-1">Agent UUID</label>
            <input
              type="text"
              required
              value={earningAgentId}
              onChange={(e) => setEarningAgentId(e.target.value)}
              placeholder="e.g. 123e4567-e89b-12d3-a456-426614174000"
              className="w-full bg-slate-800 border border-slate-700 rounded-xl px-4 py-2.5 text-sm text-slate-200 focus:outline-none focus:border-emerald-500 font-mono"
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-400 mb-1">Earning Title / Deal Reference</label>
            <input
              type="text"
              required
              value={earningTitle}
              onChange={(e) => setEarningTitle(e.target.value)}
              placeholder="e.g. Commission for 3BHK Villa Deal"
              className="w-full bg-slate-800 border border-slate-700 rounded-xl px-4 py-2.5 text-sm text-slate-200 focus:outline-none focus:border-emerald-500"
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-400 mb-1">Amount (INR ₹)</label>
            <input
              type="number"
              required
              value={earningAmount}
              onChange={(e) => setEarningAmount(e.target.value)}
              placeholder="15000"
              className="w-full bg-slate-800 border border-slate-700 rounded-xl px-4 py-2.5 text-sm text-slate-200 focus:outline-none focus:border-emerald-500 font-mono"
            />
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full bg-emerald-500 hover:bg-emerald-600 font-semibold py-3 rounded-xl text-white shadow-lg shadow-emerald-500/20 transition-all disabled:opacity-50 flex items-center justify-center space-x-2"
          >
            <Send className="h-4 w-4" />
            <span>{loading ? 'Processing...' : 'Credit Earning to Agent'}</span>
          </button>
        </form>
      ) : (
        <form onSubmit={handleRecordPayout} className="bg-slate-900 border border-slate-800 rounded-2xl p-6 space-y-4">
          <div>
            <label className="block text-xs font-semibold text-slate-400 mb-1">Agent UUID</label>
            <input
              type="text"
              required
              value={payoutAgentId}
              onChange={(e) => setPayoutAgentId(e.target.value)}
              placeholder="e.g. 123e4567-e89b-12d3-a456-426614174000"
              className="w-full bg-slate-800 border border-slate-700 rounded-xl px-4 py-2.5 text-sm text-slate-200 focus:outline-none focus:border-emerald-500 font-mono"
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-400 mb-1">Payout Amount (INR ₹)</label>
            <input
              type="number"
              required
              value={payoutAmount}
              onChange={(e) => setPayoutAmount(e.target.value)}
              placeholder="15000"
              className="w-full bg-slate-800 border border-slate-700 rounded-xl px-4 py-2.5 text-sm text-slate-200 focus:outline-none focus:border-emerald-500 font-mono"
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-400 mb-1">Transaction Ref / UTR ID</label>
            <input
              type="text"
              required
              value={txnId}
              onChange={(e) => setTxnId(e.target.value)}
              placeholder="e.g. TXN987654321"
              className="w-full bg-slate-800 border border-slate-700 rounded-xl px-4 py-2.5 text-sm text-slate-200 focus:outline-none focus:border-emerald-500 font-mono"
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-400 mb-1">Payment Method</label>
            <select
              value={paymentMethod}
              onChange={(e) => setPaymentMethod(e.target.value)}
              className="w-full bg-slate-800 border border-slate-700 rounded-xl px-4 py-2.5 text-sm text-slate-200 focus:outline-none focus:border-emerald-500"
            >
              <option value="UPI">UPI Transfer</option>
              <option value="NEFT">NEFT Bank Transfer</option>
              <option value="IMPS">IMPS Instant Transfer</option>
              <option value="RTGS">RTGS Transfer</option>
            </select>
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full bg-emerald-500 hover:bg-emerald-600 font-semibold py-3 rounded-xl text-white shadow-lg shadow-emerald-500/20 transition-all disabled:opacity-50 flex items-center justify-center space-x-2"
          >
            <Wallet className="h-4 w-4" />
            <span>{loading ? 'Processing...' : 'Record Payout & Notify Agent'}</span>
          </button>
        </form>
      )}
    </div>
  );
};
