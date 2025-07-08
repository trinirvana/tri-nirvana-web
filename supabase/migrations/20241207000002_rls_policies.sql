-- Tri Nirvana AI Platform - Row Level Security Policies

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE race_predictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE analytics_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE feedback_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE certificates ENABLE ROW LEVEL SECURITY;

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