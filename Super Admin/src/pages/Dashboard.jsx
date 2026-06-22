import { useEffect, useState } from 'react'
import { getSuperAdminStats, getAdmins, getIncidents, getResponders } from '../services/api'
import { motion } from 'framer-motion'
import { Shield, MapPin, Users, Activity, AlertTriangle, CheckCircle, RefreshCw } from 'lucide-react'
import { MapContainer, TileLayer, Marker, Popup, Circle } from 'react-leaflet'
import 'leaflet/dist/leaflet.css'
import L from 'leaflet'
import './Dashboard.css'

// Fix Leaflet marker icons in Vite
delete L.Icon.Default.prototype._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon-2x.png',
  iconUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-shadow.png',
});

// Custom markers
const createCustomIcon = (bgColor, labelChar) => {
  return new L.DivIcon({
    className: 'custom-leaflet-marker',
    html: `<div style="background-color: ${bgColor}; width: 26px; height: 26px; border-radius: 50%; border: 3px solid white; box-shadow: 0 0 10px rgba(0,0,0,0.5); display: flex; align-items: center; justify-content: center; color: white; font-weight: bold; font-size: 11px;">${labelChar}</div>`,
    iconSize: [26, 26],
    iconAnchor: [13, 13],
  })
}

const ICONS = {
  admin: createCustomIcon('#4f6ef7', 'A'),
  responder: createCustomIcon('#10b981', 'R'),
  medical: createCustomIcon('#3b82f6', 'M'),
  crime: createCustomIcon('#ef4444', 'C'),
  fire: createCustomIcon('#f59e0b', 'F'),
  accident: createCustomIcon('#8b5cf6', 'Ac'),
  other: createCustomIcon('#6b7280', 'E'),
}

