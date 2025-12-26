-- Create users table
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  fullName TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('admin', 'user')) DEFAULT 'user',
  isActive BOOLEAN NOT NULL DEFAULT true,
  canWriteTestimonial BOOLEAN NOT NULL DEFAULT false,
  createdAt TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updatedAt TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create testimonials table
CREATE TABLE testimonials (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  userId UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  role TEXT NOT NULL,
  location TEXT NOT NULL,
  trip TEXT NOT NULL,
  quote TEXT NOT NULL,
  highlight TEXT NOT NULL,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  isPublished BOOLEAN NOT NULL DEFAULT false,
  createdAt TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updatedAt TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create indexes for better performance
CREATE INDEX idx_testimonials_userId ON testimonials(userId);
CREATE INDEX idx_testimonials_isPublished ON testimonials(isPublished);
CREATE INDEX idx_users_role ON users(role);

-- Enable Row Level Security (RLS)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE testimonials ENABLE ROW LEVEL SECURITY;

-- RLS Policies for users table
-- Users can view their own profile
CREATE POLICY "Users can view own profile" ON users
  FOR SELECT USING (auth.uid() = id);

-- Admin can view all users
CREATE POLICY "Admin can view all users" ON users
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Users can update their own profile (except role and canWriteTestimonial)
CREATE POLICY "Users can update own profile" ON users
  FOR UPDATE USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id AND role = OLD.role AND canWriteTestimonial = OLD.canWriteTestimonial);

-- Admin can update any user
CREATE POLICY "Admin can update users" ON users
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Admin can delete users
CREATE POLICY "Admin can delete users" ON users
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- RLS Policies for testimonials table
-- Users can view published testimonials
CREATE POLICY "Anyone can view published testimonials" ON testimonials
  FOR SELECT USING (isPublished = true);

-- Users can view their own testimonials
CREATE POLICY "Users can view own testimonials" ON testimonials
  FOR SELECT USING (userId = auth.uid());

-- Admin can view all testimonials
CREATE POLICY "Admin can view all testimonials" ON testimonials
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Users can insert testimonials only if canWriteTestimonial is true
CREATE POLICY "Users can write testimonials if allowed" ON testimonials
  FOR INSERT WITH CHECK (
    userId = auth.uid() AND
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() AND canWriteTestimonial = true AND isActive = true
    )
  );

-- Users can update their own testimonials
CREATE POLICY "Users can update own testimonials" ON testimonials
  FOR UPDATE USING (userId = auth.uid())
  WITH CHECK (userId = auth.uid());

-- Admin can update any testimonial
CREATE POLICY "Admin can update testimonials" ON testimonials
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Admin can delete testimonials
CREATE POLICY "Admin can delete testimonials" ON testimonials
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Create a trigger to update updatedAt timestamp
CREATE OR REPLACE FUNCTION update_updatedAt_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updatedAt = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER users_update_timestamp BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updatedAt_timestamp();

CREATE TRIGGER testimonials_update_timestamp BEFORE UPDATE ON testimonials
  FOR EACH ROW EXECUTE FUNCTION update_updatedAt_timestamp();

-- Create admin user (replace email and password)
-- Note: You need to create this manually in Supabase Auth first, then run this
INSERT INTO users (id, email, fullName, role, isActive, canWriteTestimonial)
SELECT auth.users.id, auth.users.email, 'Admin User', 'admin', true, true
FROM auth.users
WHERE email = 'admin@storiesbyfoot.com' AND NOT EXISTS (
  SELECT 1 FROM users WHERE id = auth.users.id
);
