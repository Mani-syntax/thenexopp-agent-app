import React from 'react';
import { LogOut, Bell, UserCheck, Radio } from 'lucide-react';
import { useAuth } from '../context/AuthContext';

export const Navbar: React.FC = () => {
  const { logout, socketConnected } = useAuth();

  return (
    <header className="h-16 bg-white/90 backdrop-blur border-b border-slate-200 px-8 flex items-center justify-between sticky top-0 z-20">
      <div className="flex items-center space-x-3 text-xs font-semibold">
        <div
          className={`flex items-center space-x-2 px-3 py-1 rounded-full border ${
            socketConnected
              ? 'bg-emerald-50 text-emerald-700 border-emerald-200'
              : 'bg-amber-50 text-amber-700 border-amber-200'
          }`}
        >
          <Radio className={`h-3.5 w-3.5 ${socketConnected ? 'animate-pulse text-emerald-600' : 'text-amber-600'}`} />
          <span>{socketConnected ? 'Socket.io Gateway Connected (Live Stream Active)' : 'Connecting Real-Time Gateway...'}</span>
        </div>
      </div>

      <div className="flex items-center space-x-4">
        <button className="p-2 rounded-lg bg-slate-100 text-slate-500 hover:text-slate-900 transition-colors relative">
          <Bell className="h-5 w-5" />
          <span className="absolute top-1 right-1 h-2 w-2 rounded-full bg-emerald-600"></span>
        </button>

        <div className="flex items-center space-x-3 pl-4 border-l border-slate-200">
          <div className="h-9 w-9 bg-emerald-50 rounded-full flex items-center justify-center text-emerald-700 font-bold text-sm border border-emerald-200">
            <UserCheck className="h-5 w-5 text-emerald-600" />
          </div>
          <div className="text-left">
            <p className="text-sm font-semibold text-slate-900">Executive Admin</p>
            <p className="text-xs text-slate-500">admin@thenexopp.com</p>
          </div>
          <button
            onClick={logout}
            className="p-2 text-slate-400 hover:text-rose-600 transition-colors ml-2"
            title="Logout"
          >
            <LogOut className="h-5 w-5" />
          </button>
        </div>
      </div>
    </header>
  );
};
