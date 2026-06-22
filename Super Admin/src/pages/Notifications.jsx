import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { Bell, Check, Trash2, AlertTriangle, Info, CheckCircle, Server } from 'lucide-react'
import './Notifications.css'

const INITIAL_NOTIFS = [
  {
    id: 1,
    type: 'alert',
    title: 'High Priority: Medical Emergency',
    desc: 'A critical medical emergency was reported at 142 Main St. Dispatch immediately.',
    time: '2 mins ago',
    unread: true,
  },
  {
    id: 2,
    type: 'system',
    title: 'System Maintenance Scheduled',
    desc: 'SafeTrack servers will undergo scheduled maintenance on Sunday at 2:00 AM EST. Expected downtime is 15 minutes.',
    time: '1 hour ago',
    unread: true,
  },
  {
    id: 3,
    type: 'success',
    title: 'Incident #INC-892 Resolved',
    desc: 'Responder Sarah Jenkins has successfully resolved the traffic accident on Route 9.',
    time: '3 hours ago',
    unread: false,
  },
  {
    id: 4,
    type: 'info',
    title: 'New Responder Registered',
    desc: 'Officer Michael Scott has been added to the police dispatch unit and is awaiting approval.',
    time: '1 day ago',
    unread: false,
  },
  {
    id: 5,
    type: 'alert',
    title: 'Fire Reported: Downtown Warehouse',
    desc: 'Multiple reports of smoke coming from the abandoned warehouse district. Fire units dispatched.',
    time: '2 days ago',
    unread: false,
  }
]

export default function Notifications() {
  const [notifs, setNotifs] = useState(INITIAL_NOTIFS)
  const [tab, setTab] = useState('all')

  const unreadCount = notifs.filter(n => n.unread).length

  const filteredNotifs = notifs.filter(n => {
    if (tab === 'unread') return n.unread
    return true
  })

  const markAllRead = () => {
    setNotifs(notifs.map(n => ({ ...n, unread: false })))
  }

  const markRead = (id) => {
    setNotifs(notifs.map(n => n.id === id ? { ...n, unread: false } : n))
  }

  const deleteNotif = (id) => {
    setNotifs(notifs.filter(n => n.id !== id))
  }

  const getIcon = (type) => {
    switch(type) {
      case 'alert': return <AlertTriangle size={20} />
      case 'system': return <Server size={20} />
      case 'success': return <CheckCircle size={20} />
      case 'info':
      default: return <Info size={20} />
    }
  }

  return (
    <motion.div 
      className="notifications-page"
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.3 }}
    >
      <div className="page-header">
        <div>
          <h1 className="page-title">Notifications</h1>
          <p className="page-subtitle">View system alerts, incident updates, and messages</p>
        </div>
        <div className="notif-header-actions">
          {unreadCount > 0 && (
            <button className="notif-btn primary" onClick={markAllRead}>
              <Check size={16} /> Mark all read
            </button>
          )}
          <button className="notif-btn" onClick={() => setNotifs([])}>
            <Trash2 size={16} /> Clear all
          </button>
        </div>
      </div>

      <div className="notif-tabs">
        <button 
          className={`notif-tab ${tab === 'all' ? 'active' : ''}`}
          onClick={() => setTab('all')}
        >
          All Notifications
        </button>
        <button 
          className={`notif-tab ${tab === 'unread' ? 'active' : ''}`}
          onClick={() => setTab('unread')}
        >
          Unread {unreadCount > 0 && <span className="notif-badge">{unreadCount}</span>}
        </button>
      </div>

      <div className="notif-list">
        <AnimatePresence>
          {filteredNotifs.length === 0 ? (
            <motion.div 
              initial={{ opacity: 0 }} 
              animate={{ opacity: 1 }} 
              exit={{ opacity: 0 }}
              className="empty-state"
            >
              <Bell size={40} style={{ opacity: 0.2, marginBottom: 16 }} />
              <p>No notifications to display.</p>
            </motion.div>
          ) : (
            filteredNotifs.map(n => (
              <motion.div
                key={n.id}
                layout
                initial={{ opacity: 0, scale: 0.95 }}
                animate={{ opacity: 1, scale: 1 }}
                exit={{ opacity: 0, scale: 0.95, transition: { duration: 0.2 } }}
                className={`notif-card ${n.unread ? 'unread' : ''}`}
              >
                <div className={`notif-icon-wrap ${n.type}`}>
                  {getIcon(n.type)}
                </div>
                <div className="notif-content">
                  <h3 className="notif-title">{n.title}</h3>
                  <p className="notif-desc">{n.desc}</p>
                  <div className="notif-meta">
                    <span className="notif-time">{n.time}</span>
                    {n.unread && (
                      <>
                        <span>•</span>
                        <button className="notif-action-btn" onClick={() => markRead(n.id)}>
                          Mark as read
                        </button>
                      </>
                    )}
                  </div>
                </div>
                <button 
                  className="notif-delete" 
                  title="Delete notification"
                  onClick={() => deleteNotif(n.id)}
                >
                  <Trash2 size={16} />
                </button>
              </motion.div>
            ))
          )}
        </AnimatePresence>
      </div>

    </motion.div>
  )
}
