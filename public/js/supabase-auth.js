// Supabase Authentication and API Integration
// This module handles all Supabase interactions for the Tri Nirvana AI Platform

class SupabaseManager {
    constructor(supabaseUrl, supabaseAnonKey) {
        this.supabase = window.supabase.createClient(supabaseUrl, supabaseAnonKey);
        this.user = null;
        this.session = null;
        this.isInitialized = false;
        this.authCallbacks = [];
        this.sessionId = this.generateSessionId();
        
        this.init();
    }

    async init() {
        try {
            // Get initial session
            const { data: { session }, error } = await this.supabase.auth.getSession();
            if (error) {
                console.error('Session error:', error);
            } else {
                this.session = session;
                this.user = session?.user || null;
            }

            // Listen for auth changes
            this.supabase.auth.onAuthStateChange((event, session) => {
                console.log('Auth state changed:', event, session?.user?.email);
                this.session = session;
                this.user = session?.user || null;
                
                // Notify all callbacks
                this.authCallbacks.forEach(callback => {
                    try {
                        callback(event, session);
                    } catch (error) {
                        console.error('Auth callback error:', error);
                    }
                });

                // Track auth events
                this.trackEvent('auth', event, {
                    user_id: this.user?.id,
                    provider: session?.user?.app_metadata?.provider
                });
            });

            this.isInitialized = true;
            console.log('Supabase initialized successfully');
            
        } catch (error) {
            console.error('Supabase initialization error:', error);
            this.isInitialized = false;
        }
    }

    // Authentication methods
    async signUp(email, password, metadata = {}) {
        try {
            const { data, error } = await this.supabase.auth.signUp({
                email,
                password,
                options: {
                    data: {
                        display_name: metadata.displayName,
                        experience_level: metadata.experienceLevel,
                        beta_tester: true,
                        ...metadata
                    }
                }
            });

            if (error) throw error;

            this.trackEvent('auth', 'signup_attempt', {
                email,
                has_metadata: Object.keys(metadata).length > 0
            });

            return { success: true, data };
        } catch (error) {
            console.error('Sign up error:', error);
            return { success: false, error: error.message };
        }
    }

    async signIn(email, password) {
        try {
            const { data, error } = await this.supabase.auth.signInWithPassword({
                email,
                password
            });

            if (error) throw error;

            this.trackEvent('auth', 'signin_success', {
                email,
                method: 'password'
            });

            return { success: true, data };
        } catch (error) {
            console.error('Sign in error:', error);
            this.trackEvent('auth', 'signin_failure', {
                email,
                error: error.message
            });
            return { success: false, error: error.message };
        }
    }

    async signInWithGoogle() {
        try {
            const { data, error } = await this.supabase.auth.signInWithOAuth({
                provider: 'google',
                options: {
                    redirectTo: window.location.origin
                }
            });

            if (error) throw error;

            this.trackEvent('auth', 'oauth_attempt', {
                provider: 'google'
            });

            return { success: true, data };
        } catch (error) {
            console.error('Google sign in error:', error);
            return { success: false, error: error.message };
        }
    }

    async signOut() {
        try {
            const { error } = await this.supabase.auth.signOut();
            
            if (error) throw error;

            this.trackEvent('auth', 'signout', {
                user_id: this.user?.id
            });

            return { success: true };
        } catch (error) {
            console.error('Sign out error:', error);
            return { success: false, error: error.message };
        }
    }

    async resetPassword(email) {
        try {
            const { error } = await this.supabase.auth.resetPasswordForEmail(email, {
                redirectTo: `${window.location.origin}/reset-password`
            });

            if (error) throw error;

            this.trackEvent('auth', 'password_reset_request', { email });

            return { success: true };
        } catch (error) {
            console.error('Password reset error:', error);
            return { success: false, error: error.message };
        }
    }

    // Profile methods
    async getProfile() {
        if (!this.user) return { success: false, error: 'Not authenticated' };

        try {
            const response = await fetch(`${this.supabase.supabaseUrl}/functions/v1/auth-management/profile`, {
                method: 'GET',
                headers: {
                    'Authorization': `Bearer ${this.session?.access_token}`,
                    'Content-Type': 'application/json',
                    'x-session-id': this.sessionId
                }
            });

            const result = await response.json();
            
            if (!result.success) throw new Error(result.error);

            return { success: true, data: result.data };
        } catch (error) {
            console.error('Get profile error:', error);
            return { success: false, error: error.message };
        }
    }

    async updateProfile(profileData) {
        if (!this.user) return { success: false, error: 'Not authenticated' };

        try {
            const response = await fetch(`${this.supabase.supabaseUrl}/functions/v1/auth-management/profile`, {
                method: 'PUT',
                headers: {
                    'Authorization': `Bearer ${this.session?.access_token}`,
                    'Content-Type': 'application/json',
                    'x-session-id': this.sessionId
                },
                body: JSON.stringify({ data: profileData })
            });

            const result = await response.json();
            
            if (!result.success) throw new Error(result.error);

            return { success: true, data: result.data };
        } catch (error) {
            console.error('Update profile error:', error);
            return { success: false, error: error.message };
        }
    }

