import React, { useState } from 'react';
import { AdminApiService } from '../services/api';
import { Building2, CheckCircle2, XCircle, MapPin, Tag } from 'lucide-react';

export const Properties: React.FC = () => {
  const [propertyId, setPropertyId] = useState('');
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState('');

  const handleReviewProperty = async (approve: boolean) => {
    if (!propertyId.trim()) {
      alert('Please enter a Property UUID to review');
      return;
    }

    const reason = !approve ? prompt('Enter Property Rejection Reason:') || 'Verification criteria not met' : undefined;
    setLoading(true);
    setMessage('');

    try {
      const res = await AdminApiService.reviewProperty(propertyId.trim(), approve, reason);
      setMessage(`Property successfully ${approve ? 'APPROVED' : 'REJECTED'}`);
      setPropertyId('');
    } catch (e: any) {
      alert(e.message || 'Property review action failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-6 max-w-3xl">
      <div>
        <h2 className="text-2xl font-bold text-slate-100 tracking-tight">Property Listings Review Queue</h2>
        <p className="text-slate-400 text-sm mt-1">Review agent property listings, verify specifications, and publish live</p>
      </div>

      {message && (
        <div className="bg-emerald-500/10 border border-emerald-500/30 text-emerald-400 p-4 rounded-xl text-sm font-medium">
          {message}
        </div>
      )}

      <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6 space-y-6">
        <h3 className="font-bold text-lg text-slate-100 flex items-center space-x-2">
          <Building2 className="h-5 w-5 text-emerald-400" />
          <span>Inspect Property ID</span>
        </h3>

        <div>
          <label className="block text-xs font-semibold text-slate-400 mb-1">Property UUID</label>
          <input
            type="text"
            value={propertyId}
            onChange={(e) => setPropertyId(e.target.value)}
            placeholder="e.g. 550e8400-e29b-41d4-a716-446655440000"
            className="w-full bg-slate-800 border border-slate-700 rounded-xl px-4 py-2.5 text-sm text-slate-200 focus:outline-none focus:border-emerald-500 font-mono"
          />
        </div>

        <div className="flex items-center space-x-4 pt-2">
          <button
            onClick={() => handleReviewProperty(true)}
            disabled={loading}
            className="flex-1 bg-emerald-500 hover:bg-emerald-600 font-semibold py-3 rounded-xl text-sm text-white flex items-center justify-center space-x-2 shadow-lg shadow-emerald-500/20 transition-all disabled:opacity-50"
          >
            <CheckCircle2 className="h-5 w-5" />
            <span>Approve & Publish Listing</span>
          </button>

          <button
            onClick={() => handleReviewProperty(false)}
            disabled={loading}
            className="flex-1 bg-red-500/10 hover:bg-red-500 hover:text-white text-red-400 font-semibold py-3 rounded-xl text-sm border border-red-500/20 flex items-center justify-center space-x-2 transition-all disabled:opacity-50"
          >
            <XCircle className="h-5 w-5" />
            <span>Reject Listing</span>
          </button>
        </div>
      </div>
    </div>
  );
};
