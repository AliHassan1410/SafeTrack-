import { useEffect, useState } from 'react'
import { saGetStats, saGetAdmins, saGetIncidents, saGetResponders } from '../services/superAdminApi'
import { motion } from 'framer-motion'
import { Shield, MapPin, Users, Activity, AlertTriangle, RefreshCw } from 'lucide-react'
import { MapContainer, TileLayer, Marker, Popup, Circle } from 'react-leaflet'
import 'leaflet/dist/leaflet.css'
import L from 'leaflet'
import './SADashboard.css'
import QueryBox, { CHART_TYPE_OPTIONS } from '../components/QueryBox'
import StatCard from '../components/StatCard'
import {
  ResponsiveContainer, PieChart, Pie, Cell,
  LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend,
  AreaChart, Area
} from 'recharts'

delete L.Icon.Default.prototype._getIconUrl
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon-2x.png',
  iconUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-shadow.png',
})

const createIcon = (bg, label) => new L.DivIcon({
  className: '',
  html: `<div style="background:${bg};width:26px;height:26px;border-radius:50%;border:3px solid white;box-shadow:0 0 10px rgba(0,0,0,0.5);display:flex;align-items:center;justify-content:center;color:white;font-weight:bold;font-size:11px;">${label}</div>`,
  iconSize: [26, 26], iconAnchor: [13, 13],
})

// Custom icon creator for Admins with online status dot
const createAdminIcon = (isOnline) => new L.DivIcon({
  className: '',
  html: `
    <div style="position:relative;background:${isOnline ? '#4f6ef7' : '#6b7280'};width:28px;height:28px;border-radius:50%;border:3.5px solid white;box-shadow:0 0 12px rgba(0,0,0,0.5);display:flex;align-items:center;justify-content:center;color:white;font-weight:bold;font-size:12px;font-family:var(--font);">
      A
      <span style="position:absolute;bottom:-2px;right:-2px;width:9px;height:9px;border-radius:50%;background:${isOnline ? '#22c55e' : '#94a3b8'};border:1.5px solid white;"></span>
    </div>
  `,
  iconSize: [28, 28], iconAnchor: [14, 14],
})

const ICONS = {
  responder: createIcon('#10b981', 'R'),
  medical: createIcon('#3b82f6', 'M'),
  crime: createIcon('#ef4444', 'C'),
  other: createIcon('#6b7280', 'E'),
}

function getDistanceKm(lat1, lon1, lat2, lon2) {
  if (!lat1 || !lon1 || !lat2 || !lon2) return Infinity
  const R = 6371
  const dLat = (lat2 - lat1) * Math.PI / 180
  const dLon = (lon2 - lon1) * Math.PI / 180
  const a = Math.sin(dLat/2)**2 + Math.cos(lat1*Math.PI/180)*Math.cos(lat2*Math.PI/180)*Math.sin(dLon/2)**2
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
}

const isAdminOnline = (admin) => {
  if (!admin.lastActive) return false
  const diffMs = Date.now() - new Date(admin.lastActive).getTime()
  return diffMs < 60000 // Online if active in the last 60 seconds (regular frontend polls every 15s)
}

function buildTrendData(incidents, daysCount = 7) {
  const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
  const now = new Date()
  const dataMap = {}
  for (let i = daysCount - 1; i >= 0; i--) {
    const d = new Date()
    d.setDate(now.getDate() - i)
    const dateStr = d.toDateString()
    const label = daysCount <= 7
      ? days[d.getDay()]
      : d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
    dataMap[dateStr] = { day: label, crime: 0, medical: 0 }
  }
  incidents.forEach(inc => {
    const key = new Date(inc.createdAt).toDateString()
    if (dataMap[key]) {
      const t = (inc.type || '').toLowerCase()
      if (t === 'crime') dataMap[key].crime++
      if (t === 'medical') dataMap[key].medical++
    }
  })
  return Object.values(dataMap)
}

// Filter incidents by query {type, days}
function qi(list, q) {
  let r = list
  if (q?.days) {
    const lim = new Date()
    lim.setDate(lim.getDate() - q.days)
    r = r.filter(i => new Date(i.createdAt) >= lim)
  }
  const t = q?.type
  if (t && t !== 'all' && t !== 'both') {
    r = r.filter(i => (i.type || '').toLowerCase() === t)
  }
  return r
}

