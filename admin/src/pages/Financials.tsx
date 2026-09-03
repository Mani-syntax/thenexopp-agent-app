import React, { useEffect, useState } from 'react';
import { AdminApiService } from '../services/api';
import { adminSocket } from '../services/websocket';
import { PaymentRecord, PaymentAnalytics, AgentSummary, PendingPaymentRecord } from '../types';
import {
  Wallet,
  DollarSign,
  Send,
  CheckCircle2,
  Calendar,
  Search,
  RefreshCw,
  TrendingUp,
  CreditCard,
  User,
  ArrowUpRight,
  Clock,
  Trash2,
  AlertTriangle,
  Hourglass,
  ArrowRight,
  ShieldCheck,
  Building2,
  X,
} from 'lucide-react';

export const Financials: React.FC = () => {
  const [tab, setTab] = useState<'records' | 'pending' | 'payout' | 'earning'>('records');

  // Ledger records and analytics
  const [payments, setPayments] = useState<PaymentRecord[]>([]);
  const [analytics, setAnalytics] = useState<PaymentAnalytics>({
    totalSpent: 0,
    todaySpent: 0,
    thisWeekSpent: 0,
    thisMonthSpent: 0,
    totalTransactions: 0,
  });
  const [loading, setLoading] = useState(true);
  const [dateFilter, setDateFilter] = useState<string>('ALL');
  const [startDate, setStartDate] = useState<string>('');
  const [endDate, setEndDate] = useState<string>('');
  const [search, setSearch] = useState<string>('');

  // Pending payments state
  const [pendingPayments, setPendingPayments] = useState<PendingPaymentRecord[]>([]);
  const [totalPendingAmount, setTotalPendingAmount] = useState(0);
  const [pendingLoading, setPendingLoading] = useState(false);
  const [pendingSearch, setPendingSearch] = useState('');

  // Settle modal state
  const [settleTarget, setSettleTarget] = useState<PendingPaymentRecord | null>(null);
  const [settleTxnId, setSettleTxnId] = useState('');
  const [settleMethod, setSettleMethod] = useState('UPI');
  const [settleLoading, setSettleLoading] = useState(false);

  // Agents list for dropdown autofill (filtered for KYC approved only)
  const [agents, setAgents] = useState<AgentSummary[]>([]);

  // Earning form state
  const [earningAgentId, setEarningAgentId] = useState('');
  const [earningTitle, setEarningTitle] = useState('');
  const [earningAmount, setEarningAmount] = useState('');

  // Payout form state
  const [payoutAgentId, setPayoutAgentId] = useState('');
  const [payoutAmount, setPayoutAmount] = useState('');
  const [txnId, setTxnId] = useState('');
  const [paymentMethod, setPaymentMethod] = useState('UPI');

  const [formLoading, setFormLoading] = useState(false);
  const [successMsg, setSuccessMsg] = useState('');
  const [deleteLoadingId, setDeleteLoadingId] = useState<string | null>(null);

  useEffect(() => {
    fetchPayments();
    fetchPendingPayments();
    fetchAgents();

    const handlePaymentUpdated = () => {
      fetchPayments();
      fetchPendingPayments();
    };

    adminSocket.on('payment.created', handlePaymentUpdated);
    adminSocket.on('payment.deleted', handlePaymentUpdated);
    adminSocket.on('pending_payments.updated', handlePaymentUpdated);
    adminSocket.on('earning.created', handlePaymentUpdated);

    return () => {
      adminSocket.off('payment.created', handlePaymentUpdated);
      adminSocket.off('payment.deleted', handlePaymentUpdated);
      adminSocket.off('pending_payments.updated', handlePaymentUpdated);
      adminSocket.off('earning.created', handlePaymentUpdated);
    };
  }, [dateFilter, startDate, endDate]);

  const getDateRange = () => {
    if (dateFilter === 'TODAY') {
      const today = new Date().toISOString().split('T')[0];
      return { start: today, end: today };
    }
    if (dateFilter === 'YESTERDAY') {
      const yesterday = new Date(Date.now() - 86400000).toISOString().split('T')[0];
      return { start: yesterday, end: yesterday };
    }
    if (dateFilter === 'WEEK') {
      const weekAgo = new Date(Date.now() - 7 * 86400000).toISOString().split('T')[0];
      return { start: weekAgo, end: new Date().toISOString().split('T')[0] };
    }
    if (dateFilter === 'MONTH') {
      const now = new Date();
      const monthStart = new Date(now.getFullYear(), now.getMonth(), 1).toISOString().split('T')[0];
      return { start: monthStart, end: now.toISOString().split('T')[0] };
    }
    if (dateFilter === 'CUSTOM') {
      return { start: startDate || undefined, end: endDate || undefined };
    }
    return { start: undefined, end: undefined };
  };

  const fetchPayments = async () => {
    setLoading(true);
    try {
      const range = getDateRange();
      const res = await AdminApiService.getPayments({
        startDate: range.start,
        endDate: range.end,
        search: search.trim() || undefined,
      });
      if (res.success) {
        setPayments(res.data);
        if (res.analytics) {
          setAnalytics(res.analytics);
        }
      }
    } catch (_) {}
    setLoading(false);
  };

  const fetchPendingPayments = async () => {
    setPendingLoading(true);
    try {
      const res = await AdminApiService.getPendingPayments(pendingSearch.trim() || undefined);
      if (res.success) {
        setPendingPayments(res.data);
        setTotalPendingAmount(res.totalPendingAmount || 0);
      }
    } catch (_) {}
    setPendingLoading(false);
  };

  const fetchAgents = async () => {
    try {
      const res = await AdminApiService.getAgents();
      if (res.success) {
        setAgents(res.data);
      }
    } catch (_) {}
  };

  // Filter for KYC approved agents only
  const approvedAgents = agents.filter(
    (a) => a.status === 'APPROVED' || a.kycStatus === 'APPROVED',
  );

  const handleSearchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    fetchPayments();
  };

  const handlePendingSearchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    fetchPendingPayments();
  };

  const handleAddEarning = async (e: React.FormEvent) => {
    e.preventDefault();
    setFormLoading(true);
    setSuccessMsg('');

    try {
      await AdminApiService.createEarning(earningAgentId.trim(), earningTitle.trim(), Number(earningAmount));
      setSuccessMsg(`Successfully credited ₹${Number(earningAmount).toLocaleString('en-IN')} to agent!`);
      setEarningAgentId('');
      setEarningTitle('');
      setEarningAmount('');
      fetchPayments();
      fetchPendingPayments();
    } catch (err: any) {
      alert(err.message || 'Failed to add earning');
    } finally {
      setFormLoading(false);
    }
  };

  const handleRecordPayout = async (e: React.FormEvent) => {
    e.preventDefault();
    setFormLoading(true);
    setSuccessMsg('');

    try {
      await AdminApiService.recordPayment(payoutAgentId.trim(), Number(payoutAmount), txnId.trim(), paymentMethod);
      setSuccessMsg(`Successfully recorded payout transaction ${txnId}!`);
      setPayoutAgentId('');
      setPayoutAmount('');
      setTxnId('');
      fetchPayments();
      fetchPendingPayments();
    } catch (err: any) {
      alert(err.message || 'Failed to record payment');
    } finally {
      setFormLoading(false);
    }
  };

  const handleOpenSettle = (item: PendingPaymentRecord) => {
    setSettleTarget(item);
    setSettleTxnId(`UTR${Date.now().toString().slice(-8)}`);
    setSettleMethod('UPI');
  };

  const handleConfirmSettle = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!settleTarget) return;

    setSettleLoading(true);
    try {
      const res = await AdminApiService.settlePendingPayment(
        settleTarget.id,
        settleTxnId.trim(),
        settleMethod,
      );
      if (res.success) {
        setSuccessMsg(
          `Payment of ₹${Number(settleTarget.amount).toLocaleString('en-IN')} for "${settleTarget.title}" settled successfully (Ref: ${settleTxnId})!`,
        );
        setSettleTarget(null);
        fetchPayments();
        fetchPendingPayments();
      }
    } catch (err: any) {
      alert(err.message || 'Failed to settle pending payment');
    } finally {
      setSettleLoading(false);
    }
  };

  const handleDeletePayment = async (paymentId: string, txnId: string, amount: number) => {
    const confirmed = window.confirm(
      `Are you sure you want to permanently delete transaction "${txnId}" (₹${Number(amount).toLocaleString('en-IN')})?\n\nThis will update total expenditures and ledger records in real-time.`,
    );
    if (!confirmed) return;

    setDeleteLoadingId(paymentId);
    try {
      const res = await AdminApiService.deletePayment(paymentId);
      if (res.success) {
        setSuccessMsg(`Transaction "${txnId}" deleted successfully.`);
        fetchPayments();
        fetchPendingPayments();
      }
    } catch (err: any) {
      alert(err.message || 'Failed to delete payment transaction');
    } finally {
      setDeleteLoadingId(null);
    }
  };

  const handleDeletePendingPayment = async (earningId: string, title: string, amount: number) => {
    const confirmed = window.confirm(
      `Are you sure you want to cancel and delete pending listing reward "${title}" (₹${Number(amount).toLocaleString('en-IN')})?\n\nThis will remove the pending payout from both the admin queue and the agent's app.`,
    );
    if (!confirmed) return;

    try {
      await AdminApiService.deleteEarning(earningId);
      setSuccessMsg(`Pending reward "${title}" cancelled and deleted.`);
      fetchPendingPayments();
    } catch (err: any) {
      alert(err.message || 'Failed to delete pending payment');
    }
  };

  const filteredPayments = payments.filter((p) => {
    if (!search.trim()) return true;
    const q = search.toLowerCase();
    const txnMatch = (p.transactionId || '').toLowerCase().includes(q);
    const agentMatch = (p.agent?.fullName || '').toLowerCase().includes(q);
    const phoneMatch = (p.agent?.mobileNumber || '').includes(q);
    const methodMatch = (p.paymentMethod || '').toLowerCase().includes(q);
    return txnMatch || agentMatch || phoneMatch || methodMatch;
  });

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h2 className="text-2xl font-bold text-slate-900 tracking-tight">Earnings & Payout Ledger</h2>
        <p className="text-slate-500 text-sm mt-1">
          Complete database of payments made to agents, pending listing rewards, daily expenditures, and transaction logs
        </p>
      </div>

      {successMsg && (
        <div className="bg-emerald-50 border border-emerald-200 text-emerald-800 p-4 rounded-xl text-sm font-medium flex items-center space-x-2">
          <CheckCircle2 className="h-5 w-5 text-emerald-600 shrink-0" />
          <span>{successMsg}</span>
        </div>
      )}

      {/* Analytics Summary Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-white border border-slate-200 rounded-2xl p-5 shadow-sm space-y-2">
          <div className="flex items-center justify-between text-xs font-semibold text-slate-500 uppercase">
            <span>Total Spent (All-Time)</span>
            <div className="p-2 bg-emerald-50 text-emerald-600 rounded-xl">
              <TrendingUp className="h-4 w-4" />
            </div>
          </div>
          <p className="text-2xl font-extrabold text-slate-900">₹{Number(analytics.totalSpent).toLocaleString('en-IN')}</p>
          <span className="text-[11px] text-slate-400 block font-medium">{analytics.totalTransactions} Completed Payouts</span>
        </div>

        <div className="bg-white border border-slate-200 rounded-2xl p-5 shadow-sm space-y-2">
          <div className="flex items-center justify-between text-xs font-semibold text-amber-700 uppercase">
            <span>Pending Payouts Queue</span>
            <div className="p-2 bg-amber-50 text-amber-600 rounded-xl">
              <Hourglass className="h-4 w-4" />
            </div>
          </div>
          <p className="text-2xl font-extrabold text-amber-700">₹{Number(totalPendingAmount).toLocaleString('en-IN')}</p>
          <span className="text-[11px] text-amber-600 block font-medium">
            {pendingPayments.length} Listing Rewards Awaiting Settle
          </span>
        </div>

        <div className="bg-white border border-slate-200 rounded-2xl p-5 shadow-sm space-y-2">
          <div className="flex items-center justify-between text-xs font-semibold text-slate-700 uppercase">
            <span>Today's Spent (Daily)</span>
            <div className="p-2 bg-emerald-50 text-emerald-600 rounded-xl">
              <Calendar className="h-4 w-4" />
            </div>
          </div>
          <p className="text-2xl font-extrabold text-emerald-700">₹{Number(analytics.todaySpent).toLocaleString('en-IN')}</p>
          <span className="text-[11px] text-slate-400 block font-medium">Distributed today</span>
        </div>

        <div className="bg-white border border-slate-200 rounded-2xl p-5 shadow-sm space-y-2">
          <div className="flex items-center justify-between text-xs font-semibold text-slate-700 uppercase">
            <span>This Month's Spent</span>
            <div className="p-2 bg-purple-50 text-purple-600 rounded-xl">
              <Wallet className="h-4 w-4" />
            </div>
          </div>
          <p className="text-2xl font-extrabold text-slate-900">₹{Number(analytics.thisMonthSpent).toLocaleString('en-IN')}</p>
          <span className="text-[11px] text-slate-400 block font-medium">Current calendar month</span>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex flex-wrap border-b border-slate-200 gap-x-8 gap-y-2">
        <button
          onClick={() => { setTab('records'); setSuccessMsg(''); }}
          className={`pb-3 font-bold text-sm transition-colors border-b-2 ${
            tab === 'records' ? 'border-emerald-600 text-emerald-700' : 'border-transparent text-slate-500 hover:text-slate-900'
          }`}
        >
          Payment Records & Ledger ({payments.length})
        </button>
        <button
          onClick={() => { setTab('pending'); setSuccessMsg(''); }}
          className={`pb-3 font-bold text-sm transition-colors border-b-2 flex items-center space-x-2 ${
            tab === 'pending' ? 'border-amber-500 text-amber-700' : 'border-transparent text-slate-500 hover:text-slate-900'
          }`}
        >
          <span>Pending Payments</span>
          {pendingPayments.length > 0 && (
            <span className="px-2 py-0.5 text-xs rounded-full bg-amber-100 text-amber-800 font-bold border border-amber-300">
              {pendingPayments.length}
            </span>
          )}
        </button>
        <button
          onClick={() => { setTab('payout'); setSuccessMsg(''); }}
          className={`pb-3 font-bold text-sm transition-colors border-b-2 ${
            tab === 'payout' ? 'border-emerald-600 text-emerald-700' : 'border-transparent text-slate-500 hover:text-slate-900'
          }`}
        >
          + Record Payout Transaction
        </button>
        <button
          onClick={() => { setTab('earning'); setSuccessMsg(''); }}
          className={`pb-3 font-bold text-sm transition-colors border-b-2 ${
            tab === 'earning' ? 'border-emerald-600 text-emerald-700' : 'border-transparent text-slate-500 hover:text-slate-900'
          }`}
        >
          + Credit Agent Commission
        </button>
      </div>

      {tab === 'records' ? (
        <div className="space-y-4">
          {/* Top Filter Bar */}
          <div className="bg-white border border-slate-200 rounded-2xl p-4 shadow-sm space-y-4">
            <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
              {/* Date Filter Dropdown & Custom Range */}
              <div className="flex flex-wrap items-center gap-2">
                <div className="flex items-center space-x-1.5 bg-slate-50 border border-slate-200 rounded-xl px-3 py-1.5 text-xs text-slate-700">
                  <Calendar className="h-3.5 w-3.5 text-slate-400" />
                  <select
                    value={dateFilter}
                    onChange={(e) => setDateFilter(e.target.value)}
                    className="bg-transparent font-semibold text-slate-900 focus:outline-none cursor-pointer"
                  >
                    <option value="ALL">All Time Expenditures</option>
                    <option value="TODAY">Today's Payouts</option>
                    <option value="YESTERDAY">Yesterday's Payouts</option>
                    <option value="WEEK">This Week (Last 7 Days)</option>
                    <option value="MONTH">This Month</option>
                    <option value="CUSTOM">Custom Date Range</option>
                  </select>
                </div>

                {dateFilter === 'CUSTOM' && (
                  <div className="flex items-center space-x-2">
                    <input
                      type="date"
                      value={startDate}
                      onChange={(e) => setStartDate(e.target.value)}
                      className="bg-white border border-slate-200 rounded-xl px-2.5 py-1.5 text-xs text-slate-900 focus:outline-none focus:border-emerald-600"
                    />
                    <span className="text-xs text-slate-400">to</span>
                    <input
                      type="date"
                      value={endDate}
                      onChange={(e) => setEndDate(e.target.value)}
                      className="bg-white border border-slate-200 rounded-xl px-2.5 py-1.5 text-xs text-slate-900 focus:outline-none focus:border-emerald-600"
                    />
                  </div>
                )}
              </div>

              <button
                onClick={fetchPayments}
                className="p-2 bg-slate-50 border border-slate-200 rounded-xl text-slate-600 hover:text-slate-900 transition-colors self-end lg:self-auto"
                title="Refresh Ledger"
              >
                <RefreshCw className="h-4 w-4" />
              </button>
            </div>

            {/* Search Bar */}
            <form onSubmit={handleSearchSubmit} className="relative">
              <Search className="absolute left-3.5 top-3 h-4 w-4 text-slate-400" />
              <input
                type="text"
                placeholder="Search transaction UTR, agent name, mobile number, or method..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="w-full bg-slate-50 border border-slate-200 rounded-xl pl-10 pr-24 py-2.5 text-sm text-slate-900 focus:outline-none focus:bg-white focus:border-emerald-600 focus:ring-2 focus:ring-emerald-600/20"
              />
              <button
                type="submit"
                className="absolute right-2 top-2 px-3 py-1 bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg text-xs font-semibold transition-colors"
              >
                Search
              </button>
            </form>
          </div>

          {/* Payment Records Table */}
          <div className="bg-white border border-slate-200 rounded-2xl overflow-hidden shadow-sm">
            <table className="w-full text-left text-sm">
              <thead className="bg-slate-50 text-xs font-semibold text-slate-500 uppercase tracking-wider border-b border-slate-200">
                <tr>
                  <th className="p-4">Transaction Ref / UTR</th>
                  <th className="p-4">Paid To (Agent)</th>
                  <th className="p-4">Amount Paid</th>
                  <th className="p-4">Payment Method</th>
                  <th className="p-4">Transferred Date & Time</th>
                  <th className="p-4">Status</th>
                  <th className="p-4 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {loading ? (
                  <tr>
                    <td colSpan={7} className="py-8 text-center text-slate-400">Loading payment ledger from database...</td>
                  </tr>
                ) : filteredPayments.length === 0 ? (
                  <tr>
                    <td colSpan={7} className="py-8 text-center text-slate-400">No payment records found matching criteria.</td>
                  </tr>
                ) : (
                  filteredPayments.map((payment) => (
                    <tr key={payment.id} className="hover:bg-slate-50 transition-colors">
                      <td className="p-4">
                        <div className="font-mono font-bold text-slate-900 text-xs">{payment.transactionId}</div>
                        {payment.earningTitle && (
                          <div className="text-[11px] text-slate-400 mt-0.5">{payment.earningTitle}</div>
                        )}
                      </td>
                      <td className="p-4">
                        <div className="font-semibold text-slate-900">{payment.agent?.fullName || 'Agent Partner'}</div>
                        <div className="text-xs text-slate-500">+91 {payment.agent?.mobileNumber}</div>
                      </td>
                      <td className="p-4 font-extrabold text-emerald-700 text-base">
                        ₹{Number(payment.amount).toLocaleString('en-IN')}
                      </td>
                      <td className="p-4">
                        <span className="px-2.5 py-1 bg-slate-100 text-slate-700 rounded-lg text-xs font-bold border border-slate-200">
                          {payment.paymentMethod}
                        </span>
                      </td>
                      <td className="p-4 text-xs">
                        <div className="font-semibold text-slate-800">
                          {new Date(payment.paidAt).toLocaleDateString('en-IN', {
                            day: 'numeric',
                            month: 'short',
                            year: 'numeric',
                          })}
                        </div>
                        <div className="text-[11px] text-emerald-700 font-bold flex items-center space-x-1 mt-0.5">
                          <Clock className="h-3 w-3 inline text-emerald-600" />
                          <span>
                            {new Date(payment.paidAt).toLocaleTimeString('en-IN', {
                              hour: '2-digit',
                              minute: '2-digit',
                              hour12: true,
                            })}
                          </span>
                        </div>
                      </td>
                      <td className="p-4">
                        <span className="px-2.5 py-1 rounded-full text-xs font-bold bg-emerald-50 text-emerald-700 border border-emerald-200 flex items-center space-x-1 w-max">
                          <CheckCircle2 className="h-3 w-3" />
                          <span>COMPLETED</span>
                        </span>
                      </td>
                      <td className="p-4 text-right">
                        <button
                          onClick={() => handleDeletePayment(payment.id, payment.transactionId, payment.amount)}
                          disabled={deleteLoadingId === payment.id}
                          className="p-2 text-rose-500 hover:text-rose-700 hover:bg-rose-50 rounded-xl border border-transparent hover:border-rose-200 transition-colors disabled:opacity-50 inline-flex items-center space-x-1"
                          title="Delete Transaction Record"
                        >
                          <Trash2 className="h-4 w-4" />
                          <span className="text-xs font-semibold">Delete</span>
                        </button>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      ) : tab === 'pending' ? (
        <div className="space-y-4">
          {/* Top Pending Payments Header & Search */}
          <div className="bg-amber-50/60 border border-amber-200/80 rounded-2xl p-5 shadow-sm flex flex-col md:flex-row md:items-center justify-between gap-4">
            <div className="space-y-1">
              <div className="flex items-center space-x-2">
                <Hourglass className="h-5 w-5 text-amber-700" />
                <h3 className="text-base font-bold text-amber-900">Pending Listing Commissions & Payments</h3>
              </div>
              <p className="text-xs text-amber-800">
                When an agent uploads a property/business listing and it is approved by Admin, reward commissions reflect here and in the agent's app as Pending Payouts until verified and disbursed.
              </p>
            </div>

            <div className="flex items-center space-x-2 shrink-0">
              <button
                onClick={fetchPendingPayments}
                className="p-2.5 bg-white border border-amber-200 rounded-xl text-amber-900 hover:bg-amber-50 transition-colors shadow-xs"
                title="Refresh Pending List"
              >
                <RefreshCw className="h-4 w-4" />
              </button>
            </div>
          </div>

          {/* Search Bar for Pending Payments */}
          <form onSubmit={handlePendingSearchSubmit} className="relative">
            <Search className="absolute left-3.5 top-3 h-4 w-4 text-slate-400" />
            <input
              type="text"
              placeholder="Search by agent name, mobile number, property listing title, or reason..."
              value={pendingSearch}
              onChange={(e) => setPendingSearch(e.target.value)}
              className="w-full bg-white border border-slate-200 rounded-xl pl-10 pr-24 py-2.5 text-sm text-slate-900 focus:outline-none focus:border-amber-500 focus:ring-2 focus:ring-amber-500/20"
            />
            <button
              type="submit"
              className="absolute right-2 top-2 px-3 py-1 bg-amber-600 hover:bg-amber-700 text-white rounded-lg text-xs font-semibold transition-colors"
            >
              Search
            </button>
          </form>

          {/* Pending Payments Table */}
          <div className="bg-white border border-slate-200 rounded-2xl overflow-hidden shadow-sm">
            <table className="w-full text-left text-sm">
              <thead className="bg-slate-50 text-xs font-semibold text-slate-500 uppercase tracking-wider border-b border-slate-200">
                <tr>
                  <th className="p-4">Agent Partner</th>
                  <th className="p-4">Listing / Commission Details</th>
                  <th className="p-4">Pending Amount</th>
                  <th className="p-4">Earned Date</th>
                  <th className="p-4">Approval Status</th>
                  <th className="p-4 text-right">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {pendingLoading ? (
                  <tr>
                    <td colSpan={6} className="py-8 text-center text-slate-400">Loading pending payment requests...</td>
                  </tr>
                ) : pendingPayments.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="py-8 text-center text-slate-400">
                      <div className="flex flex-col items-center justify-center space-y-1 py-4">
                        <CheckCircle2 className="h-8 w-8 text-emerald-500" />
                        <span className="font-semibold text-slate-700">All pending payments are settled!</span>
                        <span className="text-xs text-slate-400">Approved property listings and rewards will appear here automatically.</span>
                      </div>
                    </td>
                  </tr>
                ) : (
                  pendingPayments.map((item) => (
                    <tr key={item.id} className="hover:bg-amber-50/40 transition-colors">
                      <td className="p-4">
                        <div className="font-semibold text-slate-900">{item.agent?.fullName || 'Agent Partner'}</div>
                        <div className="text-xs text-slate-500">+91 {item.agent?.mobileNumber}</div>
                        {item.agent?.areaLocation && (
                          <div className="text-[11px] text-slate-400">{item.agent.areaLocation}</div>
                        )}
                      </td>
                      <td className="p-4">
                        <div className="font-semibold text-slate-900">{item.title}</div>
                        {item.propertyTitle && (
                          <div className="text-xs text-emerald-700 flex items-center space-x-1 mt-0.5">
                            <Building2 className="h-3 w-3" />
                            <span>Listing: {item.propertyTitle}</span>
                          </div>
                        )}
                      </td>
                      <td className="p-4 font-extrabold text-amber-700 text-base">
                        ₹{Number(item.amount).toLocaleString('en-IN')}
                      </td>
                      <td className="p-4 text-xs text-slate-600">
                        {new Date(item.earnedDate).toLocaleDateString('en-IN', {
                          day: 'numeric',
                          month: 'short',
                          year: 'numeric',
                        })}
                      </td>
                      <td className="p-4">
                        <span className="px-2.5 py-1 rounded-full text-xs font-bold bg-amber-50 text-amber-800 border border-amber-200 flex items-center space-x-1 w-max">
                          <Hourglass className="h-3 w-3" />
                          <span>PENDING PAYOUT</span>
                        </span>
                      </td>
                      <td className="p-4 text-right">
                        <div className="flex items-center justify-end space-x-2">
                          <button
                            onClick={() => handleOpenSettle(item)}
                            className="px-3.5 py-2 bg-emerald-600 hover:bg-emerald-700 text-white rounded-xl text-xs font-bold transition-all shadow-sm hover:shadow-md flex items-center space-x-1.5"
                          >
                            <CreditCard className="h-3.5 w-3.5" />
                            <span>Settle & Pay</span>
                          </button>
                          <button
                            onClick={() => handleDeletePendingPayment(item.id, item.title, item.amount)}
                            className="p-2 bg-rose-50 hover:bg-rose-600 hover:text-white text-rose-700 rounded-xl text-xs font-bold border border-rose-200 transition-colors"
                            title="Cancel & Delete Pending Reward"
                          >
                            <Trash2 className="h-3.5 w-3.5" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      ) : tab === 'earning' ? (
        <form onSubmit={handleAddEarning} className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-4 max-w-2xl">
          <div>
            <div className="flex items-center justify-between mb-1">
              <label className="block text-xs font-semibold text-slate-700">Select KYC Approved Agent Partner</label>
              <span className="text-[11px] font-bold text-emerald-600 bg-emerald-50 px-2 py-0.5 rounded-full border border-emerald-200">
                {approvedAgents.length} KYC Approved
              </span>
            </div>
            <select
              value={earningAgentId}
              onChange={(e) => setEarningAgentId(e.target.value)}
              required
              className="w-full bg-slate-50 border border-slate-300 rounded-xl px-4 py-2.5 text-sm text-slate-900 focus:outline-none focus:bg-white focus:border-emerald-600 focus:ring-2 focus:ring-emerald-600/20"
            >
              <option value="">
                {approvedAgents.length === 0
                  ? '-- No KYC Approved Agents Found --'
                  : '-- Choose KYC Approved Agent --'}
              </option>
              {approvedAgents.map((a) => (
                <option key={a.id} value={a.id}>
                  {a.fullName} (+91 {a.mobileNumber}) - ID: {a.id.substring(0, 8)}... [KYC: APPROVED]
                </option>
              ))}
            </select>
            {approvedAgents.length === 0 && (
              <p className="text-xs text-amber-600 mt-1.5 flex items-center space-x-1">
                <AlertTriangle className="h-3.5 w-3.5 inline" />
                <span>Go to KYC Verification tab to review and approve agent documents.</span>
              </p>
            )}
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-700 mb-1">Or Enter Agent UUID Manually</label>
            <input
              type="text"
              value={earningAgentId}
              onChange={(e) => setEarningAgentId(e.target.value)}
              placeholder="e.g. 123e4567-e89b-12d3-a456-426614174000"
              className="w-full bg-slate-50 border border-slate-300 rounded-xl px-4 py-2.5 text-sm text-slate-900 focus:outline-none focus:bg-white focus:border-emerald-600 focus:ring-2 focus:ring-emerald-600/20 font-mono"
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-700 mb-1">Commission Title / Deal Reference</label>
            <input
              type="text"
              required
              value={earningTitle}
              onChange={(e) => setEarningTitle(e.target.value)}
              placeholder="e.g. Commission for 3BHK Apartment Sale Deal"
              className="w-full bg-slate-50 border border-slate-300 rounded-xl px-4 py-2.5 text-sm text-slate-900 focus:outline-none focus:bg-white focus:border-emerald-600 focus:ring-2 focus:ring-emerald-600/20"
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-700 mb-1">Commission Amount (INR ₹)</label>
            <input
              type="number"
              required
              value={earningAmount}
              onChange={(e) => setEarningAmount(e.target.value)}
              placeholder="15000"
              className="w-full bg-slate-50 border border-slate-300 rounded-xl px-4 py-2.5 text-sm text-slate-900 focus:outline-none focus:bg-white focus:border-emerald-600 focus:ring-2 focus:ring-emerald-600/20 font-mono"
            />
          </div>

          <button
            type="submit"
            disabled={formLoading || (!earningAgentId && approvedAgents.length === 0)}
            className="w-full bg-emerald-600 hover:bg-emerald-700 font-semibold py-3 rounded-xl text-white shadow-md shadow-emerald-600/15 transition-all disabled:opacity-50 flex items-center justify-center space-x-2"
          >
            <Send className="h-4 w-4" />
            <span>{formLoading ? 'Processing...' : 'Credit Commission to Agent'}</span>
          </button>
        </form>
      ) : (
        <form onSubmit={handleRecordPayout} className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-4 max-w-2xl">
          <div>
            <div className="flex items-center justify-between mb-1">
              <label className="block text-xs font-semibold text-slate-700">Select KYC Approved Agent Partner</label>
              <span className="text-[11px] font-bold text-emerald-600 bg-emerald-50 px-2 py-0.5 rounded-full border border-emerald-200">
                {approvedAgents.length} KYC Approved
              </span>
            </div>
            <select
              value={payoutAgentId}
              onChange={(e) => setPayoutAgentId(e.target.value)}
              required
              className="w-full bg-slate-50 border border-slate-300 rounded-xl px-4 py-2.5 text-sm text-slate-900 focus:outline-none focus:bg-white focus:border-emerald-600 focus:ring-2 focus:ring-emerald-600/20"
            >
              <option value="">
                {approvedAgents.length === 0
                  ? '-- No KYC Approved Agents Found --'
                  : '-- Choose KYC Approved Agent --'}
              </option>
              {approvedAgents.map((a) => (
                <option key={a.id} value={a.id}>
                  {a.fullName} (+91 {a.mobileNumber}) - ID: {a.id.substring(0, 8)}... [KYC: APPROVED]
                </option>
              ))}
            </select>
            {approvedAgents.length === 0 && (
              <p className="text-xs text-amber-600 mt-1.5 flex items-center space-x-1">
                <AlertTriangle className="h-3.5 w-3.5 inline" />
                <span>Go to KYC Verification tab to review and approve agent documents.</span>
              </p>
            )}
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-700 mb-1">Or Enter Agent UUID Manually</label>
            <input
              type="text"
              value={payoutAgentId}
              onChange={(e) => setPayoutAgentId(e.target.value)}
              placeholder="e.g. 123e4567-e89b-12d3-a456-426614174000"
              className="w-full bg-slate-50 border border-slate-300 rounded-xl px-4 py-2.5 text-sm text-slate-900 focus:outline-none focus:bg-white focus:border-emerald-600 focus:ring-2 focus:ring-emerald-600/20 font-mono"
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-700 mb-1">Payout Amount (INR ₹)</label>
            <input
              type="number"
              required
              value={payoutAmount}
              onChange={(e) => setPayoutAmount(e.target.value)}
              placeholder="15000"
              className="w-full bg-slate-50 border border-slate-300 rounded-xl px-4 py-2.5 text-sm text-slate-900 focus:outline-none focus:bg-white focus:border-emerald-600 focus:ring-2 focus:ring-emerald-600/20 font-mono"
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-700 mb-1">Transaction Ref / Bank UTR ID</label>
            <input
              type="text"
              required
              value={txnId}
              onChange={(e) => setTxnId(e.target.value)}
              placeholder="e.g. UTR123456789 or UPI987654"
              className="w-full bg-slate-50 border border-slate-300 rounded-xl px-4 py-2.5 text-sm text-slate-900 focus:outline-none focus:bg-white focus:border-emerald-600 focus:ring-2 focus:ring-emerald-600/20 font-mono"
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-700 mb-1">Payment Method</label>
            <select
              value={paymentMethod}
              onChange={(e) => setPaymentMethod(e.target.value)}
              className="w-full bg-slate-50 border border-slate-300 rounded-xl px-4 py-2.5 text-sm text-slate-900 focus:outline-none focus:bg-white focus:border-emerald-600 focus:ring-2 focus:ring-emerald-600/20"
            >
              <option value="UPI">UPI Instant Transfer</option>
              <option value="NEFT">NEFT Bank Transfer</option>
              <option value="IMPS">IMPS Immediate Payment</option>
              <option value="RTGS">RTGS Real-Time Gross Settlement</option>
            </select>
          </div>

          <button
            type="submit"
            disabled={formLoading || (!payoutAgentId && approvedAgents.length === 0)}
            className="w-full bg-emerald-600 hover:bg-emerald-700 font-semibold py-3 rounded-xl text-white shadow-md shadow-emerald-600/15 transition-all disabled:opacity-50 flex items-center justify-center space-x-2"
          >
            <Wallet className="h-4 w-4" />
            <span>{formLoading ? 'Recording Transaction...' : 'Record Payout & Push Live Notification'}</span>
          </button>
        </form>
      )}

      {/* Settle Pending Payment Modal */}
      {settleTarget && (
        <div className="fixed inset-0 z-50 bg-slate-900/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl max-w-lg w-full p-6 shadow-2xl border border-slate-100 space-y-5 animate-in fade-in zoom-in-95 duration-150">
            <div className="flex items-center justify-between pb-3 border-b border-slate-100">
              <div className="flex items-center space-x-2">
                <div className="p-2 bg-emerald-50 text-emerald-600 rounded-xl">
                  <CreditCard className="h-5 w-5" />
                </div>
                <div>
                  <h3 className="font-bold text-slate-900 text-base">Settle Pending Listing Reward</h3>
                  <p className="text-xs text-slate-500">Transfer reward to agent partner</p>
                </div>
              </div>
              <button
                onClick={() => setSettleTarget(null)}
                className="p-1.5 text-slate-400 hover:text-slate-700 hover:bg-slate-100 rounded-lg transition-colors"
              >
                <X className="h-5 w-5" />
              </button>
            </div>

            {/* Target Details Card */}
            <div className="bg-slate-50 border border-slate-200 rounded-2xl p-4 space-y-2 text-xs">
              <div className="flex justify-between">
                <span className="text-slate-500 font-medium">Agent Partner:</span>
                <span className="font-bold text-slate-900">{settleTarget.agent?.fullName} (+91 {settleTarget.agent?.mobileNumber})</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-500 font-medium">Listing Reference:</span>
                <span className="font-semibold text-slate-800">{settleTarget.title}</span>
              </div>
              <div className="flex justify-between items-center pt-2 border-t border-slate-200">
                <span className="text-slate-700 font-bold">Reward Amount:</span>
                <span className="text-lg font-extrabold text-emerald-700">₹{Number(settleTarget.amount).toLocaleString('en-IN')}</span>
              </div>
            </div>

            {/* Settle Form */}
            <form onSubmit={handleConfirmSettle} className="space-y-4">
              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">Transaction Ref / Bank UTR ID</label>
                <input
                  type="text"
                  required
                  value={settleTxnId}
                  onChange={(e) => setSettleTxnId(e.target.value)}
                  placeholder="e.g. UTR987654321 or UPI123456"
                  className="w-full bg-slate-50 border border-slate-300 rounded-xl px-4 py-2.5 text-sm text-slate-900 focus:outline-none focus:bg-white focus:border-emerald-600 focus:ring-2 focus:ring-emerald-600/20 font-mono"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">Payment Method</label>
                <select
                  value={settleMethod}
                  onChange={(e) => setSettleMethod(e.target.value)}
                  className="w-full bg-slate-50 border border-slate-300 rounded-xl px-4 py-2.5 text-sm text-slate-900 focus:outline-none focus:bg-white focus:border-emerald-600 focus:ring-2 focus:ring-emerald-600/20"
                >
                  <option value="UPI">UPI Instant Transfer</option>
                  <option value="NEFT">NEFT Bank Transfer</option>
                  <option value="IMPS">IMPS Immediate Payment</option>
                  <option value="RTGS">RTGS Real-Time Gross Settlement</option>
                </select>
              </div>

              <div className="flex items-center space-x-3 pt-2">
                <button
                  type="button"
                  onClick={() => setSettleTarget(null)}
                  className="flex-1 py-3 border border-slate-200 rounded-xl text-slate-700 font-semibold text-sm hover:bg-slate-50 transition-colors"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={settleLoading}
                  className="flex-1 py-3 bg-emerald-600 hover:bg-emerald-700 text-white rounded-xl font-bold text-sm shadow-md shadow-emerald-600/20 transition-all disabled:opacity-50 flex items-center justify-center space-x-2"
                >
                  <ShieldCheck className="h-4 w-4" />
                  <span>{settleLoading ? 'Settling...' : 'Confirm & Disburse'}</span>
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
