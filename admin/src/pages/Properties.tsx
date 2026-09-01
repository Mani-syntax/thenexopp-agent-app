import React, { useEffect, useState } from 'react';
import { AdminApiService } from '../services/api';
import { PropertyListing, PropertyStatus } from '../types';
import {
  Building2,
  CheckCircle2,
  XCircle,
  MapPin,
  Tag,
  Search,
  Calendar,
  Filter,
  Eye,
  ChevronLeft,
  ChevronRight,
  User,
  Phone,
  Clock,
  Layers,
  LayoutGrid,
  List,
  RefreshCw,
} from 'lucide-react';
import { Modal } from '../components/Modal';

export const Properties: React.FC = () => {
  const [properties, setProperties] = useState<PropertyListing[]>([]);
  const [loading, setLoading] = useState(true);
  const [filterStatus, setFilterStatus] = useState<string>('ALL');
  const [dateFilter, setDateFilter] = useState<string>('ALL');
  const [startDate, setStartDate] = useState<string>('');
  const [endDate, setEndDate] = useState<string>('');
  const [search, setSearch] = useState<string>('');
  const [viewMode, setViewMode] = useState<'grid' | 'table'>('grid');

  // Review & Inspect Modals
  const [inspectProperty, setInspectProperty] = useState<PropertyListing | null>(null);
  const [rejectionModalOpen, setRejectionModalOpen] = useState(false);
  const [selectedPropertyId, setSelectedPropertyId] = useState<string | null>(null);
  const [rejectionReason, setRejectionReason] = useState('');
  const [actionLoading, setActionLoading] = useState(false);

  // Image Lightbox Modal
  const [lightboxImages, setLightboxImages] = useState<string[]>([]);
  const [lightboxIndex, setLightboxIndex] = useState(0);

  useEffect(() => {
    fetchProperties();
  }, [filterStatus, dateFilter, startDate, endDate]);

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

  const fetchProperties = async () => {
    setLoading(true);
    try {
      const range = getDateRange();
      const statusParam = filterStatus === 'ALL' ? undefined : (filterStatus as PropertyStatus);
      const res = await AdminApiService.getProperties({
        status: statusParam,
        startDate: range.start,
        endDate: range.end,
        search: search.trim() || undefined,
      });
      if (res.success) {
        setProperties(res.data);
      }
    } catch (_) {}
    setLoading(false);
  };

  const handleSearchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    fetchProperties();
  };

  const handleReviewAction = async (propertyId: string, approve: boolean) => {
    if (!approve) {
      setSelectedPropertyId(propertyId);
      setRejectionReason('');
      setRejectionModalOpen(true);
    } else {
      executeReview(propertyId, true);
    }
  };

  const executeReview = async (propertyId: string, approve: boolean, reason?: string) => {
    setActionLoading(true);
    try {
      await AdminApiService.reviewProperty(propertyId, approve, reason);
      setRejectionModalOpen(false);
      if (inspectProperty?.id === propertyId) {
        setInspectProperty(null);
      }
      fetchProperties();
    } catch (e: any) {
      alert(e.message || 'Review failed');
    } finally {
      setActionLoading(false);
    }
  };

  const openLightbox = (images: { url: string | null }[], startIndex = 0) => {
    const validUrls = images.map((img) => img.url).filter((u): u is string => !!u);
    if (validUrls.length > 0) {
      setLightboxImages(validUrls);
      setLightboxIndex(startIndex);
    }
  };

  const filteredProperties = properties.filter((p) => {
    if (!search.trim()) return true;
    const q = search.toLowerCase();
    const titleMatch = (p.title || '').toLowerCase().includes(q);
    const locationMatch = (p.location || '').toLowerCase().includes(q);
    const agentMatch = (p.agent?.fullName || '').toLowerCase().includes(q);
    const phoneMatch = (p.agent?.mobileNumber || '').includes(q);
    return titleMatch || locationMatch || agentMatch || phoneMatch;
  });

  // Group properties day-wise / date-wise
  const groupPropertiesByDate = () => {
    const groups: { [dateStr: string]: PropertyListing[] } = {};
    filteredProperties.forEach((prop) => {
      const dateKey = new Date(prop.createdAt).toLocaleDateString('en-IN', {
        weekday: 'long',
        year: 'numeric',
        month: 'short',
        day: 'numeric',
      });
      if (!groups[dateKey]) groups[dateKey] = [];
      groups[dateKey].push(prop);
    });
    return groups;
  };

  const grouped = groupPropertiesByDate();
  const totalCount = properties.length;
  const underReviewCount = properties.filter((p) => p.status === 'SUBMITTED' || p.status === 'UNDER_REVIEW').length;
  const approvedCount = properties.filter((p) => p.status === 'APPROVED').length;
  const rejectedCount = properties.filter((p) => p.status === 'REJECTED').length;

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold text-slate-900 tracking-tight">Property Listings & Asset Management</h2>
          <p className="text-slate-500 text-sm mt-1">
            Review agent-submitted listings, inspect pictures, verify specifications, and track day-wise asset submissions
          </p>
        </div>

        <div className="flex items-center space-x-2">
          <button
            onClick={fetchProperties}
            className="p-2.5 bg-white border border-slate-200 rounded-xl text-slate-600 hover:text-slate-900 hover:bg-slate-50 transition-colors shadow-sm"
            title="Refresh Listings"
          >
            <RefreshCw className="h-4 w-4" />
          </button>
          <div className="flex bg-slate-100 p-1 rounded-xl border border-slate-200">
            <button
              onClick={() => setViewMode('grid')}
              className={`p-2 rounded-lg text-xs font-semibold transition-all ${
                viewMode === 'grid' ? 'bg-white text-slate-900 shadow-sm' : 'text-slate-500 hover:text-slate-900'
              }`}
              title="Card Grid View"
            >
              <LayoutGrid className="h-4 w-4" />
            </button>
            <button
              onClick={() => setViewMode('table')}
              className={`p-2 rounded-lg text-xs font-semibold transition-all ${
                viewMode === 'table' ? 'bg-white text-slate-900 shadow-sm' : 'text-slate-500 hover:text-slate-900'
              }`}
              title="Table View"
            >
              <List className="h-4 w-4" />
            </button>
          </div>
        </div>
      </div>

      {/* Metrics Row */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
        <div className="bg-white border border-slate-200 rounded-2xl p-4 shadow-sm">
          <span className="text-xs text-slate-500 font-semibold uppercase">Total Listings</span>
          <p className="text-2xl font-bold text-slate-900 mt-1">{totalCount}</p>
        </div>
        <div className="bg-white border border-slate-200 rounded-2xl p-4 shadow-sm">
          <span className="text-xs text-amber-600 font-semibold uppercase">Under Review</span>
          <p className="text-2xl font-bold text-amber-600 mt-1">{underReviewCount}</p>
        </div>
        <div className="bg-white border border-slate-200 rounded-2xl p-4 shadow-sm">
          <span className="text-xs text-emerald-600 font-semibold uppercase">Approved Live</span>
          <p className="text-2xl font-bold text-emerald-600 mt-1">{approvedCount}</p>
        </div>
        <div className="bg-white border border-slate-200 rounded-2xl p-4 shadow-sm">
          <span className="text-xs text-rose-600 font-semibold uppercase">Rejected</span>
          <p className="text-2xl font-bold text-rose-600 mt-1">{rejectedCount}</p>
        </div>
      </div>

      {/* Top Filter Bar */}
      <div className="bg-white border border-slate-200 rounded-2xl p-4 shadow-sm space-y-4">
        <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
          {/* Status Tabs */}
          <div className="flex flex-wrap gap-1.5">
            {[
              { label: 'All Statuses', val: 'ALL' },
              { label: 'Under Review', val: 'SUBMITTED' },
              { label: 'Approved', val: 'APPROVED' },
              { label: 'Rejected', val: 'REJECTED' },
            ].map((t) => (
              <button
                key={t.val}
                onClick={() => setFilterStatus(t.val)}
                className={`px-3.5 py-1.5 rounded-xl text-xs font-semibold transition-all ${
                  filterStatus === t.val
                    ? 'bg-emerald-600 text-white shadow-sm'
                    : 'bg-slate-50 text-slate-600 hover:bg-slate-100 border border-slate-200'
                }`}
              >
                {t.label}
              </button>
            ))}
          </div>

          {/* Date Filter Dropdown & Custom Range */}
          <div className="flex flex-wrap items-center gap-2">
            <div className="flex items-center space-x-1.5 bg-slate-50 border border-slate-200 rounded-xl px-3 py-1.5 text-xs text-slate-700">
              <Calendar className="h-3.5 w-3.5 text-slate-400" />
              <select
                value={dateFilter}
                onChange={(e) => setDateFilter(e.target.value)}
                className="bg-transparent font-semibold text-slate-900 focus:outline-none cursor-pointer"
              >
                <option value="ALL">All Time</option>
                <option value="TODAY">Today's Listings</option>
                <option value="YESTERDAY">Yesterday</option>
                <option value="WEEK">Last 7 Days</option>
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
        </div>

        {/* Search Bar */}
        <form onSubmit={handleSearchSubmit} className="relative">
          <Search className="absolute left-3.5 top-3 h-4 w-4 text-slate-400" />
          <input
            type="text"
            placeholder="Search property title, location, or Agent Name / Mobile Number..."
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

      {/* Property Listing View */}
      {loading ? (
        <div className="bg-white border border-slate-200 rounded-2xl p-12 text-center text-slate-400 font-medium">
          Loading property listings & pictures...
        </div>
      ) : filteredProperties.length === 0 ? (
        <div className="bg-white border border-slate-200 rounded-2xl p-12 text-center text-slate-400">
          <Building2 className="h-12 w-12 mx-auto text-slate-300 mb-3" />
          <p className="font-semibold text-slate-700">No Property Listings Found</p>
          <p className="text-xs text-slate-400 mt-1">Try adjusting the status or date filters above.</p>
        </div>
      ) : viewMode === 'grid' ? (
        /* Day-wise Grouped Grid View */
        <div className="space-y-8">
          {Object.entries(grouped).map(([dateHeader, list]) => (
            <div key={dateHeader} className="space-y-4">
              <div className="flex items-center space-x-3">
                <div className="flex items-center space-x-2 bg-slate-100 text-slate-800 px-3.5 py-1 rounded-full text-xs font-bold border border-slate-200">
                  <Calendar className="h-3.5 w-3.5 text-emerald-600" />
                  <span>{dateHeader}</span>
                </div>
                <span className="text-xs font-semibold text-slate-400">({list.length} listings)</span>
                <div className="h-px bg-slate-200 flex-1" />
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                {list.map((prop) => {
                  const primaryImg = prop.images?.find((i) => i.isPrimary) || prop.images?.[0];
                  return (
                    <div
                      key={prop.id}
                      className="bg-white border border-slate-200 rounded-2xl overflow-hidden shadow-sm hover:shadow-md transition-all flex flex-col"
                    >
                      {/* Image Preview Banner */}
                      <div className="relative h-48 bg-slate-100 overflow-hidden group">
                        {primaryImg?.url ? (
                          <img
                            src={primaryImg.url}
                            alt={prop.title}
                            className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300 cursor-pointer"
                            onClick={() => openLightbox(prop.images || [])}
                          />
                        ) : (
                          <div className="w-full h-full flex flex-col items-center justify-center text-slate-400 space-y-1">
                            <Building2 className="h-10 w-10 text-slate-300" />
                            <span className="text-xs">No Photos Uploaded</span>
                          </div>
                        )}

                        {/* Top Category & Photo Count Badges */}
                        <div className="absolute top-3 left-3 flex items-center space-x-2">
                          <span className="px-2.5 py-1 bg-white/90 backdrop-blur-sm rounded-lg text-xs font-bold text-slate-800 shadow-sm">
                            {prop.category.replace('_', ' ')}
                          </span>
                        </div>

                        {prop.images && prop.images.length > 1 && (
                          <button
                            onClick={() => openLightbox(prop.images)}
                            className="absolute top-3 right-3 px-2.5 py-1 bg-slate-900/80 hover:bg-slate-900 text-white rounded-lg text-xs font-bold flex items-center space-x-1 backdrop-blur-sm shadow-sm"
                          >
                            <Layers className="h-3 w-3" />
                            <span>{prop.images.length} Photos</span>
                          </button>
                        )}

                        {/* Status Badge */}
                        <div className="absolute bottom-3 left-3">
                          <span
                            className={`px-2.5 py-1 rounded-lg text-xs font-extrabold shadow-sm ${
                              prop.status === 'APPROVED'
                                ? 'bg-emerald-600 text-white'
                                : prop.status === 'REJECTED'
                                ? 'bg-rose-600 text-white'
                                : 'bg-amber-500 text-white'
                            }`}
                          >
                            {prop.status}
                          </span>
                        </div>
                      </div>

                      {/* Content Details */}
                      <div className="p-5 flex-1 flex flex-col justify-between space-y-4">
                        <div className="space-y-2">
                          <div className="flex items-baseline justify-between">
                            <h3 className="font-bold text-base text-slate-900 line-clamp-1" title={prop.title}>
                              {prop.title}
                            </h3>
                          </div>

                          <p className="text-emerald-700 font-extrabold text-lg">
                            ₹{Number(prop.price).toLocaleString('en-IN')}
                          </p>

                          <div className="flex items-center space-x-1.5 text-xs text-slate-500">
                            <MapPin className="h-3.5 w-3.5 text-slate-400 shrink-0" />
                            <span className="line-clamp-1">{prop.location}</span>
                          </div>
                        </div>

                        {/* Agent / Listed By Section */}
                        <div className="bg-slate-50 border border-slate-200/80 rounded-xl p-3 space-y-1.5">
                          <div className="flex items-center justify-between">
                            <div className="flex items-center space-x-2">
                              <div className="h-7 w-7 rounded-full bg-emerald-100 text-emerald-800 flex items-center justify-center font-bold text-xs">
                                {prop.agent?.fullName ? prop.agent.fullName.charAt(0).toUpperCase() : 'A'}
                              </div>
                              <div>
                                <span className="text-xs font-bold text-slate-900 block leading-tight">
                                  {prop.agent?.fullName || 'Agent Partner'}
                                </span>
                                <span className="text-[11px] text-slate-500 flex items-center space-x-1">
                                  <Phone className="h-2.5 w-2.5 inline" />
                                  <span>+91 {prop.agent?.mobileNumber}</span>
                                </span>
                              </div>
                            </div>
                          </div>

                          <div className="flex items-center justify-between text-[11px] text-slate-400 pt-1 border-t border-slate-200">
                            <span className="flex items-center space-x-1">
                              <Clock className="h-3 w-3" />
                              <span>{new Date(prop.createdAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</span>
                            </span>
                            <span className="text-slate-500 font-medium">{prop.agent?.areaLocation || 'Bangalore'}</span>
                          </div>
                        </div>

                        {/* Action Buttons */}
                        <div className="flex items-center space-x-2 pt-2">
                          <button
                            onClick={() => setInspectProperty(prop)}
                            className="flex-1 py-2 bg-slate-100 hover:bg-slate-200 text-slate-700 font-semibold rounded-xl text-xs flex items-center justify-center space-x-1.5 transition-colors"
                          >
                            <Eye className="h-3.5 w-3.5" />
                            <span>Inspect</span>
                          </button>

                          {prop.status !== 'APPROVED' && (
                            <button
                              onClick={() => handleReviewAction(prop.id, true)}
                              className="flex-1 py-2 bg-emerald-600 hover:bg-emerald-700 text-white font-semibold rounded-xl text-xs flex items-center justify-center space-x-1.5 shadow-sm transition-colors"
                            >
                              <CheckCircle2 className="h-3.5 w-3.5" />
                              <span>Approve</span>
                            </button>
                          )}

                          {prop.status !== 'REJECTED' && (
                            <button
                              onClick={() => handleReviewAction(prop.id, false)}
                              className="p-2 bg-rose-50 hover:bg-rose-600 hover:text-white text-rose-700 border border-rose-200 rounded-xl transition-colors"
                              title="Reject Listing"
                            >
                              <XCircle className="h-4 w-4" />
                            </button>
                          )}
                        </div>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          ))}
        </div>
      ) : (
        /* Table View */
        <div className="bg-white border border-slate-200 rounded-2xl overflow-hidden shadow-sm">
          <table className="w-full text-left text-sm">
            <thead className="bg-slate-50 text-xs font-semibold text-slate-500 uppercase tracking-wider border-b border-slate-200">
              <tr>
                <th className="p-4">Property</th>
                <th className="p-4">Listed By (Agent)</th>
                <th className="p-4">Category</th>
                <th className="p-4">Price (₹)</th>
                <th className="p-4">Location</th>
                <th className="p-4">Submission Date</th>
                <th className="p-4">Status</th>
                <th className="p-4 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {filteredProperties.map((prop) => (
                <tr key={prop.id} className="hover:bg-slate-50 transition-colors">
                  <td className="p-4">
                    <div className="flex items-center space-x-3">
                      {prop.images?.[0]?.url ? (
                        <img
                          src={prop.images[0].url}
                          alt={prop.title}
                          className="h-10 w-10 rounded-lg object-cover cursor-pointer"
                          onClick={() => openLightbox(prop.images)}
                        />
                      ) : (
                        <div className="h-10 w-10 rounded-lg bg-slate-100 flex items-center justify-center text-slate-400">
                          <Building2 className="h-5 w-5" />
                        </div>
                      )}
                      <div>
                        <span className="font-bold text-slate-900 block line-clamp-1">{prop.title}</span>
                        <span className="text-xs text-slate-400">{prop.images?.length || 0} photos</span>
                      </div>
                    </div>
                  </td>
                  <td className="p-4">
                    <div>
                      <span className="font-semibold text-slate-900 block">{prop.agent?.fullName || 'Agent Partner'}</span>
                      <span className="text-xs text-slate-500">+91 {prop.agent?.mobileNumber}</span>
                    </div>
                  </td>
                  <td className="p-4 text-slate-700">{prop.category.replace('_', ' ')}</td>
                  <td className="p-4 font-bold text-emerald-700">₹{Number(prop.price).toLocaleString('en-IN')}</td>
                  <td className="p-4 text-slate-600">{prop.location}</td>
                  <td className="p-4 text-slate-600 text-xs">
                    {new Date(prop.createdAt).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' })}
                  </td>
                  <td className="p-4">
                    <span
                      className={`px-2.5 py-1 rounded-full text-xs font-bold ${
                        prop.status === 'APPROVED'
                          ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                          : prop.status === 'REJECTED'
                          ? 'bg-rose-50 text-rose-700 border border-rose-200'
                          : 'bg-amber-50 text-amber-700 border border-amber-200'
                      }`}
                    >
                      {prop.status}
                    </span>
                  </td>
                  <td className="p-4 text-right space-x-2">
                    <button
                      onClick={() => setInspectProperty(prop)}
                      className="px-2.5 py-1 bg-slate-100 hover:bg-slate-200 text-slate-700 rounded-lg text-xs font-semibold"
                    >
                      Inspect
                    </button>
                    {prop.status !== 'APPROVED' && (
                      <button
                        onClick={() => handleReviewAction(prop.id, true)}
                        className="px-2.5 py-1 bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg text-xs font-semibold shadow-sm"
                      >
                        Approve
                      </button>
                    )}
                    {prop.status !== 'REJECTED' && (
                      <button
                        onClick={() => handleReviewAction(prop.id, false)}
                        className="px-2.5 py-1 bg-rose-50 hover:bg-rose-600 hover:text-white text-rose-700 border border-rose-200 rounded-lg text-xs font-semibold"
                      >
                        Reject
                      </button>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* Property Full Inspection Modal */}
      {inspectProperty && (
        <Modal isOpen={!!inspectProperty} onClose={() => setInspectProperty(null)} title="Property Details & Specifications">
          <div className="space-y-6">
            {/* Gallery */}
            {inspectProperty.images && inspectProperty.images.length > 0 && (
              <div>
                <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-2">
                  Uploaded Photos ({inspectProperty.images.length})
                </label>
                <div className="grid grid-cols-3 sm:grid-cols-4 gap-2">
                  {inspectProperty.images.map((img, idx) => (
                    <div
                      key={img.id}
                      onClick={() => openLightbox(inspectProperty.images, idx)}
                      className="relative h-24 rounded-xl overflow-hidden border border-slate-200 cursor-pointer group"
                    >
                      {img.url ? (
                        <img src={img.url} alt="prop" className="w-full h-full object-cover group-hover:scale-105 transition-transform" />
                      ) : (
                        <div className="w-full h-full bg-slate-100 flex items-center justify-center text-xs text-slate-400">Photo</div>
                      )}
                      {img.isPrimary && (
                        <span className="absolute bottom-1 left-1 bg-emerald-600 text-white text-[10px] font-bold px-1.5 py-0.5 rounded">
                          Primary
                        </span>
                      )}
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Core Info */}
            <div className="grid grid-cols-2 gap-4 bg-slate-50 p-4 rounded-xl border border-slate-200 text-xs">
              <div>
                <span className="text-slate-500 font-semibold">Title:</span>
                <p className="text-slate-900 font-bold mt-0.5">{inspectProperty.title}</p>
              </div>
              <div>
                <span className="text-slate-500 font-semibold">Price:</span>
                <p className="text-emerald-700 font-bold mt-0.5">₹{Number(inspectProperty.price).toLocaleString('en-IN')}</p>
              </div>
              <div>
                <span className="text-slate-500 font-semibold">Category:</span>
                <p className="text-slate-900 font-bold mt-0.5">{inspectProperty.category.replace('_', ' ')}</p>
              </div>
              <div>
                <span className="text-slate-500 font-semibold">Location:</span>
                <p className="text-slate-900 font-bold mt-0.5">{inspectProperty.location}</p>
              </div>
            </div>

            {/* Description */}
            <div>
              <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">Description</label>
              <p className="text-xs text-slate-700 bg-slate-50 p-3 rounded-xl border border-slate-200 leading-relaxed">
                {inspectProperty.description || 'No description provided.'}
              </p>
            </div>

            {/* Specifications */}
            {inspectProperty.specifications && Object.keys(inspectProperty.specifications).length > 0 && (
              <div>
                <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">Specifications</label>
                <div className="grid grid-cols-2 sm:grid-cols-3 gap-2 text-xs">
                  {Object.entries(inspectProperty.specifications).map(([k, v]) => (
                    <div key={k} className="bg-slate-50 p-2.5 rounded-lg border border-slate-200">
                      <span className="text-slate-500 capitalize">{k.replace(/([A-Z])/g, ' $1')}:</span>
                      <p className="font-bold text-slate-900 mt-0.5">{String(v)}</p>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Listed By Agent */}
            <div className="bg-emerald-50 border border-emerald-200 p-4 rounded-xl flex items-center justify-between text-xs">
              <div>
                <span className="text-emerald-800 font-semibold">Listed by Verified Agent</span>
                <p className="text-slate-900 font-bold text-sm mt-0.5">{inspectProperty.agent?.fullName || 'Agent Partner'}</p>
                <p className="text-slate-600 mt-0.5">Mobile: +91 {inspectProperty.agent?.mobileNumber}</p>
              </div>
              <div className="text-right text-slate-500">
                <span>Submitted on</span>
                <p className="font-bold text-slate-800">
                  {new Date(inspectProperty.createdAt).toLocaleDateString('en-IN', {
                    day: 'numeric',
                    month: 'short',
                    year: 'numeric',
                  })}
                </p>
              </div>
            </div>

            {/* Action Bar inside modal */}
            <div className="flex items-center space-x-3 pt-2">
              <button
                onClick={() => setInspectProperty(null)}
                className="flex-1 py-2.5 bg-slate-100 hover:bg-slate-200 text-slate-700 font-semibold rounded-xl text-xs"
              >
                Close
              </button>
              {inspectProperty.status !== 'APPROVED' && (
                <button
                  onClick={() => executeReview(inspectProperty.id, true)}
                  disabled={actionLoading}
                  className="flex-1 py-2.5 bg-emerald-600 hover:bg-emerald-700 text-white font-semibold rounded-xl text-xs flex items-center justify-center space-x-1.5 shadow-sm"
                >
                  <CheckCircle2 className="h-4 w-4" />
                  <span>Approve & Publish</span>
                </button>
              )}
              {inspectProperty.status !== 'REJECTED' && (
                <button
                  onClick={() => {
                    setSelectedPropertyId(inspectProperty.id);
                    setRejectionReason('');
                    setRejectionModalOpen(true);
                  }}
                  disabled={actionLoading}
                  className="flex-1 py-2.5 bg-rose-50 hover:bg-rose-600 hover:text-white text-rose-700 border border-rose-200 font-semibold rounded-xl text-xs flex items-center justify-center space-x-1.5"
                >
                  <XCircle className="h-4 w-4" />
                  <span>Reject Listing</span>
                </button>
              )}
            </div>
          </div>
        </Modal>
      )}

      {/* Rejection Reason Modal */}
      <Modal isOpen={rejectionModalOpen} onClose={() => setRejectionModalOpen(false)} title="Reject Property Listing">
        <div className="space-y-4">
          <p className="text-xs text-slate-500">
            Please enter the official reason for rejecting this listing. The reason will be pushed directly to the agent's mobile app.
          </p>
          <div>
            <label className="block text-xs font-semibold text-slate-700 mb-1">Rejection Reason</label>
            <textarea
              value={rejectionReason}
              onChange={(e) => setRejectionReason(e.target.value)}
              rows={3}
              placeholder="e.g. Incomplete address, photos unclear, or price invalid"
              className="w-full bg-slate-50 border border-slate-300 rounded-xl p-3 text-xs text-slate-900 focus:outline-none focus:border-rose-500 focus:bg-white"
            />
          </div>
          <div className="flex justify-end space-x-3 pt-2">
            <button
              onClick={() => setRejectionModalOpen(false)}
              className="px-4 py-2 bg-slate-100 text-slate-600 rounded-xl text-xs font-semibold hover:bg-slate-200"
            >
              Cancel
            </button>
            <button
              onClick={() => selectedPropertyId && executeReview(selectedPropertyId, false, rejectionReason)}
              disabled={actionLoading}
              className="px-4 py-2 bg-rose-600 hover:bg-rose-700 text-white rounded-xl text-xs font-semibold shadow-md shadow-rose-600/15"
            >
              {actionLoading ? 'Processing...' : 'Confirm Rejection'}
            </button>
          </div>
        </div>
      </Modal>

      {/* Image Lightbox Modal */}
      {lightboxImages.length > 0 && (
        <div className="fixed inset-0 z-50 bg-slate-950/90 flex items-center justify-center p-4 backdrop-blur-md">
          <button
            onClick={() => setLightboxImages([])}
            className="absolute top-6 right-6 text-white/80 hover:text-white p-2 rounded-full bg-white/10"
          >
            <XCircle className="h-6 w-6" />
          </button>

          {lightboxImages.length > 1 && (
            <>
              <button
                onClick={() => setLightboxIndex((prev) => (prev > 0 ? prev - 1 : lightboxImages.length - 1))}
                className="absolute left-6 text-white/80 hover:text-white p-3 rounded-full bg-white/10"
              >
                <ChevronLeft className="h-6 w-6" />
              </button>
              <button
                onClick={() => setLightboxIndex((prev) => (prev < lightboxImages.length - 1 ? prev + 1 : 0))}
                className="absolute right-6 text-white/80 hover:text-white p-3 rounded-full bg-white/10"
              >
                <ChevronRight className="h-6 w-6" />
              </button>
            </>
          )}

          <div className="max-w-4xl max-h-[85vh] flex flex-col items-center">
            <img
              src={lightboxImages[lightboxIndex]}
              alt={`Photo ${lightboxIndex + 1}`}
              className="max-w-full max-h-[80vh] rounded-2xl object-contain shadow-2xl"
            />
            <span className="text-white/80 text-xs font-bold mt-4">
              Photo {lightboxIndex + 1} of {lightboxImages.length}
            </span>
          </div>
        </div>
      )}
    </div>
  );
};

