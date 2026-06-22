import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import Login from './pages/Login'
import Dashboard from './pages/Dashboard'
import Admins from './pages/Admins'
import Incidents from './pages/Incidents'
import Responders from './pages/Responders'
import Settings from './pages/Settings'
import AdminProfile from './pages/AdminProfile'
import { Toaster } from 'react-hot-toast'
import Layout from './components/Layout'
import { AuthProvider, useAuth } from './context/AuthContext'

function PrivateRoute({ children }) {
  const { token } = useAuth()
  return token ? children : <Navigate to="/login" replace />
}

function App() {
  return (
    <AuthProvider>
      <Toaster 
        position="top-right" 
        toastOptions={{
          style: { background: '#1e293b', color: '#fff', border: '1px solid #334155' }
        }} 
      />
      <BrowserRouter>
        <Routes>
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
            <Route path="dashboard" element={<Dashboard />} />
            <Route path="admins" element={<Admins />} />
            <Route path="incidents" element={<Incidents />} />
            <Route path="responders" element={<Responders />} />
            <Route path="settings" element={<Settings />} />
            <Route path="admin-profile" element={<AdminProfile />} />
          </Route>
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  )
}

export default App
