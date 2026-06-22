import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { Toaster } from 'react-hot-toast'

// ─── Admin (regular) ─────────────────────────────────────────
import Login from './pages/Login'
import Dashboard from './pages/Dashboard'
import AdminProfile from './pages/AdminProfile'
import LiveMap from './pages/LiveMap'
import Incidents from './pages/Incidents'
import Responders from './pages/Responders'
import History from './pages/History'
import Notifications from './pages/Notifications'
import Settings from './pages/Settings'
import Layout from './components/Layout'
import { AuthProvider, useAuth } from './context/AuthContext'

// ─── Super Admin ──────────────────────────────────────────────
import { SuperAdminAuthProvider } from './context/SuperAdminAuthContext'
import SuperAdminLogin from './superadmin/SuperAdminLogin'
import SuperAdminLayout from './superadmin/SuperAdminLayout'
import SADashboard from './superadmin/SADashboard'
import SAAdmins from './superadmin/SAAdmins'
import SAIncidents from './superadmin/SAIncidents'
import SAResponders from './superadmin/SAResponders'
import SAAdminProfile from './superadmin/SAAdminProfile'
import SASettings from './superadmin/SASettings'

// ─── Guard for regular admin ──────────────────────────────────
function PrivateRoute({ children }) {
  const { token } = useAuth()
  return token ? children : <Navigate to="/login" replace />
}

function App() {
  return (
    <AuthProvider>
      <SuperAdminAuthProvider>
        <Toaster
          position="top-right"
          toastOptions={{
            style: { background: '#1e293b', color: '#fff', border: '1px solid #334155' }
          }}
        />
        <BrowserRouter>
          <Routes>
            {/* ── Regular Admin ── */}
            <Route path="/login" element={<Login />} />
            <Route
              path="/"
              element={
                <PrivateRoute>
                  <Layout />
                </PrivateRoute>
              }
            >
              <Route index element={<Navigate to="/dashboard" replace />} />
              <Route path="dashboard"     element={<Dashboard />} />
              <Route path="admin-profile" element={<AdminProfile />} />
              <Route path="live-map"      element={<LiveMap />} />
              <Route path="incidents"     element={<Incidents />} />
              <Route path="responders"    element={<Responders />} />
              <Route path="history"       element={<History />} />
              <Route path="notifications" element={<Notifications />} />
              <Route path="settings"      element={<Settings />} />
            </Route>

            {/* ── Super Admin ── /SuperAdmin = login, /SuperAdmin/* = dashboard ── */}
            <Route path="/SuperAdmin">
              <Route index element={<SuperAdminLogin />} />
              <Route element={<SuperAdminLayout />}>
                <Route path="dashboard"     element={<SADashboard />} />
                <Route path="admins"        element={<SAAdmins />} />
                <Route path="incidents"     element={<SAIncidents />} />
                <Route path="responders"    element={<SAResponders />} />
                <Route path="admin-profile" element={<SAAdminProfile />} />
                <Route path="settings"      element={<SASettings />} />
              </Route>
            </Route>

            {/* ── Catch-all ── */}
            <Route path="*" element={<Navigate to="/login" replace />} />
          </Routes>
        </BrowserRouter>
      </SuperAdminAuthProvider>
    </AuthProvider>
  )
}

export default App
