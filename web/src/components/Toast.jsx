import { AnimatePresence, motion } from 'framer-motion'
import { CheckCircle, AlertCircle, Info, X } from 'lucide-react'

const ICONS = {
  success: CheckCircle,
  error: AlertCircle,
  info: Info,
}

export default function Toast({ toasts }) {
  return (
    <div className="toast-container">
      <AnimatePresence>
        {toasts.map(t => {
          const Icon = ICONS[t.type] || Info
          return (
            <motion.div
              key={t.id}
              className={`toast ${t.type}`}
              initial={{ opacity: 0, x: 60, scale: 0.9 }}
              animate={{ opacity: 1, x: 0, scale: 1 }}
              exit={{ opacity: 0, x: 60, scale: 0.9 }}
              transition={{ duration: 0.2 }}
            >
              <Icon size={16} />
              <span style={{ flex: 1 }}>{t.message}</span>
            </motion.div>
          )
        })}
      </AnimatePresence>
    </div>
  )
}
