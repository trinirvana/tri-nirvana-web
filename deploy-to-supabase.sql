-- Tri Nirvana AI Platform - Complete Database Setup
-- Copy and paste this entire script into Supabase SQL Editor

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- User profiles table
CREATE TABLE IF NOT EXISTS profiles (
    id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    first_name TEXT,
    last_name TEXT,
    beta_tester BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Race distances table
CREATE TABLE IF NOT EXISTS race_distances (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    distance_km DECIMAL(10,2) NOT NULL,
    category TEXT NOT NULL, -- 'triathlon', 'running', 'cycling', 'swimming'
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Race predictions table
CREATE TABLE IF NOT EXISTS race_predictions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    race_distance_id UUID REFERENCES race_distances(id),
    predicted_time INTERVAL NOT NULL,
    swim_pace TEXT,
    bike_speed DECIMAL(5,2),
    run_pace TEXT,
    experience_level TEXT,
    environmental_factors JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Analytics events table
CREATE TABLE IF NOT EXISTS analytics_events (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    event_type TEXT NOT NULL,
    event_data JSONB,
    session_id TEXT,
    user_agent TEXT,
    ip_address INET,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Feedback submissions table
CREATE TABLE IF NOT EXISTS feedback_submissions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    feedback_text TEXT,
    page_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Certificates table
CREATE TABLE IF NOT EXISTS certificates (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    prediction_id UUID REFERENCES race_predictions(id) ON DELETE CASCADE,
    certificate_data JSONB NOT NULL,
    download_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert default race distances
INSERT INTO race_distances (name, distance_km, category, description) VALUES
-- Triathlon distances
('Sprint Triathlon', 25.75, 'triathlon', '750m swim, 20km bike, 5km run'),
('Olympic Triathlon', 51.5, 'triathlon', '1.5km swim, 40km bike, 10km run'),
('Half Ironman', 113, 'triathlon', '1.9km swim, 90km bike, 21.1km run'),
('Ironman', 226, 'triathlon', '3.8km swim, 180km bike, 42.2km run'),

-- Running distances
('5K Run', 5, 'running', '5 kilometer road race'),
('10K Run', 10, 'running', '10 kilometer road race'),
('Half Marathon', 21.1, 'running', '21.1 kilometer road race'),
('Marathon', 42.2, 'running', '42.2 kilometer road race'),

-- Cycling distances
('Time Trial 10K', 10, 'cycling', '10 kilometer time trial'),
('Time Trial 25K', 25, 'cycling', '25 kilometer time trial'),
('Century Ride', 100, 'cycling', '100 kilometer cycling challenge'),

-- Swimming distances
('1500m Swim', 1.5, 'swimming', '1500 meter open water swim'),
('3800m Swim', 3.8, 'swimming', '3800 meter open water swim')

ON CONFLICT (name) DO NOTHING;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_race_predictions_user_id ON race_predictions(user_id);
CREATE INDEX IF NOT EXISTS idx_race_predictions_created_at ON race_predictions(created_at);
CREATE INDEX IF NOT EXISTS idx_analytics_events_user_id ON analytics_events(user_id);
CREATE INDEX IF NOT EXISTS idx_analytics_events_created_at ON analytics_events(created_at);
CREATE INDEX IF NOT EXISTS idx_feedback_user_id ON feedback_submissions(user_id);
CREATE INDEX IF NOT EXISTS idx_certificates_user_id ON certificates(user_id);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for profiles table
DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;
CREATE TRIGGER update_profiles_updated_at 
    BEFORE UPDATE ON profiles 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE race_predictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE analytics_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE feedback_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE certificates ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist, then create new ones
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
DROP POLICY IF EXISTS "Users can view own predictions" ON race_predictions;
DROP POLICY IF EXISTS "Users can insert own predictions" ON race_predictions;
DROP POLICY IF EXISTS "Users can update own predictions" ON race_predictions;
DROP POLICY IF EXISTS "Users can view own analytics" ON analytics_events;
DROP POLICY IF EXISTS "Users can insert own analytics" ON analytics_events;
DROP POLICY IF EXISTS "Service role can insert analytics" ON analytics_events;
DROP POLICY IF EXISTS "Users can view own feedback" ON feedback_submissions;
DROP POLICY IF EXISTS "Users can insert feedback" ON feedback_submissions;
DROP POLICY IF EXISTS "Users can view own certificates" ON certificates;
DROP POLICY IF EXISTS "Users can insert own certificates" ON certificates;
DROP POLICY IF EXISTS "Users can update own certificates" ON certificates;

-- Profiles policies
CREATE POLICY "Users can view own profile" ON profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Race predictions policies
CREATE POLICY "Users can view own predictions" ON race_predictions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own predictions" ON race_predictions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own predictions" ON race_predictions
    FOR UPDATE USING (auth.uid() = user_id);

-- Analytics events policies
CREATE POLICY "Users can view own analytics" ON analytics_events
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own analytics" ON analytics_events
    FOR INSERT WITH CHECK (auth.uid() = user_id OR user_id IS NULL);

-- Service role can insert analytics for all users
CREATE POLICY "Service role can insert analytics" ON analytics_events
    FOR INSERT WITH CHECK (auth.jwt() ->> 'role' = 'service_role');

-- Feedback policies
CREATE POLICY "Users can view own feedback" ON feedback_submissions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert feedback" ON feedback_submissions
    FOR INSERT WITH CHECK (auth.uid() = user_id OR user_id IS NULL);

-- Certificates policies
CREATE POLICY "Users can view own certificates" ON certificates
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own certificates" ON certificates
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own certificates" ON certificates
    FOR UPDATE USING (auth.uid() = user_id);

-- Race distances are public (no RLS needed)
-- Everyone can read race distances
GRANT SELECT ON race_distances TO anon, authenticated;

-- Function to handle new user registration
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, beta_tester)
    VALUES (new.id, new.email, true);
    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for new user registration
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Verification queries (run these to confirm everything worked)
SELECT 'Tables created successfully' as status;
SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name;
SELECT COUNT(*) as race_distances_count FROM race_distances;