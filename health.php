<?php
header('Content-Type: application/json');

// Check database connection
try {
    $pdo = new PDO(
        "mysql:host=" . $_ENV['DB_HOST'] . ";dbname=" . $_ENV['DB_NAME'],
        $_ENV['DB_USER'],
        $_ENV['DB_PASS']
    );
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Test simple query
    $stmt = $pdo->query("SELECT 1");
    $db_status = "healthy";
} catch (Exception $e) {
    $db_status = "error: " . $e->getMessage();
}

$health = [
    'status' => 'healthy',
    'timestamp' => date('c'),
    'version' => '1.0.0-beta',
    'services' => [
        'database' => $db_status,
        'web' => 'healthy'
    ]
];

http_response_code(200);
echo json_encode($health, JSON_PRETTY_PRINT);
?>