import { useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '@/context/AuthContext'

/**
 * Hook that automatically redirects users to their dashboard after login
 * Should be used on pages where unauthenticated users land (like home page)
 */
export function useAuthRedirect() {
  const navigate = useNavigate()
  const { user, isAdmin, isLoading, isAuthenticated } = useAuth()

  useEffect(() => {
    // Don't redirect while auth is still loading
    if (isLoading) return

    // If user is authenticated, redirect to their dashboard
    // If user profile loaded, use role to determine dashboard
    // Otherwise, redirect to user dashboard (default for any authenticated user)
    if (isAuthenticated) {
      if (user && isAdmin) {
        console.log('[useAuthRedirect] Redirecting admin to admin dashboard')
        navigate('/admin-dashboard', { replace: true })
      } else if (isAuthenticated) {
        // Either user profile loaded (user exists) or session exists but profile pending
        // Either way, redirect to appropriate dashboard
        console.log('[useAuthRedirect] Redirecting authenticated user to user dashboard')
        navigate('/user-dashboard', { replace: true })
      }
    }
  }, [user, isAdmin, isLoading, isAuthenticated, navigate])
}
