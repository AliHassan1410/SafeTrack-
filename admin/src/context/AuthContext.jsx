import { createContext, useContext, useState } from 'react'
import { api } from '../services/api'

const AuthContext = createContext(null)

export function AuthProvider({ children }) {
  const [token, setToken] = useState(() => localStorage.getItem('st_admin_token'))
  const [admin, setAdmin] = useState(() => {
    try {
      return JSON.parse(localStorage.getItem('st_admin_user')) || null
    } catch { return null }
  })
  const [loading, setLoading] = useState(false)




  const login = async (email, password) => {
    setLoading(true)
    try {
      const res = await api.post('/api/auth/login', { email, password, role: 'admin' })
      const { user } = res.data
      const tok = user.token
      setToken(tok)
      setAdmin(user)
      localStorage.setItem('st_admin_token', tok)
      localStorage.setItem('st_admin_user', JSON.stringify(user))
      return { success: true }
    } catch (err) {
      return { 
        success: false, 
        message: err.response?.data?.message || 'Login failed',
        isSuspended: err.response?.data?.isSuspended || false,
        suspendedByName: err.response?.data?.suspendedByName || null
      }
    } finally {
      setLoading(false)
    }
  }

  const logout = async () => {
    try {
      await api.post('/api/auth/logout')
    } catch (err) {
      console.error('Logout error:', err)
    }
    setToken(null)
    setAdmin(null)
    localStorage.removeItem('st_admin_token')
    localStorage.removeItem('st_admin_user')
  }

  const updateAdmin = (updatedUser) => {
    setAdmin(updatedUser)
    localStorage.setItem('st_admin_user', JSON.stringify(updatedUser))
  }

  return (
    <AuthContext.Provider value={{ token, admin, login, logout, loading, updateAdmin }}>
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  return useContext(AuthContext)
}
