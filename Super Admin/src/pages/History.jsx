import { useEffect, useState } from 'react'
import { getIncidents } from '../services/api'
import { motion } from 'framer-motion'
import toast from 'react-hot-toast'
import { MapPin, Clock, User, CheckCircle, XCircle, Download } from 'lucide-react'
import {
  ResponsiveContainer,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Cell,
} from 'recharts'
import QueryBox from '../components/QueryBox'
import './History.css'
import '../pages/Dashboard.css'

const STATUS_COLORS = {
  resolved: 'green',
  cancelled: 'red',
}

const TYPE_LABELS = {
  crime: { label: 'Crime', color: 'red', hex: '#ef4444' },
  medical: { label: 'Medical', color: 'blue', hex: '#4f6ef7' },
  fire: { label: 'Fire', color: 'amber', hex: '#f59e0b' },
  accident: { label: 'Accident', color: 'purple', hex: '#a855f7' },
  other: { label: 'Other', color: 'green', hex: '#10b981' },
}

function formatDuration(createdAt, updatedAt) {
  if (!updatedAt || !createdAt) return '—'
  const ms = new Date(updatedAt) - new Date(createdAt)
  const mins = Math.floor(ms / 60000)
  if (mins < 1) return '< 1 min'
  if (mins < 60) return `${mins} min`
  const hrs = Math.floor(mins / 60)
  if (hrs < 24) return `${hrs}h ${mins % 60}m`
  return `${Math.floor(hrs / 24)}d ${hrs % 24}h`
}

