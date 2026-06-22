import './StatCard.css'

export default function StatCard({ label, value, color = 'blue', icon, headerAction }) {
  return (
    <div className={`stat-card stat-card-${color}`}>
      <div className="stat-card-header" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', width: '100%' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px', flex: 1 }}>
          <div className={`stat-card-icon stat-icon-${color}`}>{icon}</div>
          <span className="stat-card-label">{label}</span>
        </div>
        {headerAction && <div className="stat-card-action" style={{ zIndex: 10 }}>{headerAction}</div>}
      </div>
      <div className="stat-card-value">{value}</div>
    </div>
  )
}
