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
    <aside className="w-64 bg-slate-900 border-r border-slate-800 flex flex-col min-h-screen">
      <div className="p-6 border-b border-slate-800 flex items-center space-x-3">
        <div className="h-10 w-10 bg-emerald-500/10 border border-emerald-500/30 rounded-xl flex items-center justify-center text-emerald-400">
          <Shield className="h-6 w-6" />
        </div>
        <div>
          <h1 className="font-bold text-lg text-slate-100 tracking-tight">TheNexopp</h1>
          <p className="text-xs text-slate-400 font-medium">Agent Network Admin</p>
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
                    ? 'bg-emerald-500 text-white shadow-lg shadow-emerald-500/20'
                    : 'text-slate-400 hover:bg-slate-800 hover:text-slate-200'
                }`
              }
            >
              <Icon className="h-5 w-5" />
              <span>{link.label}</span>
            </NavLink>
          );
        })}
      </nav>

      <div className="p-4 border-t border-slate-800">
        <div className="bg-slate-800/50 border border-slate-700/50 p-3 rounded-xl text-xs text-slate-400 text-center">
          Production Admin v1.0.0
        </div>
      </div>
    </aside>
  );
};
