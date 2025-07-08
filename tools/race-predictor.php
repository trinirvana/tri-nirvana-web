<?php
$pageTitle = "Race Time Predictor";
require_once '../src/config/config.php';
require_once '../src/includes/header.php';
?>

<div class="container">
    <div class="section-title">Race Time Predictor</div>
    
    <div class="card">
        <form id="raceForm">
            <div class="form-row">
                <div class="form-group">
                    <label for="distance">Race Distance</label>
                    <select id="distance" class="form-control" required>
                        <option value="sichonUltimate">Sichon Ultimate (3.8km/180km/42.2km)</option>
                        <option value="sprint">Sprint (750m/20km/5km)</option>
                        <option value="olympic">Olympic (1.5km/40km/10km)</option>
                        <option value="t100">T100 (2km/80km/18km)</option>
                        <option value="half">Half Ironman (1.9km/90km/21.1km)</option>
                        <option value="ironman">Ironman (3.8km/180km/42.2km)</option>
                        <option value="norseman">Norseman (3.8km/180km/42.2km)</option>
                    </select>
                </div>
                
                <div class="form-group">
                    <label for="experience">Experience Level</label>
                    <select id="experience" class="form-control" required>
                        <option value="beginner">Beginner</option>
                        <option value="intermediate">Intermediate</option>
                        <option value="advanced">Advanced</option>
                        <option value="elite">Elite</option>
                    </select>
                </div>
            </div>
            
            <div class="form-row">
                <div class="form-group">
                    <label for="swimPace">Swimming Pace (per 100m)</label>
                    <input type="text" id="swimPace" class="form-control" placeholder="2:00" required>
                </div>
                
                <div class="form-group">
                    <label for="bikeSpeed">Bike Speed (km/h)</label>
                    <input type="number" id="bikeSpeed" class="form-control" min="15" max="60" value="30" required>
                </div>
            </div>
            
            <div class="form-row">
                <div class="form-group">
                    <label for="runPace">Running Pace (per km)</label>
                    <input type="text" id="runPace" class="form-control" placeholder="5:30" required>
                </div>
                
                <div class="form-group">
                    <label for="temperature">Temperature (°C)</label>
                    <input type="number" id="temperature" class="form-control" min="-10" max="50" value="25">
                </div>
            </div>
            
            <div class="form-group">
                <button type="button" id="toggleAdvanced" class="btn-secondary">Show Advanced Settings</button>
            </div>
            
            <div id="advancedSettings" class="hidden">
                <div class="form-row">
                    <div class="form-group">
                        <label for="windSpeed">Wind Speed (km/h)</label>
                        <input type="number" id="windSpeed" class="form-control" min="0" max="100" value="10">
                    </div>
                    
                    <div class="form-group">
                        <label for="precipitation">Precipitation</label>
                        <select id="precipitation" class="form-control">
                            <option value="none">None</option>
                            <option value="light">Light Rain</option>
                            <option value="moderate">Moderate Rain</option>
                            <option value="heavy">Heavy Rain</option>
                        </select>
                    </div>
                </div>
                
                <div class="form-row">
                    <div class="form-group">
                        <label for="bikeElevation">Bike Elevation Gain (m)</label>
                        <input type="number" id="bikeElevation" class="form-control" min="0" max="5000" value="100">
                    </div>
                    
                    <div class="form-group">
                        <label for="runElevation">Run Elevation Gain (m)</label>
                        <input type="number" id="runElevation" class="form-control" min="0" max="2000" value="50">
                    </div>
                </div>
            </div>
            
            <div class="form-group text-center">
                <button type="submit" id="calculateBtn" class="btn-primary">Calculate Race Time</button>
            </div>
        </form>
    </div>
    
    <div id="results" class="hidden">
        <div class="results-container">
            <h3>Predicted Race Results</h3>
            <div id="resultsContent"></div>
        </div>
    </div>
</div>

<script src="../public/js/race-predictor.js"></script>

<?php require_once '../src/includes/footer.php'; ?>