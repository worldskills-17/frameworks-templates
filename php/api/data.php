<?php
// JSON API endpoint example
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

// Get request method
$method = $_SERVER['REQUEST_METHOD'];

// Sample data
$response = [
    'success' => true,
    'method' => $method,
    'timestamp' => date('Y-m-d H:i:s'),
    'data' => [
        'message' => 'This is a sample JSON API response',
        'items' => [
            ['id' => 1, 'name' => 'Item 1'],
            ['id' => 2, 'name' => 'Item 2'],
            ['id' => 3, 'name' => 'Item 3'],
        ]
    ]
];

// Return JSON
echo json_encode($response, JSON_PRETTY_PRINT);