export default function History() {
  const [incidents, setIncidents] = useState([])
  const [loading, setLoading] = useState(true)
  const [filter, setFilter] = useState('all')
  const [search, setSearch] = useState('')
  const [error, setError] = useState('')
  const [expandedId, setExpandedId] = useState(null)
  const [historyQ, setHistoryQ] = useState({ type: 'all', days: 7 })

  const load = () => {
    setLoading(true)
    getIncidents()
      .then(res => {
        const historyData = (res.data || []).filter(
          i => i.status === 'resolved' || i.status === 'cancelled'
        )
        setIncidents(historyData)
      })
      .catch(() => {
        setError('Failed to load history')
        toast.error('Failed to load history')
      })
      .finally(() => setLoading(false))
  }

  useEffect(load, [])

  const baseFiltered = incidents.filter(i => {
    if (historyQ.type !== 'all' && historyQ.type !== 'both') {
      if (historyQ.type === 'crime' && i.type !== 'crime') return false
      if (historyQ.type === 'medical' && i.type !== 'medical') return false
    }
    const daysAgo = new Date()
    daysAgo.setDate(daysAgo.getDate() - historyQ.days)
    if (new Date(i.createdAt) < daysAgo) return false

    return true
  })

  const filtered = baseFiltered.filter(i => {
    const matchStatus = filter === 'all' || i.status === filter
    const q = search.toLowerCase()
    const matchSearch = !q ||
      i.description?.toLowerCase().includes(q) ||
      i.type?.toLowerCase().includes(q) ||
      i.reporter?.name?.toLowerCase().includes(q) ||
      i.assignedResponder?.name?.toLowerCase().includes(q)
    return matchStatus && matchSearch
  })

  const resolvedCount = baseFiltered.filter(i => i.status === 'resolved').length
  const cancelledCount = baseFiltered.filter(i => i.status === 'cancelled').length

  // Type distribution among resolved/cancelled
  const typeCounts = {}
  baseFiltered.forEach(i => {
    const t = i.type || 'other'
    typeCounts[t] = (typeCounts[t] || 0) + 1
  })
  const typeChartData = Object.entries(typeCounts).map(([key, val]) => ({
    name: TYPE_LABELS[key]?.label || key,
    value: val,
    color: TYPE_LABELS[key]?.hex || '#888',
  }))

  // Resolution rate
  const resolutionRate = baseFiltered.length > 0
    ? Math.round((resolvedCount / baseFiltered.length) * 100)
    : 0

  const downloadCSV = () => {
    if (filtered.length === 0) { toast.error('No records to export'); return }
    const headers = ['Type', 'Description', 'Reporter', 'Responder', 'Status', 'Date Reported', 'Date Closed', 'Duration', 'Coordinates']
    const rows = filtered.map(inc => [
      inc.type,
      `"${(inc.description || '').replace(/"/g, '""')}"`,
      `"${inc.reporter?.name || 'Unknown'}"`,
      `"${inc.assignedResponder?.name || 'N/A'}"`,
      inc.status,
      new Date(inc.createdAt).toLocaleString(),
      new Date(inc.updatedAt).toLocaleString(),
      formatDuration(inc.createdAt, inc.updatedAt),
      inc.location?.coordinates ? `"${inc.location.coordinates[1]}, ${inc.location.coordinates[0]}"` : 'N/A',
    ])
    const csvContent = [headers.join(','), ...rows.map(r => r.join(','))].join('\n')
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' })
    const url = URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = url
    link.setAttribute('download', `safetrack_history_${new Date().toISOString().split('T')[0]}.csv`)
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
    toast.success('History report downloaded')
  }

  return (
    <motion.div
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.3 }}
    >
      <div className="page-header">
        <div>
          <h1 className="page-title">Incident History</h1>
          <p className="page-subtitle">View and analyze completed or cancelled incident records</p>
        </div>
        <div style={{ display: 'flex', gap: 10, alignItems: 'center' }}>
          <QueryBox onApply={setHistoryQ} />
          <div style={{ width: 1, height: 24, background: 'var(--border)', margin: '0 5px' }} />
          <button className="refresh-btn" onClick={downloadCSV} style={{ background: 'var(--bg-card)', border: '1px solid var(--border)' }}>
            <Download size={16} /> Export CSV
          </button>
          <button className="refresh-btn" onClick={load}>
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
              <polyline points="23 4 23 10 17 10"/><polyline points="1 20 1 14 7 14"/>
              <path d="M3.51 9a9 9 0 0114.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0020.49 15"/>
            </svg>
            Refresh
          </button>
        </div>
      </div>

      {error && <div className="dashboard-error" style={{ marginBottom: 20 }}>{error}</div>}

      {/* History Overview Cards */}
      <div className="history-overview-grid">
        <div className="history-stat-card history-resolved">
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 8 }}>
            <CheckCircle size={20} color="#22c55e" />
            <span className="history-stat-lbl">Resolved Cases</span>
          </div>
          <div className="history-stat-val text-green">{resolvedCount}</div>
          <div className="history-stat-sub">{resolutionRate}% resolution rate</div>
        </div>

        <div className="history-stat-card history-cancelled">
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 8 }}>
            <XCircle size={20} color="#ef4444" />
            <span className="history-stat-lbl">Cancelled Cases</span>
          </div>
          <div className="history-stat-val text-red">{cancelledCount}</div>
          <div className="history-stat-sub">{incidents.length - resolvedCount} not resolved</div>
        </div>

        <div className="history-stat-card">
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 8 }}>
            <Clock size={20} color="#4f6ef7" />
            <span className="history-stat-lbl">Total Completed</span>
          </div>
          <div className="history-stat-val text-primary">{baseFiltered.length}</div>
          <div className="history-stat-sub">Showing {filtered.length} filtered</div>
        </div>

        {/* Type Chart */}
        <div className="history-stat-card history-chart-mini">
          <div className="history-stat-lbl" style={{ marginBottom: 8 }}>By Type</div>
          <div style={{ height: 90 }}>
            {typeChartData.length > 0 ? (
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={typeChartData} margin={{ top: 0, right: 0, left: -36, bottom: 0 }}>
                  <XAxis dataKey="name" stroke="#5c6188" fontSize={9} tickLine={false} axisLine={false} />
                  <YAxis stroke="#5c6188" fontSize={9} tickLine={false} axisLine={false} allowDecimals={false} />
                  <Tooltip
                    contentStyle={{ background: '#13152a', border: '1px solid rgba(255,255,255,0.1)', borderRadius: '8px', fontSize: '11px' }}
                    labelStyle={{ color: '#fff' }}
                    itemStyle={{ color: '#94a3b8' }}
                  />
                  <Bar dataKey="value" radius={[3, 3, 0, 0]} maxBarSize={18}>
                    {typeChartData.map((entry, idx) => (
                      <Cell key={idx} fill={entry.color} />
                    ))}
                  </Bar>
                </BarChart>
              </ResponsiveContainer>
            ) : (
              <div className="empty-state" style={{ padding: 0, fontSize: 12 }}>No data</div>
            )}
          </div>
        </div>
      </div>

      {/* Filters */}
      <div className="incidents-filters" style={{ marginTop: 24 }}>
        <div className="filter-tabs">
          <button className={`filter-tab${filter === 'all' ? ' active' : ''}`} onClick={() => setFilter('all')}>
            All History ({baseFiltered.length})
          </button>
          <button className={`filter-tab${filter === 'resolved' ? ' active' : ''}`} onClick={() => setFilter('resolved')}>
            Resolved ({resolvedCount})
          </button>
          <button className={`filter-tab${filter === 'cancelled' ? ' active' : ''}`} onClick={() => setFilter('cancelled')}>
            Cancelled ({cancelledCount})
          </button>
        </div>
        <div className="search-wrap">
          <svg className="search-icon" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
            <circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
          </svg>
          <input
            className="search-input"
            placeholder="Search by type, reporter, responder..."
            value={search}
            onChange={e => setSearch(e.target.value)}
          />
        </div>
      </div>

      {/* Table */}
      <div className="dashboard-section">
        {loading ? (
          <div className="shimmer" style={{ height: 300, margin: 20, borderRadius: 12 }} />
        ) : filtered.length === 0 ? (
          <div className="empty-state">No historical incidents found matching your criteria.</div>
        ) : (
          <div className="incidents-table-wrap">
            <table className="incidents-table">
              <thead>
                <tr>
                  <th>Type</th>
                  <th>Description</th>
                  <th>Reporter</th>
                  <th>Responder</th>
                  <th>Status</th>
                  <th>Location</th>
                  <th>Date Reported</th>
                  <th>Duration</th>
                </tr>
              </thead>
              <tbody>
                {filtered.map(inc => {
                  const typeInfo = TYPE_LABELS[inc.type] || TYPE_LABELS.other
                  const coords = inc.location?.coordinates
                  const isExpanded = expandedId === inc._id

                  return (
                    <>
                      <tr
                        key={inc._id}
                        className={`history-row${isExpanded ? ' expanded' : ''}`}
                        onClick={() => setExpandedId(isExpanded ? null : inc._id)}
                        style={{ cursor: 'pointer' }}
                      >
                        <td><span className={`badge badge-${typeInfo.color}`}>{typeInfo.label}</span></td>
                        <td className="incident-desc" title={inc.description}>
                          {inc.description?.slice(0, 55) || '—'}{inc.description?.length > 55 ? '…' : ''}
                        </td>
                        <td className="incident-reporter">
                          <div style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                            <span style={{ display: 'flex', alignItems: 'center', gap: 5 }}>
                              <User size={11} style={{ opacity: 0.5 }} /> {inc.reporter?.name || 'Unknown'}
                            </span>
                            {inc.reporter?.phone && (
                              <span style={{ fontSize: '11px', color: 'var(--text-muted)' }}>{inc.reporter.phone}</span>
                            )}
                          </div>
                        </td>
                        <td>
                          {inc.assignedResponder ? (
                            <span style={{ display: 'flex', alignItems: 'center', gap: 5, color: 'var(--accent-green)', fontSize: 13 }}>
                              <div style={{ width: 7, height: 7, borderRadius: '50%', background: 'var(--accent-green)' }} />
                              {inc.assignedResponder.name}
                            </span>
                          ) : (
                            <span style={{ color: 'var(--text-muted)', fontSize: 12 }}>Unassigned</span>
                          )}
                        </td>
                        <td><span className={`badge badge-${STATUS_COLORS[inc.status]}`}>{inc.status}</span></td>
                        <td>
                          {coords ? (
                            <a
                              href={`https://maps.google.com/?q=${coords[1]},${coords[0]}`}
                              target="_blank"
                              rel="noopener noreferrer"
                              className="location-link"
                              onClick={e => e.stopPropagation()}
                            >
                              <MapPin size={11} />
                              {coords[1].toFixed(3)}, {coords[0].toFixed(3)}
                            </a>
                          ) : (
                            <span style={{ color: 'var(--text-muted)', fontSize: 12 }}>N/A</span>
                          )}
                        </td>
                        <td className="incident-time">
                          <div style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                            <span>{new Date(inc.createdAt).toLocaleDateString()}</span>
                            <span style={{ fontSize: '11px', color: 'var(--text-muted)' }}>
                              {new Date(inc.createdAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                            </span>
                          </div>
                        </td>
                        <td>
                          <span className="duration-badge">
                            <Clock size={11} /> {formatDuration(inc.createdAt, inc.updatedAt)}
                          </span>
                        </td>
                      </tr>
                      {isExpanded && (
                        <tr key={`${inc._id}-detail`} className="history-detail-row">
                          <td colSpan={8}>
                            <div className="history-detail-panel">
                              <div className="detail-section">
                                <span className="detail-label">Full Description</span>
                                <p className="detail-value">{inc.description || '—'}</p>
                              </div>
                              <div className="detail-section">
                                <span className="detail-label">Incident ID</span>
                                <p className="detail-value detail-mono">{inc._id}</p>
                              </div>
                              <div className="detail-section">
                                <span className="detail-label">Closed At</span>
                                <p className="detail-value">{new Date(inc.updatedAt).toLocaleString()}</p>
                              </div>
                              {inc.reporter?.email && (
                                <div className="detail-section">
                                  <span className="detail-label">Reporter Email</span>
                                  <p className="detail-value">{inc.reporter.email}</p>
                                </div>
                              )}
                              {coords && (
                                <div className="detail-section">
                                  <span className="detail-label">GPS Coordinates</span>
                                  <a
                                    href={`https://maps.google.com/?q=${coords[1]},${coords[0]}`}
                                    target="_blank"
                                    rel="noopener noreferrer"
                                    className="detail-value location-link"
                                  >
                                    <MapPin size={13} /> {coords[1]}, {coords[0]}
                                  </a>
                                </div>
                              )}
                            </div>
                          </td>
                        </tr>
                      )}
                    </>
                  )
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </motion.div>
  )
}
