import { createClient } from '@supabase/supabase-js'

const SUPABASE_URL = 'https://fecxyreocrvscudavykt.supabase.co'
const SUPABASE_ANON_KEY = 'sb_publishable_oE07xyr5xibH7lh2WcfNPQ_mm-mGQdP'

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY)

export type User = {
  id: string
  email: string
  fullName: string
  role: 'admin' | 'user'
  isActive: boolean
  canWriteTestimonial: boolean
  createdAt: string
  updatedAt: string
}

export type Testimonial = {
  id: string
  userId: string
  name: string
  role: string
  location: string
  trip: string
  quote: string
  highlight: string
  rating: number
  isPublished: boolean
  createdAt: string
  updatedAt: string
}

export type Session = {
  user: {
    id: string
    email: string
  }
  access_token: string
  refresh_token: string
}
