<?php
require_once 'src/config/config.php';
require_once 'src/includes/header.php';
?>

<!-- Initialize Supabase -->
<script src="https://unpkg.com/@supabase/supabase-js@2"></script>
<script>
// Initialize Supabase with environment variables
const SUPABASE_URL = 'https://lwjudzphytpjywnzcxlu.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx3anVkenBoeXRwanl3bnpjeGx1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk4MDMzMjcsImV4cCI6MjA2NTM3OTMyN30.9RFekS9u9KO-eLyLfLQ3uTcELEEKAhz8JSUPR8_wSRw';

// Initialize Supabase Manager
const supabaseManager = new SupabaseManager(SUPABASE_URL, SUPABASE_ANON_KEY);

// Track page view
window.addEventListener('load', () => {
    supabaseManager.trackPageView('Home - Tri Nirvana AI Platform');
});
</script>

<div class="container">
    <div class="hero-section">
        <h1>Tri Nirvana AI Platform</h1>
        <p>Advanced Interactive Coaching Tools for Triathlon Excellence</p>
    </div>
    
    <div class="tools-grid">
        <div class="tool-card">
            <h3>Race Time Predictor</h3>
            <p>Predict your race times with advanced environmental factors</p>
            <a href="tools/race-predictor.php" class="btn-primary">Launch Tool</a>
        </div>
        
        <div class="tool-card">
            <h3>Workout Generator</h3>
            <p>AI-powered workout generation based on RPE</p>
            <a href="tools/workout-generator.php" class="btn-primary">Launch Tool</a>
        </div>
        
        <div class="tool-card coming-soon">
            <h3>Training Load Calculator</h3>
            <p>Calculate TSS, CTL, ATL, and TSB metrics</p>
            <span class="badge">Coming Soon</span>
        </div>
        
        <div class="tool-card coming-soon">
            <h3>Power Zone Calculator</h3>
            <p>Determine optimal training zones</p>
            <span class="badge">Coming Soon</span>
        </div>
    </div>
</div>

<?php require_once 'src/includes/footer.php'; ?>