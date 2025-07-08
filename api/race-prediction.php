<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, x-session-id');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Only allow POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'error' => 'Method not allowed']);
    exit();
}

try {
    // Get request data
    $input = json_decode(file_get_contents('php://input'), true);
    $data = $input['data'] ?? $input;
    
    // Validate required fields
    $requiredFields = ['distance', 'experience'];
    foreach ($requiredFields as $field) {
        if (!isset($data[$field]) || empty($data[$field])) {
            throw new Exception("Missing required field: $field");
        }
    }
    
    // Race distance configurations
    $raceDistances = [
        'Sprint Triathlon' => ['swim' => 0.75, 'bike' => 20, 'run' => 5],
        'Olympic Triathlon' => ['swim' => 1.5, 'bike' => 40, 'run' => 10],
        'Half Ironman' => ['swim' => 1.9, 'bike' => 90, 'run' => 21.1],
        'Ironman' => ['swim' => 3.8, 'bike' => 180, 'run' => 42.2],
        '5K Run' => ['swim' => 0, 'bike' => 0, 'run' => 5],
        '10K Run' => ['swim' => 0, 'bike' => 0, 'run' => 10],
        'Half Marathon' => ['swim' => 0, 'bike' => 0, 'run' => 21.1],
        'Marathon' => ['swim' => 0, 'bike' => 0, 'run' => 42.2]
    ];
    
    // Get race configuration
    $distance = $data['distance'];
    if (!isset($raceDistances[$distance])) {
        throw new Exception("Invalid race distance: $distance");
    }
    
    $race = $raceDistances[$distance];
    $totalTime = 0;
    
    // Calculate swim time
    if ($race['swim'] > 0 && isset($data['swimPace'])) {
        $swimPaceMatch = [];
        if (preg_match('/(\d+):(\d+)/', $data['swimPace'], $swimPaceMatch)) {
            $swimPacePer100m = (int)$swimPaceMatch[1] * 60 + (int)$swimPaceMatch[2];
            $swimTime = ($race['swim'] * 1000 / 100) * $swimPacePer100m;
            $totalTime += $swimTime;
        }
    }
    
    // Calculate bike time
    if ($race['bike'] > 0 && isset($data['bikeSpeed']) && $data['bikeSpeed'] > 0) {
        $bikeTime = ($race['bike'] / $data['bikeSpeed']) * 3600; // Convert hours to seconds
        $totalTime += $bikeTime;
    }
    
    // Calculate run time
    if ($race['run'] > 0 && isset($data['runPace'])) {
        $runPaceMatch = [];
        if (preg_match('/(\d+):(\d+)/', $data['runPace'], $runPaceMatch)) {
            $runPacePerKm = (int)$runPaceMatch[1] * 60 + (int)$runPaceMatch[2];
            $runTime = $race['run'] * $runPacePerKm;
            $totalTime += $runTime;
        }
    }
    
    // Apply experience level adjustments
    $experienceMultipliers = [
        'beginner' => 1.15,
        'intermediate' => 1.0,
        'advanced' => 0.92,
        'elite' => 0.85
    ];
    
    $experience = $data['experience'];
    $multiplier = $experienceMultipliers[$experience] ?? 1.0;
    $totalTime *= $multiplier;
    
    // Apply environmental factors if provided
    if (isset($data['environmentalFactors'])) {
        $factors = $data['environmentalFactors'];
        $envMultiplier = 1.0;
        
        if (isset($factors['temperature']) && $factors['temperature'] > 25) {
            $envMultiplier += 0.05;
        }
        if (isset($factors['humidity']) && $factors['humidity'] > 70) {
            $envMultiplier += 0.03;
        }
        if (isset($factors['wind']) && $factors['wind'] > 15) {
            $envMultiplier += 0.08;
        }
        if (isset($factors['elevation']) && $factors['elevation'] > 500) {
            $envMultiplier += 0.1;
        }
        
        $totalTime *= $envMultiplier;
    }
    
    // Format predicted time
    $totalTimeInt = (int)round($totalTime);
    $hours = intval($totalTimeInt / 3600);
    $minutes = intval(($totalTimeInt % 3600) / 60);
    $seconds = intval($totalTimeInt % 60);
    $predictedTime = sprintf('%02d:%02d:%02d', $hours, $minutes, $seconds);
    
    // Save prediction to database if user is authenticated
    // Note: In production, you'd verify the JWT token here
    $sessionId = $_SERVER['HTTP_X_SESSION_ID'] ?? 'anonymous';
    
    // For now, we'll just track the prediction without saving to database
    // This can be enhanced later with proper Supabase integration
    
    // Return successful prediction
    $response = [
        'success' => true,
        'prediction' => [
            'time' => $predictedTime,
            'distance' => $distance,
            'breakdown' => [
                'total_seconds' => $totalTimeInt,
                'hours' => $hours,
                'minutes' => $minutes,
                'seconds' => $seconds,
                'race_type' => $race['swim'] > 0 ? 'triathlon' : 'running',
                'experience_multiplier' => $multiplier
            ],
            'inputs' => [
                'distance' => $distance,
                'swim_pace' => $data['swimPace'] ?? null,
                'bike_speed' => $data['bikeSpeed'] ?? null,
                'run_pace' => $data['runPace'] ?? null,
                'experience' => $experience
            ]
        ]
    ];
    
    http_response_code(200);
    echo json_encode($response, JSON_PRETTY_PRINT);
    
} catch (Exception $e) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ], JSON_PRETTY_PRINT);
}
?>