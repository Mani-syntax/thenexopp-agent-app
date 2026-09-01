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
      className={`p-4 rounded-xl border shadow-xl flex items-start space-x-3 transition-all transform translate-y-0 bg-white ${
        toast.type === 'success'
          ? 'border-emerald-200 text-emerald-800'
          : toast.type === 'error'
          ? 'border-rose-200 text-rose-800'
          : 'border-blue-200 text-blue-800'
      }`}
    >
      {toast.type === 'success' && <CheckCircle2 className="h-5 w-5 shrink-0 mt-0.5 text-emerald-600" />}
      {toast.type === 'error' && <AlertCircle className="h-5 w-5 shrink-0 mt-0.5 text-rose-600" />}
      {toast.type === 'info' && <Info className="h-5 w-5 shrink-0 mt-0.5 text-blue-600" />}

      <div className="flex-1 min-w-0">
        <h4 className="text-sm font-bold text-slate-900">{toast.title}</h4>
        <p className="text-xs text-slate-600 mt-0.5">{toast.message}</p>
      </div>

      <button onClick={() => onRemove(toast.id)} className="text-slate-400 hover:text-slate-700">
        <X className="h-4 w-4" />
      </button>
    </div>
  );
};
