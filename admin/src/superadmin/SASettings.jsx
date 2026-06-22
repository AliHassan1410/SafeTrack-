// Super Admin Settings — matches Settings.jsx layout exactly
import { useState } from 'react'
import { motion } from 'framer-motion'
import { Bell, Shield, Database, Globe, Crown } from 'lucide-react'
import toast from 'react-hot-toast'
import '../pages/Settings.css'

export default function SASettings() {
  const [activeTab, setActiveTab] = useState('general')
  const [settings, setSettings] = useState({
    timezone: 'UTC',
    language: 'en',
    emailAlerts: true,
    pushAlerts: true,
    smsAlerts: false,
    autoAssign: true,
    twoFactor: false,
  })

  const handleChange = (key, value) => {
    setSettings(prev => ({ ...prev, [key]: value }))
    toast.success('Setting saved automatically', { position: 'bottom-right' })
  }

  const renderContent = () => {
    switch (activeTab) {
      case 'general':
        return (
          <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }}>
            <h2 className="settings-section-title">General Settings</h2>
            <p className="settings-section-desc">Manage system-wide configuration and regional defaults across all zones.</p>

            <div className="settings-group">
              <div className="settings-group-title">System Defaults</div>

              <div className="setting-item">
                <div className="setting-info">
                  <h3 className="setting-name">Timezone</h3>
                  <p className="setting-desc">Set the primary timezone for timestamps across all admin dashboards.</p>
                </div>
                <div className="setting-action">
                  <select
                    className="setting-select"
                    value={settings.timezone}
                    onChange={(e) => handleChange('timezone', e.target.value)}
                  >
                    <option value="UTC">UTC (GMT+0)</option>
                    <option value="EST">Eastern Time (US)</option>
                    <option value="PST">Pacific Time (US)</option>
                    <option value="IST">India Standard Time</option>
                    <option value="PKT">Pakistan Standard Time</option>
                  </select>
                </div>
              </div>

              <div className="setting-item">
                <div className="setting-info">
                  <h3 className="setting-name">Language</h3>
                  <p className="setting-desc">Primary language for the super admin portal interface.</p>
                </div>
                <div className="setting-action">
                  <select
                    className="setting-select"
                    value={settings.language}
                    onChange={(e) => handleChange('language', e.target.value)}
                  >
                    <option value="en">English (US)</option>
                    <option value="es">Spanish</option>
                    <option value="fr">French</option>
                    <option value="ur">Urdu</option>
                  </select>
                </div>
              </div>
            </div>

            <div className="settings-group">
              <div className="settings-group-title">Dispatch</div>
              <div className="setting-item">
                <div className="setting-info">
                  <h3 className="setting-name">Auto-assign Responders</h3>
                  <p className="setting-desc">Automatically assign nearest available responders to high-priority incidents system-wide.</p>
                </div>
                <div className="setting-action">
                  <label className="toggle-switch">
                    <input
                      type="checkbox"
                      checked={settings.autoAssign}
                      onChange={(e) => handleChange('autoAssign', e.target.checked)}
                    />
                    <span className="toggle-slider"></span>
                  </label>
                </div>
              </div>
            </div>
          </motion.div>
        )

      case 'notifications':
        return (
          <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }}>
            <h2 className="settings-section-title">Notification Preferences</h2>
            <p className="settings-section-desc">Control how and when you receive system alerts across all admin levels.</p>

            <div className="settings-group">
              <div className="settings-group-title">Alert Channels</div>

              <div className="setting-item">
                <div className="setting-info">
                  <h3 className="setting-name">Email Alerts</h3>
                  <p className="setting-desc">Receive daily summaries and critical alerts via email.</p>
                </div>
                <div className="setting-action">
                  <label className="toggle-switch">
                    <input
                      type="checkbox"
                      checked={settings.emailAlerts}
                      onChange={(e) => handleChange('emailAlerts', e.target.checked)}
                    />
                    <span className="toggle-slider"></span>
                  </label>
                </div>
              </div>

              <div className="setting-item">
                <div className="setting-info">
                  <h3 className="setting-name">Push Notifications</h3>
                  <p className="setting-desc">Browser notifications for incoming critical incidents system-wide.</p>
                </div>
                <div className="setting-action">
                  <label className="toggle-switch">
                    <input
                      type="checkbox"
                      checked={settings.pushAlerts}
                      onChange={(e) => handleChange('pushAlerts', e.target.checked)}
                    />
                    <span className="toggle-slider"></span>
                  </label>
                </div>
              </div>

              <div className="setting-item">
                <div className="setting-info">
                  <h3 className="setting-name">SMS Alerts</h3>
                  <p className="setting-desc">Text messages for server downtime or catastrophic system-level emergencies.</p>
                </div>
                <div className="setting-action">
                  <label className="toggle-switch">
                    <input
                      type="checkbox"
                      checked={settings.smsAlerts}
                      onChange={(e) => handleChange('smsAlerts', e.target.checked)}
                    />
                    <span className="toggle-slider"></span>
                  </label>
                </div>
              </div>
            </div>
          </motion.div>
        )

      case 'security':
        return (
          <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }}>
            <h2 className="settings-section-title">Security &amp; Privacy</h2>
            <p className="settings-section-desc">Manage super admin account security and system-wide access control.</p>

            <div className="settings-group">
              <div className="settings-group-title">Authentication</div>

              <div className="setting-item">
                <div className="setting-info">
                  <h3 className="setting-name">Two-Factor Authentication (2FA)</h3>
                  <p className="setting-desc">Require an authenticator code when logging into the super admin portal.</p>
                </div>
                <div className="setting-action">
                  <label className="toggle-switch">
                    <input
                      type="checkbox"
                      checked={settings.twoFactor}
                      onChange={(e) => handleChange('twoFactor', e.target.checked)}
                    />
                    <span className="toggle-slider"></span>
                  </label>
                </div>
              </div>
            </div>

            <div className="settings-group">
              <div className="settings-group-title">Danger Zone</div>
              <div className="setting-item">
                <div className="setting-info">
                  <h3 className="setting-name">Force Logout All Sessions</h3>
                  <p className="setting-desc">Instantly revoke access to all active admin and super admin sessions globally.</p>
                </div>
                <div className="setting-action">
                  <button className="btn-danger" onClick={() => toast.success('All sessions terminated.')}>Revoke Sessions</button>
                </div>
              </div>
            </div>
          </motion.div>
        )

      case 'system':
        return (
          <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }}>
            <h2 className="settings-section-title">System Status</h2>
            <p className="settings-section-desc">Technical information about your SafeTrack installation and super admin scope.</p>

            <div className="settings-group">
              <div className="settings-group-title">Server Metrics</div>
              <div className="setting-item">
                <div className="setting-info">
                  <h3 className="setting-name">Backend API Version</h3>
                  <p className="setting-desc">v1.4.2 (Latest)</p>
                </div>
              </div>
              <div className="setting-item">
                <div className="setting-info">
                  <h3 className="setting-name">Database Connectivity</h3>
                  <p className="setting-desc" style={{ color: '#22c55e' }}>Connected (32ms latency)</p>
                </div>
              </div>
              <div className="setting-item">
                <div className="setting-info">
                  <h3 className="setting-name">Access Level</h3>
                  <p className="setting-desc" style={{ color: '#a78bfa' }}>👑 Highest — Full System Control (All Zones)</p>
                </div>
              </div>
            </div>
          </motion.div>
        )

      default:
        return null
    }
  }

  return (
    <motion.div
      className="settings-page"
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.3 }}
    >
      <div className="page-header">
        <div>
          <h1 className="page-title">Settings</h1>
          <p className="page-subtitle">Configure super admin behaviors and system-wide preferences</p>
        </div>
      </div>

      <div className="settings-grid">
        <nav className="settings-nav">
          <button
            className={`settings-nav-btn ${activeTab === 'general' ? 'active' : ''}`}
            onClick={() => setActiveTab('general')}
          >
            <Globe size={18} /> General
          </button>
          <button
            className={`settings-nav-btn ${activeTab === 'notifications' ? 'active' : ''}`}
            onClick={() => setActiveTab('notifications')}
          >
            <Bell size={18} /> Notifications
          </button>
          <button
            className={`settings-nav-btn ${activeTab === 'security' ? 'active' : ''}`}
            onClick={() => setActiveTab('security')}
          >
            <Shield size={18} /> Security
          </button>
          <button
            className={`settings-nav-btn ${activeTab === 'system' ? 'active' : ''}`}
            onClick={() => setActiveTab('system')}
          >
            <Database size={18} /> System
          </button>
        </nav>

        <div className="settings-content">
          {renderContent()}
        </div>
      </div>
    </motion.div>
  )
}
