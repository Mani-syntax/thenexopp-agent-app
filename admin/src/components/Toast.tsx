import React, { useEffect } from 'react';
import { CheckCircle2, AlertCircle, Info, X } from 'lucide-react';

export interface ToastMessage {
  id: string;
  type: 'success' | 'error' | 'info';
  title: string;
  message: string;
}

interface ToastProps {
  toasts: ToastMessage[];
  onRemove: (id: string) => void;
}

export const ToastContainer: React.FC<ToastProps> = ({ toasts, onRemove }) => {
  return (
    <div className="fixed bottom-6 right-6 z-50 flex flex-col space-y-3 max-w-sm w-full">
      {toasts.map((toast) => (
        <ToastItem key={toast.id} toast={toast} onRemove={onRemove} />
      ))}
    </div>
  );
};

const ToastItem: React.FC<{ toast: ToastMessage; onRemove: (id: string) => void }> = ({ toast, onRemove }) => {
  useEffect(() => {
    const timer = setTimeout(() => {
      onRemove(toast.id);
    }, 4000);
    return () => clearTimeout(timer);
  }, [toast.id, onRemove]);

  return (
    <div
      className={`p-4 rounded-xl border shadow-xl flex items-start space-x-3 transition-all transform translate-y-0 ${
        toast.type === 'success'
          ? 'bg-slate-900 border-emerald-500/50 text-emerald-400'
          : toast.type === 'error'
          ? 'bg-slate-900 border-red-500/50 text-red-400'
          : 'bg-slate-900 border-blue-500/50 text-blue-400'
      }`}
    >
      {toast.type === 'success' && <CheckCircle2 className="h-5 w-5 shrink-0 mt-0.5" />}
      {toast.type === 'error' && <AlertCircle className="h-5 w-5 shrink-0 mt-0.5" />}
      {toast.type === 'info' && <Info className="h-5 w-5 shrink-0 mt-0.5" />}

      <div className="flex-1 min-w-0">
        <h4 className="text-sm font-bold text-slate-100">{toast.title}</h4>
        <p className="text-xs text-slate-300 mt-0.5">{toast.message}</p>
      </div>

      <button onClick={() => onRemove(toast.id)} className="text-slate-400 hover:text-slate-200">
        <X className="h-4 w-4" />
      </button>
    </div>
  );
};
