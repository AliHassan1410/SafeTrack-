import { createContext, useContext, useState, useEffect } from 'react'
import { api } from '../services/api'

const AuthContext = createContext(null)

export function AuthProvider({ children }) {
  const [token, setToken] = useState(() => localStorage.getItem('st_superadmin_token'))
  const [admin, setAdmin] = useState(() => {
    try {
      return JSON.parse(localStorage.getItem('st_superadmin_user')) || null
    } catch { return null }
  })
  const [loading, setLoading] = useState(false)

  const login = async (email, password) => {
    setLoading(true)
    try {
      const res = await api.post('/api/auth/login', { email, password, role: 'superadmin' })
      const { user } = res.data
      const tok = user.token
      setToken(tok)
      setAdmin(user)
      localStorage.setItem('st_superadmin_token', tok)
      localStorage.setItem('st_superadmin_user', JSON.stringify(user))
      return { success: true }
    } catch (err) {
      return { success: false, message: err.response?.data?.message || 'Login failed' }
    } finally {
      setLoading(false)
    }
  }

  const logout = () => {
    setToken(null)
    setAdmin(null)
    localStorage.removeItem('st_superadmin_token')
    localStorage.removeItem('st_superadmin_user')
  }

  const updateAdmin = (updatedUser) => {
    setAdmin(updatedUser)
    localStorage.setItem('st_superadmin_user', JSON.stringify(updatedUser))
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
