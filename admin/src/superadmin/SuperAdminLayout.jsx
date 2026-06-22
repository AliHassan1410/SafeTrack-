import { Outlet, Navigate } from 'react-router-dom'
import { useSuperAdminAuth } from '../context/SuperAdminAuthContext'
import SuperAdminSidebar from './SuperAdminSidebar'
import '../components/Layout.css'

export default function SuperAdminLayout() {
  const { token } = useSuperAdminAuth()

  // If not authenticated as super admin, redirect to super admin login
  if (!token) {
    return <Navigate to="/SuperAdmin" replace />
  }

  return (
    <div className="layout">
      <SuperAdminSidebar />
      <main className="layout-main">
        <div className="layout-content fade-in">
          <Outlet />
        </div>
      </main>
    </div>
  )
}
