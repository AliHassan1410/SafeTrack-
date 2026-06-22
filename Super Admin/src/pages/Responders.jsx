import { useEffect, useState } from 'react'
import { api, suspendUser, unsuspendUser } from '../services/api'
import { motion } from 'framer-motion'
import toast from 'react-hot-toast'
import './Responders.css'
import '../pages/Dashboard.css'

const TYPE_COLOR = { medical: 'blue', crime: 'red' }

function timeAgo(d) {
  const diff = Date.now() - new Date(d)
  const m = Math.floor(diff / 60000)
  if (m < 1) return 'Just now'
  if (m < 60) return `${m}m ago`
  const h = Math.floor(m / 60)
  if (h < 24) return `${h}h ago`
  return new Date(d).toLocaleDateString()
}

export default function Responders() {
  const [responders, setResponders] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [search, setSearch] = useState('')
  const [actionLoading, setActionLoading] = useState(null)

  const fetchResponders = () => {
    api.get('/api/auth/users?role=responder')
      .then(res => setResponders(res.data?.users || res.data || []))
      .catch(err => {
        setError(err.response?.data?.message || 'Failed to load responders')
        toast.error('Failed to load responders')
      })
      .finally(() => setLoading(false))
  }

  useEffect(() => { fetchResponders() }, [])

  const handleSuspend = async (id, name) => {
    if (!window.confirm(`Suspend "${name}"? They will not be able to log in.`)) return
    setActionLoading(id)
    try {
      await suspendUser(id)
      toast.success(`${name} has been suspended`)
      setResponders(prev => prev.map(r => r._id === id ? { ...r, isSuspended: true, suspendedByName: 'Super Admin' } : r))
    } catch (err) {
      toast.error(err.response?.data?.message || 'Failed to suspend')
    } finally {
      setActionLoading(null)
    }
  }

  const handleUnsuspend = async (id, name) => {
    setActionLoading(id)
    try {
      await unsuspendUser(id)
      toast.success(`${name} has been reinstated`)
      setResponders(prev => prev.map(r => r._id === id ? { ...r, isSuspended: false, suspendedByName: null } : r))
    } catch (err) {
      toast.error(err.response?.data?.message || 'Failed to unsuspend')
    } finally {
      setActionLoading(null)
    }
  }

  const filtered = responders.filter(r => {
    const q = search.toLowerCase()
    return !q || r.name?.toLowerCase().includes(q) || r.email?.toLowerCase().includes(q) || r.responderType?.toLowerCase().includes(q)
  })

  return (
    <motion.div
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.3 }}
    >
      <div className="page-header">
        <div>
          <h1 className="page-title">Responders</h1>
          <p className="page-subtitle">Manage emergency responders — suspend those who violate protocol</p>
        </div>
        <div className="responders-count">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/>
            <circle cx="9" cy="7" r="4"/>
            <path d="M23 21v-2a4 4 0 00-3-3.87"/>
            <path d="M16 3.13a4 4 0 010 7.75"/>
          </svg>
          {responders.length} Registered
        </div>
      </div>

      {error && <div className="dashboard-error" style={{marginBottom:20}}>{error}</div>}

      {/* Search */}
      <div style={{marginBottom:20, display:'flex'}}>
        <div className="search-wrap" style={{marginLeft:0}}>
          <svg className="search-icon" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
            <circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
          </svg>
          <input className="search-input" placeholder="Search responders..." value={search} onChange={e => setSearch(e.target.value)} />
        </div>
      </div>

      {loading ? (
        <div className="responders-grid">
          {[1,2,3,4,5,6].map(i => <div key={i} className="responder-card shimmer" style={{height:200}} />)}
        </div>
      ) : filtered.length === 0 ? (
        <div className="dashboard-section">
          <div className="empty-state">
            {responders.length === 0 ? 'No responders registered yet.' : 'No responders match your search.'}
          </div>
        </div>
      ) : (
        <div className="responders-grid">
          {filtered.map(r => {
            const typeColor = TYPE_COLOR[r.responderType] || 'green'
            const isBusy = actionLoading === r._id
            return (
              <div key={r._id} className={`responder-card ${r.isSuspended ? 'responder-card--suspended' : ''}`}>
                {r.isSuspended && (
                  <div className="suspension-banner">
                    <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                      <circle cx="12" cy="12" r="10"/><line x1="4.93" y1="4.93" x2="19.07" y2="19.07"/>
                    </svg>
                    SUSPENDED {r.suspendedByName ? `by ${r.suspendedByName}` : ''}
                  </div>
                )}
                <div className="responder-card-top">
                  <div className={`responder-avatar ${r.isSuspended ? 'avatar--suspended' : ''}`}>
                    {r.name?.charAt(0)?.toUpperCase() || 'R'}
                  </div>
                  <div>
                    <div className="responder-name">{r.name}</div>
                    <div className="responder-email">{r.email}</div>
                  </div>
                </div>
                <div className="responder-divider" />
                <div className="responder-meta">
                  {r.responderType && (
                    <span className={`badge badge-${typeColor}`}>
                      {r.responderType === 'medical' ? '🏥 Medical' : '🚔 Crime / Police'}
                    </span>
                  )}
                  <div className="responder-info-row">
                    <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                      <path d="M22 16.92v3a2 2 0 01-2.18 2 19.79 19.79 0 01-8.63-3.07A19.5 19.5 0 013.07 9.81 19.79 19.79 0 01.01 1.18 2 2 0 012 .01h3a2 2 0 012 1.72c.127.96.361 1.903.7 2.81a2 2 0 01-.45 2.11L6.09 7.91a16 16 0 006 6l1.27-1.27a2 2 0 012.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0122 16.92z"/>
                    </svg>
                    {r.phone || 'Not provided'}
                  </div>
                  <div className="responder-info-row">
                    <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                      <circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/>
                    </svg>
                    Joined {timeAgo(r.createdAt)}
                  </div>
                </div>

                {/* Suspend / Unsuspend Button */}
                <div className="responder-actions">
                  {r.isSuspended ? (
                    <button
                      className="btn-unsuspend"
                      onClick={() => handleUnsuspend(r._id, r.name)}
                      disabled={isBusy}
                    >
                      {isBusy ? <span className="btn-spinner" /> : (
                        <>
                          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                            <polyline points="20 6 9 17 4 12"/>
                          </svg>
                          Reinstate
                        </>
                      )}
                    </button>
                  ) : (
                    <button
                      className="btn-suspend"
                      onClick={() => handleSuspend(r._id, r.name)}
                      disabled={isBusy}
                    >
                      {isBusy ? <span className="btn-spinner" /> : (
                        <>
                          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                            <circle cx="12" cy="12" r="10"/><line x1="4.93" y1="4.93" x2="19.07" y2="19.07"/>
                          </svg>
                          Suspend
                        </>
                      )}
                    </button>
                  )}

                  <div className={`responder-status-dot ${r.isSuspended ? 'suspended' : r.isEmailVerified ? 'verified' : 'unverified'}`}>
                    {r.isSuspended ? '⛔ Suspended' : r.isEmailVerified ? '✓ Verified' : '⚠ Unverified'}
                  </div>
                </div>
              </div>
            )
          })}
        </div>
      )}
    </motion.div>
  )
}