const TT = {
  contentStyle: { background: '#13152a', border: '1px solid rgba(255,255,255,0.1)', borderRadius: '10px', boxShadow: '0 8px 32px rgba(0,0,0,0.4)' },
  labelStyle: { color: '#e2e8f0', fontWeight: 600, marginBottom: 4 },
  itemStyle: { color: '#94a3b8' },
}

export default function SADashboard() {
  const [stats, setStats] = useState(null)
  const [admins, setAdmins] = useState([])
  const [incidents, setIncidents] = useState([])
  const [responders, setResponders] = useState([])
  const [loading, setLoading] = useState(true)
  const [refreshing, setRefreshing] = useState(false)
  const [error, setError] = useState('')

  // Per-statcard query states
  const [totalQ, setTotalQ] = useState({ type: 'all', days: 7 })
  const [pendingQ, setPendingQ] = useState({ type: 'all', days: 7 })
  const [activeQ, setActiveQ] = useState({ type: 'all', days: 7 })
  const [resolvedQ, setResolvedQ] = useState({ type: 'all', days: 7 })

  // Per-chart query states
  const [statusQ, setStatusQ] = useState({ type: 'all', days: 7 })
  const [workloadQ, setWorkloadQ] = useState({ type: 'all', days: 7 })
  const [trendQ, setTrendQ] = useState({ type: 'both', days: 7 })

  const fetchData = async () => {
    try {
      const [statsRes, adminsRes, incidentsRes, respondersRes] = await Promise.all([
        saGetStats(), saGetAdmins(), saGetIncidents(), saGetResponders()
      ])
      setStats(statsRes.data.stats)
      setAdmins(adminsRes.data.admins || [])
      setIncidents(incidentsRes.data || [])
      setResponders(respondersRes.data?.users || respondersRes.data || [])
      setError('')
    } catch (err) {
      setError('Failed to load data. Make sure the backend is running.')
    } finally {
      setLoading(false)
      setRefreshing(false)
    }
  }

  useEffect(() => {
    fetchData()
    const interval = setInterval(fetchData, 15000)
    return () => clearInterval(interval)
  }, [])

  const activeIncidentsForMap = incidents.filter(i =>
    i.location?.coordinates?.length === 2 &&
    !['resolved','cancelled','completed'].includes(i.status)
  )

  const adminsWithStats = admins.map(admin => {
    const lat = admin.coverageArea?.lat
    const lng = admin.coverageArea?.lng
    const radius = admin.coverageArea?.radius || 5
    const count = activeIncidentsForMap.filter(inc => {
      const [iLng, iLat] = inc.location.coordinates
      return getDistanceKm(lat, lng, iLat, iLng) <= radius
    }).length
    return { ...admin, activeIncidentsCount: count }
  })

  // Stat card computed values (client-side filtering matching regular admin dashboard)
  const totalVal = qi(incidents, totalQ).length
  const pendingVal = qi(incidents, pendingQ).filter(i => i.status === 'pending').length
  const activeVal = qi(incidents, activeQ).filter(i => ['active', 'in_progress', 'accepted'].includes(i.status)).length
  const resolvedVal = qi(incidents, resolvedQ).filter(i => i.status === 'resolved').length

  // Status doughnut data
  const statusInc = qi(incidents, statusQ)
  const statusData = [
    { name: 'Pending', value: statusInc.filter(i => i.status === 'pending').length, color: '#f59e0b' },
    { name: 'Active / In Progress', value: statusInc.filter(i => ['active', 'in_progress', 'accepted'].includes(i.status)).length, color: '#06b6d4' },
    { name: 'Resolved', value: statusInc.filter(i => i.status === 'resolved').length, color: '#22c55e' },
    { name: 'Cancelled', value: statusInc.filter(i => i.status === 'cancelled').length, color: '#ef4444' },
  ].filter(d => d.value > 0)

  // Trend line data
  const trendInc = qi(incidents, { days: trendQ.days })
  const weeklyData = buildTrendData(trendInc, trendQ.days)

  // Workload area data
  const workloadInc = qi(incidents, workloadQ)
  const workloadData = responders.length > 0
    ? responders.map(r => {
        const assigned = workloadInc.filter(i => i.assignedResponder?._id === r._id || i.assignedResponder === r._id)
        return { name: r.name ? r.name.split(' ')[0] : 'Unknown', assigned: assigned.length, resolved: assigned.filter(i => i.status === 'resolved').length }
      }).slice(0, 7)
    : [{ name: 'Police A', assigned: 4, resolved: 3 }, { name: 'Medic B', assigned: 5, resolved: 4 }, { name: 'Fire C', assigned: 2, resolved: 1 }]

  if (loading) return (
    <div className="sa-dashboard-loading shimmer">
      <h2>Loading Super Admin Dashboard...</h2>
    </div>
  )

  return (
    <motion.div className="sa-dashboard" initial={{ opacity:0, y:15 }} animate={{ opacity:1, y:0 }} transition={{ duration:0.4 }}>
      {/* Header */}
      <div className="sa-dash-header">
        <div>
          <h1 className="sa-dash-title">System Overview</h1>
          <p className="sa-dash-subtitle">Global monitoring across all emergency zones</p>
        </div>
        <button className={`sa-refresh-btn ${refreshing ? 'spinning' : ''}`} onClick={() => { setRefreshing(true); fetchData() }} disabled={refreshing}>
          <RefreshCw size={16} />
          {refreshing ? 'Refreshing...' : 'Refresh'}
        </button>
      </div>

      {error && <div className="sa-error-banner">{error}</div>}

      {/* Stats Grid — with individual Query filter boxes */}
      <div className="sa-stats-grid">
        <StatCard
          label="Total Incidents"
          value={totalVal}
          color="blue"
          icon={<AlertTriangle size={22}/>}
          headerAction={<QueryBox compact onApply={setTotalQ} />}
        />
        <StatCard
          label="Pending"
          value={pendingVal}
          color="amber"
          icon={<AlertTriangle size={22}/>}
          headerAction={<QueryBox compact onApply={setPendingQ} />}
        />
        <StatCard
          label="Active / In Progress"
          value={activeVal}
          color="red"
          icon={<Activity size={22}/>}
          headerAction={<QueryBox compact onApply={setActiveQ} />}
        />
        <StatCard
          label="Resolved"
          value={resolvedVal}
          color="green"
          icon={<Shield size={22}/>}
          headerAction={<QueryBox compact onApply={setResolvedQ} />}
        />
      </div>

      {/* Map */}
      <div className="sa-map-section">
        <h2 className="sa-section-title"><MapPin size={18}/>National Emergency Map</h2>
        <div className="sa-map-wrapper">
          <MapContainer center={[31.5204, 74.3587]} zoom={12} style={{ height:'480px', width:'100%' }}>
            <TileLayer
              url="https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png"
              attribution='&copy; OpenStreetMap contributors &copy; CARTO'
            />
            {admins.map(admin => {
              if (!admin.coverageArea?.lat) return null
              const online = isAdminOnline(admin)
              return (
                <div key={admin._id}>
                  <Circle center={[admin.coverageArea.lat, admin.coverageArea.lng]} radius={admin.coverageArea.radius*1000}
                    pathOptions={{ color: online ? '#4f6ef7' : '#94a3b8', fillColor: online ? '#4f6ef7' : '#94a3b8', fillOpacity:0.1, weight:1.5 }} />
                  <Marker position={[admin.coverageArea.lat, admin.coverageArea.lng]} icon={createAdminIcon(online)}>
                    <Popup>
                      <div className="sa-map-popup" style={{ color: '#1e293b' }}>
                        <strong style={{ fontSize: '13px', display: 'block', marginBottom: '2px' }}>{admin.name}</strong>
                        <span style={{
                          display: 'inline-block',
                          padding: '1px 5px',
                          borderRadius: '3px',
                          fontSize: '9px',
                          fontWeight: 'bold',
                          marginBottom: '6px',
                          background: online ? 'rgba(34,197,94,0.15)' : 'rgba(148,163,184,0.15)',
                          color: online ? '#22c55e' : '#64748b',
                          border: `1px solid ${online ? 'rgba(34,197,94,0.3)' : 'rgba(148,163,184,0.3)'}`
                        }}>
                          {online ? '● Online' : '○ Offline'}
                        </span>
                        <div style={{ fontSize: '11px', color: '#475569', lineHeight: '1.4' }}>
                          <p style={{ margin: '1px 0' }}>📧 {admin.email}</p>
                          <p style={{ margin: '1px 0' }}>📱 {admin.phone || 'No phone'}</p>
                          <p style={{ margin: '1px 0' }}>🏙️ City: {admin.city}</p>
                          <p style={{ margin: '1px 0' }}>📍 {admin.coverageArea.radius}km zone coverage</p>
                          <p style={{ margin: '3px 0 0 0', fontWeight: 'bold', color: admin.activeIncidentsCount > 0 ? '#ef4444' : '#22c55e' }}>
                            ⚠️ {admin.activeIncidentsCount} active incident(s) in zone
                          </p>
                        </div>
                      </div>
                    </Popup>
                  </Marker>
                </div>
              )
            })}
            {responders.map(r => r.currentLocation?.lat && (
              <Marker key={r._id} position={[r.currentLocation.lat, r.currentLocation.lng]} icon={ICONS.responder}>
                <Popup><div className="sa-map-popup"><strong>{r.name}</strong><p>{r.responderType}</p></div></Popup>
              </Marker>
            ))}
            {activeIncidentsForMap.map(inc => {
              const [lng, lat] = inc.location.coordinates
              return (
                <Marker key={inc._id} position={[lat, lng]} icon={ICONS[inc.type] || ICONS.other}>
                  <Popup><div className="sa-map-popup"><strong>{inc.title}</strong><p>{inc.type} · {inc.status}</p></div></Popup>
                </Marker>
              )
            })}
          </MapContainer>
        </div>
      </div>

      {/* 2-col Analytics Charts — System-wide analytics */}
      <div className="sa-charts-grid">
        {/* Doughnut — Incident Status */}
        <div className="sa-chart-card" style={{ overflow: 'visible' }}>
          <div className="sa-chart-header" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
            <div>
              <h2 className="sa-chart-title">Incident Status</h2>
              <p className="sa-chart-subtitle">Global breakdown of incident states</p>
            </div>
            <QueryBox onApply={setStatusQ} />
          </div>
          <div className="sa-chart-container">
            {statusData.length === 0 ? (
              <div className="empty-state" style={{ padding: 0 }}>No data for selected query</div>
            ) : (
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie data={statusData} cx="50%" cy="45%" innerRadius={55} outerRadius={75} paddingAngle={4} dataKey="value">
                    {statusData.map((e, i) => <Cell key={i} fill={e.color} />)}
                  </Pie>
                  <Tooltip {...TT} />
                  <Legend verticalAlign="bottom" iconType="circle" iconSize={8} formatter={v => <span style={{ color: '#8b92b8', fontSize: '11px' }}>{v}</span>} />
                </PieChart>
              </ResponsiveContainer>
            )}
          </div>
        </div>

        {/* Area — Responder Workload */}
        <div className="sa-chart-card" style={{ overflow: 'visible' }}>
          <div className="sa-chart-header" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
            <div>
              <h2 className="sa-chart-title">Responder Workload</h2>
              <p className="sa-chart-subtitle">Assigned vs resolved per responder</p>
            </div>
            <QueryBox showType={false} onApply={setWorkloadQ} />
          </div>
          <div className="sa-chart-container">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={workloadData} margin={{ top: 10, right: 10, left: -25, bottom: 0 }}>
                <defs>
                  <linearGradient id="saCA" x1="0" y1="0" x2="0" y2="1"><stop offset="5%" stopColor="#4f6ef7" stopOpacity={0.2}/><stop offset="95%" stopColor="#4f6ef7" stopOpacity={0}/></linearGradient>
                  <linearGradient id="saCR" x1="0" y1="0" x2="0" y2="1"><stop offset="5%" stopColor="#22c55e" stopOpacity={0.2}/><stop offset="95%" stopColor="#22c55e" stopOpacity={0}/></linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.03)" vertical={false} />
                <XAxis dataKey="name" stroke="#5c6188" fontSize={11} tickLine={false} axisLine={false} />
                <YAxis stroke="#5c6188" fontSize={11} tickLine={false} axisLine={false} allowDecimals={false} />
                <Tooltip {...TT} />
                <Legend verticalAlign="top" height={28} iconType="circle" iconSize={8} formatter={v => <span style={{ color: '#8b92b8', fontSize: '11px' }}>{v.charAt(0).toUpperCase() + v.slice(1)}</span>} />
                <Area type="monotone" dataKey="assigned" stroke="#4f6ef7" strokeWidth={2} fillOpacity={1} fill="url(#saCA)" />
                <Area type="monotone" dataKey="resolved" stroke="#22c55e" strokeWidth={2} fillOpacity={1} fill="url(#saCR)" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>

      {/* Full-width Trend Chart */}
      <div className="sa-chart-card sa-dashboard-weekly-chart" style={{ overflow: 'visible' }}>
        <div className="sa-chart-header" style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between' }}>
          <div>
            <h2 className="sa-chart-title">{trendQ.days === 7 ? 'Weekly' : `${trendQ.days}-Day`} Incident Trend</h2>
            <p className="sa-chart-subtitle">System-wide Crime vs Medical emergency reports</p>
          </div>
          <div style={{ display: 'flex', gap: 10, alignItems: 'center' }}>
            {(trendQ.type === 'both' || trendQ.type === 'crime') && <span className="sa-legend-chip crime">● Crime</span>}
            {(trendQ.type === 'both' || trendQ.type === 'medical') && <span className="sa-legend-chip medical">● Medical</span>}
            <QueryBox typeOptions={CHART_TYPE_OPTIONS} initialType="both" onApply={setTrendQ} />
          </div>
        </div>
        <div style={{ height: 260 }}>
          <ResponsiveContainer width="100%" height="100%">
            <LineChart data={weeklyData} margin={{ top: 10, right: 24, left: -20, bottom: 0 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.04)" vertical={false} />
              <XAxis dataKey="day" stroke="#5c6188" fontSize={12} tickLine={false} axisLine={false} />
              <YAxis stroke="#5c6188" fontSize={12} tickLine={false} axisLine={false} allowDecimals={false} />
              <Tooltip {...TT} />
              {(trendQ.type === 'both' || trendQ.type === 'crime') && (
                <Line type="monotone" dataKey="crime" name="Crime" stroke="#ef4444" strokeWidth={2.5} dot={{ fill: '#ef4444', r: 4, strokeWidth: 0 }} activeDot={{ r: 6, fill: '#ef4444', stroke: 'rgba(239,68,68,0.3)', strokeWidth: 4 }} />
              )}
              {(trendQ.type === 'both' || trendQ.type === 'medical') && (
                <Line type="monotone" dataKey="medical" name="Medical" stroke="#4f6ef7" strokeWidth={2.5} dot={{ fill: '#4f6ef7', r: 4, strokeWidth: 0 }} activeDot={{ r: 6, fill: '#4f6ef7', stroke: 'rgba(79,110,247,0.3)', strokeWidth: 4 }} />
              )}
            </LineChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Admin Table */}
      <div className="sa-table-section">
        <h2 className="sa-section-title"><Shield size={18}/>Low-Level Admin Directory</h2>
        <div className="sa-table-wrapper">
          <table className="sa-table">
            <thead>
              <tr>
                <th>Admin Name</th>
                <th>Contact</th>
                <th>City</th>
                <th>Coverage</th>
                <th>Active Incidents</th>
              </tr>
            </thead>
            <tbody>
              {adminsWithStats.length === 0 ? (
                <tr><td colSpan="5" className="sa-table-empty">No admins registered. Go to Manage Admins to create one.</td></tr>
              ) : adminsWithStats.map(admin => {
                const online = isAdminOnline(admin)
                return (
                  <tr key={admin._id} className={admin.isSuspended ? 'sa-row-suspended' : ''}>
                    <td>
                      <div className="sa-admin-cell">
                        <span className={`sa-admin-avatar ${admin.isSuspended ? 'sa-avatar-suspended' : ''}`}>{admin.name[0]}</span>
                        <div>
                          <div className="sa-admin-name">
                            {admin.name}
                            <span className={`sa-online-dot ${online ? 'online' : 'offline'}`} title={online ? 'Online' : 'Offline'} />
                          </div>
                          <div className="sa-admin-sub">
                            {admin.isSuspended
                              ? <span className="sa-suspended-tag">⛔ Suspended</span>
                              : <span className="sa-admin-id">ID: ...{admin._id.slice(-6)}</span>
                            }
                          </div>
                        </div>
                      </div>
                    </td>
                    <td>
                      <div className="sa-contact-cell">
                        <div>{admin.email}</div>
                        <div className="sa-contact-sub">{admin.phone || 'No phone'}</div>
                      </div>
                    </td>
                    <td><span className="sa-city-badge">{admin.city}</span></td>
                    <td className="sa-coords">{admin.coverageArea?.lat?.toFixed(4)}, {admin.coverageArea?.lng?.toFixed(4)} · {admin.coverageArea?.radius||5}km</td>
                    <td>
                      <span className={`sa-incident-badge ${admin.activeIncidentsCount > 0 ? 'alert' : 'clear'}`}>
                        {admin.activeIncidentsCount} active
                      </span>
                    </td>
                  </tr>
                )
              })}
            </tbody>
          </table>
        </div>
      </div>
    </motion.div>
  )
}
