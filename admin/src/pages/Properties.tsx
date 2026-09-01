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
        <h2 className="text-2xl font-bold text-slate-900 tracking-tight">Property Listings Review Queue</h2>
        <p className="text-slate-500 text-sm mt-1">Review agent property listings, verify specifications, and publish live</p>
      </div>

      {message && (
        <div className="bg-emerald-50 border border-emerald-200 text-emerald-800 p-4 rounded-xl text-sm font-medium">
          {message}
        </div>
      )}

      <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-6">
        <h3 className="font-bold text-lg text-slate-900 flex items-center space-x-2">
          <Building2 className="h-5 w-5 text-emerald-600" />
          <span>Inspect Property ID</span>
        </h3>

        <div>
          <label className="block text-xs font-semibold text-slate-700 mb-1">Property UUID</label>
          <input
            type="text"
            value={propertyId}
            onChange={(e) => setPropertyId(e.target.value)}
            placeholder="e.g. 550e8400-e29b-41d4-a716-446655440000"
            className="w-full bg-slate-50 border border-slate-300 rounded-xl px-4 py-2.5 text-sm text-slate-900 focus:outline-none focus:bg-white focus:border-emerald-600 focus:ring-2 focus:ring-emerald-600/20 font-mono"
          />
        </div>

        <div className="flex items-center space-x-4 pt-2">
          <button
            onClick={() => handleReviewProperty(true)}
            disabled={loading}
            className="flex-1 bg-emerald-600 hover:bg-emerald-700 font-semibold py-3 rounded-xl text-sm text-white flex items-center justify-center space-x-2 shadow-sm transition-all disabled:opacity-50"
          >
            <CheckCircle2 className="h-5 w-5" />
            <span>Approve & Publish Listing</span>
          </button>

          <button
            onClick={() => handleReviewProperty(false)}
            disabled={loading}
            className="flex-1 bg-rose-50 hover:bg-rose-600 hover:text-white text-rose-700 font-semibold py-3 rounded-xl text-sm border border-rose-200 flex items-center justify-center space-x-2 transition-all disabled:opacity-50"
          >
            <XCircle className="h-5 w-5" />
            <span>Reject Listing</span>
          </button>
        </div>
      </div>
    </div>
  );
};
