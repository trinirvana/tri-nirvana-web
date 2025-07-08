# 🚀 Supabase Deployment Guide - Tri Nirvana AI Platform

## Phase 2: Complete Supabase Setup

Your Supabase project credentials have been configured. Now you need to deploy the database schema and Edge Functions.

### Step 1: Deploy Database Schema

1. **Open Supabase Dashboard**
   - Go to [supabase.com](https://supabase.com)
   - Navigate to your project: `lwjudzphytpjywnzcxlu`

2. **Run Database Schema**
   - Go to **SQL Editor** in the left sidebar
   - Copy the entire contents of `deploy-to-supabase.sql`
   - Paste into the SQL Editor
   - Click **Run** to execute

3. **Verify Schema Deployment**
   - Go to **Database > Tables** 
   - You should see these tables:
     - `profiles`
     - `race_distances` (with 13 default distances)
     - `race_predictions`
     - `analytics_events`
     - `feedback_submissions`
     - `certificates`

### Step 2: Configure Authentication

1. **Enable Auth Providers**
   - Go to **Authentication > Settings**
   - Enable **Email** (should be enabled by default)
   - Optionally enable **Google OAuth**:
     - Add Google OAuth credentials
     - Set redirect URL: `http://localhost:8080/auth/callback`

2. **Configure Site URLs**
   - Site URL: `http://localhost:8080`
   - Redirect URLs: `http://localhost:8080/**`

### Step 3: Deploy Edge Functions (Optional for local testing)

For production deployment, you'll need to deploy the Edge Functions:

```bash
# Install Supabase CLI (if not already installed)
curl -sL https://github.com/supabase/cli/releases/latest/download/supabase_linux_amd64.tar.gz | tar xzf -

# Login to Supabase
./supabase login

# Link to your project
./supabase link --project-ref lwjudzphytpjywnzcxlu

# Deploy Edge Functions
./supabase functions deploy race-prediction
./supabase functions deploy analytics-tracker
./supabase functions deploy feedback-collector
./supabase functions deploy auth-management
```

### Step 4: Test the Integration

1. **Open Test Page**
   - Navigate to: `http://localhost:8080/test-auth.html`
   - This page will test all Supabase integrations

2. **Run Tests in Order**
   - ✅ **Connection Test**: Should show "SUCCESS: Connected to Supabase"
   - ✅ **Schema Test**: Click "Test Schema" - should show "SUCCESS: Schema exists"
   - ✅ **Authentication Test**: Try signing up with test@trinirvana.com
   - ✅ **API Test**: Test race prediction generation
   - ✅ **Analytics Test**: Test event tracking

### Expected Results

After successful deployment:

1. **Database Tables Created**: 6 tables with proper relationships
2. **Authentication Working**: Users can sign up/sign in
3. **Race Distances Populated**: 13 default race distances available
4. **Row Level Security**: All tables protected with RLS policies
5. **Edge Functions**: API endpoints for predictions, analytics, feedback

### Current Status: ✅ READY FOR TESTING

**Your configuration:**
- Project URL: `https://lwjudzphytpjywnzcxlu.supabase.co`
- Environment file updated with real credentials
- Docker containers running with Supabase integration
- Test page available at: `http://localhost:8080/test-auth.html`

### Next Steps

1. **Deploy the database schema** using the SQL Editor
2. **Test authentication** using the test page
3. **Verify all systems** are working correctly
4. **Proceed to production deployment** (Phase 3)

### Troubleshooting

**Schema deployment fails:**
- Check if you have the correct permissions
- Ensure you're connected to the right project
- Try running smaller parts of the SQL file

**Authentication not working:**
- Check browser console for errors
- Verify API keys are correct
- Check if email confirmation is required

**Functions not working:**
- For local testing, the functions will work via direct API calls
- For production, deploy the Edge Functions using the CLI

---

## 📊 Database Schema Overview

### Core Tables
- **profiles**: User profiles and metadata
- **race_distances**: Triathlon, running, cycling, swimming distances
- **race_predictions**: User-generated race time predictions
- **analytics_events**: User behavior tracking
- **feedback_submissions**: User feedback and ratings
- **certificates**: Generated race prediction certificates

### Security Features
- ✅ Row Level Security (RLS) enabled on all tables
- ✅ Users can only access their own data
- ✅ Service role can insert analytics for all users
- ✅ Anonymous users can read race distances
- ✅ Automatic profile creation on user registration

Your Tri Nirvana AI Platform is now ready for **Phase 3: Production Deployment**! 🎯