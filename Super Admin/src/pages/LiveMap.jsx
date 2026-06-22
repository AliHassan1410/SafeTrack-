import { useEffect, useState } from 'react'
import { MapContainer, TileLayer, Marker, Popup } from 'react-leaflet'
import 'leaflet/dist/leaflet.css'
import L from 'leaflet'
import { getIncidents } from '../services/api'
import { motion } from 'framer-motion'
import { MapPin, Activity } from 'lucide-react'
import './LiveMap.css'

// Fix Leaflet's default icon path issues in Vite
delete L.Icon.Default.prototype._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon-2x.png',
  iconUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-shadow.png',
});

// Custom icons based on status
const createCustomIcon = (color) => {
  return new L.DivIcon({
    className: 'custom-leaflet-icon',
    html: `<div style="background-color: ${color}; width: 24px; height: 24px; border-radius: 50%; border: 3px solid white; box-shadow: 0 0 10px rgba(0,0,0,0.5);"></div>`,
    iconSize: [24, 24],
    iconAnchor: [12, 12],
  })
}

const ICONS = {
  medical: createCustomIcon('#3b82f6'),
  crime: createCustomIcon('#ef4444'),
  fire: createCustomIcon('#f59e0b'),
  accident: createCustomIcon('#8b5cf6'),
  other: createCustomIcon('#10b981'),
}

export default function LiveMap() {
  const [incidents, setIncidents] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    getIncidents().then(res => {
      // Filter out incidents without valid coordinates
      const valid = res.data.filter(i => 
        i.location && 
        i.location.coordinates && 
        i.location.coordinates.length === 2 &&
        i.status !== 'resolved' && 
        i.status !== 'cancelled'
      )
      setIncidents(valid)
      setLoading(false)
    }).catch(err => {
      console.error(err)
      setLoading(false)
    })
  }, [])

  // Default center (e.g., center of your primary city). 
  // If we have incidents, center on the first one.
  const center = incidents.length > 0 
    ? [incidents[0].location.coordinates[1], incidents[0].location.coordinates[0]]
    : [31.5204, 74.3587] // Default coordinates (Lahore, Pakistan, commonly used in tutorials, or you can use your own)

  return (
    <motion.div 
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.4 }}
      className="live-map-page"
    >
      <div className="page-header">
        <div>
          <h1 className="page-title" style={{display:'flex', alignItems:'center', gap:10}}>
            <MapPin size={28} /> Live Incident Map
          </h1>
          <p className="page-subtitle">Real-time geographical tracking of active emergencies</p>
        </div>
        <div className="map-stats">
          <div className="stat-badge">
            <Activity size={16} className="pulse-icon" color="#10b981" />
            {incidents.length} Active Events
          </div>
        </div>
      </div>

      <div className="map-container-wrapper">
        {loading ? (
          <div className="shimmer map-loading">Loading Map Data...</div>
        ) : (
          <MapContainer 
            center={center} 
            zoom={12} 
            style={{ height: '100%', width: '100%', borderRadius: '16px', zIndex: 0 }}
            theme="dark"
          >
            {/* Dark themed tile layer for professional aesthetic */}
            <TileLayer
              url="https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png"
              attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a>'
            />
            
            {incidents.map(inc => (
              <Marker 
                key={inc._id} 
                position={[inc.location.coordinates[1], inc.location.coordinates[0]]}
                icon={ICONS[inc.type] || ICONS.other}
              >
                <Popup className="dark-popup">
                  <div className="popup-content">
                    <span className={`badge badge-${inc.type === 'crime' ? 'red' : 'blue'}`}>{inc.type.toUpperCase()}</span>
                    <h4>{inc.description?.slice(0, 50) || 'Emergency Incident'}</h4>
                    <p><strong>Reporter:</strong> {inc.reporter?.name || 'Unknown'}</p>
                    <p><strong>Status:</strong> {inc.status}</p>
                  </div>
                </Popup>
              </Marker>
            ))}
          </MapContainer>
        )}
      </div>
    </motion.div>
  )
}