    // Prediction methods
    async savePrediction(predictionData) {
        try {
            const response = await fetch(`${this.supabase.supabaseUrl}/functions/v1/race-prediction`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'x-session-id': this.sessionId
                },
                body: JSON.stringify({ 
                    data: {
                        ...predictionData,
                        userId: this.user?.id
                    }
                })
            });

            const result = await response.json();
            
            if (!result.success) throw new Error(result.error);

            this.trackEvent('prediction', 'generated', {
                race_distance: predictionData.distance,
                experience_level: predictionData.experience,
                user_authenticated: !!this.user
            });

            return { success: true, data: result.data };
        } catch (error) {
            console.error('Save prediction error:', error);
            return { success: false, error: error.message };
        }
    }

    async getPredictionHistory(limit = 10) {
        if (!this.user) return { success: false, error: 'Not authenticated' };

        try {
            const { data, error } = await this.supabase
                .from('race_predictions')
                .select(`
                    *,
                    race_distances(name, swim_distance_km, bike_distance_km, run_distance_km),
                    belt_system(name, description, color_class, level)
                `)
                .eq('user_id', this.user.id)
                .order('created_at', { ascending: false })
                .limit(limit);

            if (error) throw error;

            return { success: true, data };
        } catch (error) {
            console.error('Get prediction history error:', error);
            return { success: false, error: error.message };
        }
    }

    // Feedback methods
    async submitFeedback(feedbackData) {
        try {
            const response = await fetch(`${this.supabase.supabaseUrl}/functions/v1/feedback-collector`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'x-session-id': this.sessionId
                },
                body: JSON.stringify({ 
                    data: {
                        ...feedbackData,
                        userId: this.user?.id,
                        pageUrl: window.location.href,
                        userAgent: navigator.userAgent
                    }
                })
            });

            const result = await response.json();
            
            if (!result.success) throw new Error(result.error);

            return { success: true, data: result.data };
        } catch (error) {
            console.error('Submit feedback error:', error);
            return { success: false, error: error.message };
        }
    }

    // Analytics methods
    async trackEvent(eventType, eventName, properties = {}) {
        try {
            const response = await fetch(`${this.supabase.supabaseUrl}/functions/v1/analytics-tracker/event`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'x-session-id': this.sessionId
                },
                body: JSON.stringify({ 
                    data: {
                        eventType,
                        eventName,
                        properties: {
                            ...properties,
                            timestamp: new Date().toISOString(),
                            page_url: window.location.href,
                            referrer: document.referrer
                        },
                        userId: this.user?.id,
                        sessionId: this.sessionId,
                        userAgent: navigator.userAgent
                    }
                })
            });

            // Don't throw errors for analytics - they should be silent
            if (!response.ok) {
                console.warn('Analytics tracking failed:', response.status);
            }
        } catch (error) {
            console.warn('Analytics tracking error:', error);
        }
    }

    async trackPageView(pageTitle = document.title) {
        try {
            const response = await fetch(`${this.supabase.supabaseUrl}/functions/v1/analytics-tracker/page-view`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'x-session-id': this.sessionId
                },
                body: JSON.stringify({ 
                    data: {
                        sessionId: this.sessionId,
                        userId: this.user?.id,
                        pageUrl: window.location.href,
                        referrer: document.referrer,
                        title: pageTitle
                    }
                })
            });

            if (!response.ok) {
                console.warn('Page view tracking failed:', response.status);
            }
        } catch (error) {
            console.warn('Page view tracking error:', error);
        }
    }

    async updateSession(metrics = {}) {
        try {
            const response = await fetch(`${this.supabase.supabaseUrl}/functions/v1/analytics-tracker/session`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'x-session-id': this.sessionId
                },
                body: JSON.stringify({ 
                    data: {
                        sessionId: this.sessionId,
                        userId: this.user?.id,
                        userAgent: navigator.userAgent,
                        ...metrics
                    }
                })
            });

            if (!response.ok) {
                console.warn('Session update failed:', response.status);
            }
        } catch (error) {
            console.warn('Session update error:', error);
        }
    }

    // Utility methods
    generateSessionId() {
        return 'session_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
    }

    onAuthStateChange(callback) {
        this.authCallbacks.push(callback);
        
        // Return unsubscribe function
        return () => {
            const index = this.authCallbacks.indexOf(callback);
            if (index > -1) {
                this.authCallbacks.splice(index, 1);
            }
        };
    }

    isAuthenticated() {
        return !!this.user;
    }

    getUser() {
        return this.user;
    }

    getSession() {
        return this.session;
    }

    async deleteAccount(confirmation) {
        if (!this.user) return { success: false, error: 'Not authenticated' };

        try {
            const response = await fetch(`${this.supabase.supabaseUrl}/functions/v1/auth-management/delete-account`, {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${this.session?.access_token}`,
                    'Content-Type': 'application/json',
                    'x-session-id': this.sessionId
                },
                body: JSON.stringify({ data: { confirmation } })
            });

            const result = await response.json();
            
            if (!result.success) throw new Error(result.error);

            return { success: true, data: result.data };
        } catch (error) {
            console.error('Delete account error:', error);
            return { success: false, error: error.message };
        }
    }
}

// Export for use in other modules
window.SupabaseManager = SupabaseManager;