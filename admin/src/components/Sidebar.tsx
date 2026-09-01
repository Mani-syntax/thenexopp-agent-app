import React from 'react';
import { NavLink } from 'react-router-dom';
import { LayoutDashboard, Users, FileCheck, Building2, WalletCards, Shield } from 'lucide-react';

export const Sidebar: React.FC = () => {
  const links = [
    { to: '/', label: 'Overview', icon: LayoutDashboard },
    { to: '/agents', label: 'Agents & Partners', icon: Users },
    { to: '/kyc', label: 'KYC Verification', icon: FileCheck },
    { to: '/properties', label: 'Property Listings', icon: Building2 },
    { to: '/financials', label: 'Earnings & Payouts', icon: WalletCards },
  ];

  return (
    <aside className="w-64 bg-white border-r border-slate-200 flex flex-col min-h-screen">
      <div className="p-6 border-b border-slate-200 flex items-center space-x-3">
        <div className="h-10 w-10 bg-emerald-50 border border-emerald-200 rounded-xl flex items-center justify-center text-emerald-600">
          <Shield className="h-6 w-6" />
        </div>
        <div>
          <h1 className="font-bold text-lg text-slate-900 tracking-tight">TheNexopp</h1>
          <p className="text-xs text-slate-500 font-medium">Agent Network Admin</p>
        </div>
      </div>

      <nav className="flex-1 p-4 space-y-1">
        {links.map((link) => {
          const Icon = link.icon;
          return (
            <NavLink
              key={link.to}
              to={link.to}
              className={({ isActive }) =>
                `flex items-center space-x-3 px-4 py-3 rounded-xl font-medium text-sm transition-all ${
                  isActive
                    ? 'bg-emerald-600 text-white shadow-md shadow-emerald-600/15'
                    : 'text-slate-600 hover:bg-slate-100 hover:text-slate-900'
                }`
              }
            >
              <Icon className="h-5 w-5" />
              <span>{link.label}</span>
            </NavLink>
          );
        })}
      </nav>

      <div className="p-4 border-t border-slate-200">
        <div className="bg-slate-50 border border-slate-200 p-3 rounded-xl text-xs text-slate-500 text-center font-medium">
          Production Admin v1.0.0
        </div>
      </div>
    </aside>
  );
};