// Haversine formula to compute distance in km
function getDistanceKm(lat1, lon1, lat2, lon2) {
  if (!lat1 || !lon1 || !lat2 || !lon2) return Infinity;
  const R = 6371; // Earth radius in km
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a = 
    Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * 
    Math.sin(dLon/2) * Math.sin(dLon/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  return R * c;
}

export default function Dashboard() {
  const [stats, setStats] = useState(null)
  const [admins, setAdmins] = useState([])
  const [incidents, setIncidents] = useState([])
  const [responders, setResponders] = useState([])
  const [loading, setLoading] = useState(true)
  const [refreshing, setRefreshing] = useState(false)
  const [error, setError] = useState('')

  const fetchData = async () => {
    try {
      const [statsRes, adminsRes, incidentsRes, respondersRes] = await Promise.all([
        getSuperAdminStats(),
        getAdmins(),
        getIncidents(),
        getResponders()
      ])

      setStats(statsRes.data.stats)
      setAdmins(adminsRes.data.admins || [])
      setIncidents(incidentsRes.data || [])
      setResponders(respondersRes.data.users || respondersRes.data || [])
      setError('')
    } catch (err) {
      console.error(err)
      setError('Failed to load system data. Make sure the backend is running.')
    } finally {
      setLoading(false)
      setRefreshing(false)
    }
  }

  useEffect(() => {
    fetchData()
    // Poll every 10 seconds for real-time updates
    const interval = setInterval(fetchData, 10000)
    return () => clearInterval(interval)
  }, [])

  const handleRefresh = () => {
    setRefreshing(true)
    fetchData()
  }

  // Filter out resolved or cancelled incidents for active tracking
  const activeIncidentsList = incidents.filter(i => 
    i.location && 
    i.location.coordinates && 
    i.location.coordinates.length === 2 &&
    !['resolved', 'cancelled', 'completed'].includes(i.status)
  )

  // Calculate stats for each admin
  const adminsWithStats = admins.map(admin => {
    const adminLat = admin.coverageArea?.lat;
    const adminLng = admin.coverageArea?.lng;
    const radius = admin.coverageArea?.radius || 5;

    // Filter active incidents falling in this admin's zone
    const activeInZone = activeIncidentsList.filter(inc => {
      const incLng = inc.location.coordinates[0];
      const incLat = inc.location.coordinates[1];
      const distance = getDistanceKm(adminLat, adminLng, incLat, incLng);
      return distance <= radius;
    });

    return {
      ...admin,
      activeIncidentsCount: activeInZone.length
    }
  })

  if (loading) {
    return (
      <div className="dashboard-loading shimmer">
        <h2>Loading Super Admin Dashboard...</h2>
      </div>
    )
  }

  const defaultCenter = [31.5204, 74.3587] // Lahore center

  return (
    <motion.div 
      className="dashboard-container"
      initial={{ opacity: 0, y: 15 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.4 }}
    >
      <div className="dashboard-header">
        <div>
          <h1 className="dashboard-title">System Overview</h1>
          <p className="dashboard-subtitle">Global monitoring of emergency zones and low-level admins</p>
        </div>
        <button 
          className={`refresh-btn ${refreshing ? 'spinning' : ''}`}
          onClick={handleLogout => handleRefresh()}
          disabled={refreshing}
        >
          <RefreshCw size={18} />
          {refreshing ? 'Refreshing...' : 'Refresh Data'}
        </button>
      </div>

      {error && <div className="error-banner">{error}</div>}

      {/* Stats Grid */}
      <div className="stats-grid">
        <div className="stat-card blue-glow">
          <div className="stat-icon-wrap bg-blue-trans">
            <Shield size={24} className="color-blue" />
          </div>
          <div className="stat-details">
            <span className="stat-label">Active Admins</span>
            <span className="stat-value">{stats?.totalAdmins || admins.length}</span>
          </div>
        </div>

        <div className="stat-card amber-glow">
          <div className="stat-icon-wrap bg-amber-trans">
            <AlertTriangle size={24} className="color-amber" />
          </div>
          <div className="stat-details">
            <span className="stat-label">Pending Incidents</span>
            <span className="stat-value">{stats?.pendingIncidents || 0}</span>
          </div>
        </div>

        <div className="stat-card red-glow">
          <div className="stat-icon-wrap bg-red-trans">
            <Activity size={24} className="color-red" />
          </div>
          <div className="stat-details">
            <span className="stat-label">Active Incidents</span>
            <span className="stat-value">{stats?.activeIncidents || 0}</span>
          </div>
        </div>

        <div className="stat-card green-glow">
          <div className="stat-icon-wrap bg-green-trans">
            <Users size={24} className="color-green" />
          </div>
          <div className="stat-details">
            <span className="stat-label font-bold">Total Responders</span>
            <span className="stat-value">{stats?.totalResponders || responders.length}</span>
          </div>
        </div>
      </div>

      {/* Main Map View */}
      <div className="dashboard-map-section">
        <h2 className="section-heading"><MapPin size={20} /> National Emergency Map (Lahore)</h2>
        <div className="dashboard-map-wrapper">
          <MapContainer 
            center={defaultCenter} 
            zoom={12} 
            style={{ height: '500px', width: '100%', borderRadius: '16px', zIndex: 0 }}
          >
            <TileLayer
              url="https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png"
              attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a>'
            />

            {/* Admin zones & markers */}
            {admins.map(admin => {
              if (admin.coverageArea?.lat && admin.coverageArea?.lng) {
                return (
                  <div key={admin._id}>
                    {/* 5 km circular range visualizer */}
                    <Circle
                      center={[admin.coverageArea.lat, admin.coverageArea.lng]}
                      radius={admin.coverageArea.radius * 1000}
                      pathOptions={{ color: '#4f6ef7', fillColor: '#4f6ef7', fillOpacity: 0.15, weight: 1.5 }}
                    />
                    <Marker 
                      position={[admin.coverageArea.lat, admin.coverageArea.lng]}
                      icon={ICONS.admin}
                    >
                      <Popup>
                        <div className="map-popup">
                          <h3>{admin.name}</h3>
                          <p><strong>Email:</strong> {admin.email}</p>
                          <p><strong>City:</strong> {admin.city}</p>
                          <p><strong>Coverage Radius:</strong> {admin.coverageArea.radius} km</p>
                        </div>
                      </Popup>
                    </Marker>
                  </div>
                )
              }
              return null
            })}

            {/* Active Responders */}
            {responders.map(resp => {
              if (resp.currentLocation?.lat && resp.currentLocation?.lng) {
                return (
                  <Marker 
                    key={resp._id}
                    position={[resp.currentLocation.lat, resp.currentLocation.lng]}
                    icon={ICONS.responder}
                  >
                    <Popup>
                      <div className="map-popup">
                        <h3>{resp.name}</h3>
                        <p><strong>Role:</strong> Responder ({resp.responderType})</p>
                        <p><strong>Phone:</strong> {resp.phone}</p>
                      </div>
                    </Popup>
                  </Marker>
                )
              }
              return null
            })}

            {/* Active Incidents */}
            {activeIncidentsList.map(inc => {
              const [lng, lat] = inc.location.coordinates;
              const typeIcon = ICONS[inc.type] || ICONS.other;

              return (
                <Marker 
                  key={inc._id}
                  position={[lat, lng]}
                  icon={typeIcon}
                >
                  <Popup>
                    <div className="map-popup">
                      <h3>{inc.title}</h3>
                      <p><strong>Type:</strong> {inc.type.toUpperCase()}</p>
                      <p><strong>Status:</strong> {inc.status.toUpperCase()}</p>
                      <p><strong>Details:</strong> {inc.description}</p>
                    </div>
                  </Popup>
                </Marker>
              )
            })}
          </MapContainer>
        </div>
      </div>

      {/* Admin Monitoring Grid */}
      <div className="admins-summary-section">
        <h2 className="section-heading"><Shield size={20} /> Low-Level Admin Performance Directory</h2>
        <div className="admins-table-wrapper">
          <table className="admins-table">
            <thead>
              <tr>
                <th>Admin Name</th>
                <th>Email / Contact</th>
                <th>Covered City</th>
                <th>Coverage Coordinates</th>
                <th>Coverage Radius</th>
                <th>Active Incidents in Zone</th>
              </tr>
            </thead>
            <tbody>
              {adminsWithStats.length === 0 ? (
                <tr>
                  <td colSpan="6" style={{ textAlign: 'center', padding: '24px', color: 'var(--text-muted)' }}>
                    No low-level admins registered. Go to "Manage Admins" to create one.
                  </td>
                </tr>
              ) : (
                adminsWithStats.map(admin => (
                  <tr key={admin._id}>
                    <td>
                      <div className="admin-td-name">
                        <span className="admin-avatar bg-blue-trans">{admin.name[0]}</span>
                        <div>
                          <div className="admin-name-text">{admin.name}</div>
                          <span className="admin-id-sub">ID: ...{admin._id.slice(-6)}</span>
                        </div>
                      </div>
                    </td>
                    <td>
                      <div className="admin-td-contact">
                        <div>{admin.email}</div>
                        <div className="admin-phone-sub">{admin.phone || 'No phone'}</div>
                      </div>
                    </td>
                    <td><span className="badge badge-city">{admin.city}</span></td>
                    <td>
                      <span className="coords-text">
                        {admin.coverageArea?.lat?.toFixed(4)}, {admin.coverageArea?.lng?.toFixed(4)}
                      </span>
                    </td>
                    <td>{admin.coverageArea?.radius || 5} km</td>
                    <td>
                      <span className={`badge-active-count ${admin.activeIncidentsCount > 0 ? 'alert' : 'clear'}`}>
                        {admin.activeIncidentsCount} active emergencies
                      </span>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </motion.div>
  )
}
