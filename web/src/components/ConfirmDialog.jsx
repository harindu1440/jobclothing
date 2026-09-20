import { motion, AnimatePresence } from 'framer-motion'
import { AlertTriangle, X } from 'lucide-react'

export default function ConfirmDialog({ message, subtext, onConfirm, onCancel, dangerous = false }) {
  return (
    <div className="overlay" onClick={onCancel}>
      <motion.div
        className="glass-panel"
        style={{ width: 340, padding: 24 }}
        initial={{ opacity: 0, scale: 0.9 }}
        animate={{ opacity: 1, scale: 1 }}
        exit={{ opacity: 0, scale: 0.9 }}
        transition={{ duration: 0.15 }}
        onClick={e => e.stopPropagation()}
      >
        <div className="flex items-center gap-3" style={{ marginBottom: 12 }}>
          <div style={{
            width: 36, height: 36, borderRadius: '50%',
            background: dangerous ? 'var(--danger-dim)' : 'var(--accent-dim)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            flexShrink: 0,
          }}>
            <AlertTriangle size={18} color={dangerous ? 'var(--danger)' : 'var(--accent)'} />
          </div>
          <div>
            <div style={{ fontWeight: 600, fontSize: 15 }}>{message}</div>
            {subtext && <div style={{ color: 'var(--text-secondary)', fontSize: 12, marginTop: 2 }}>{subtext}</div>}
          </div>
        </div>

        <div className="flex gap-2" style={{ justifyContent: 'flex-end', marginTop: 20 }}>
          <button className="btn btn-ghost btn-sm" onClick={onCancel}>Cancel</button>
          <button
            className={`btn btn-sm ${dangerous ? 'btn-danger' : 'btn-primary'}`}
            onClick={onConfirm}
          >
            Confirm
          </button>
        </div>
      </motion.div>
    </div>
  )
}
