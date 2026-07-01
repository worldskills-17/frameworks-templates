<?php
// Demo PHP endpoint - replace with the task's real handler.
header('Content-Type: application/json');
echo json_encode([
    'stack' => 'php',
    'status' => 'ok',
    'php_version' => PHP_VERSION,
]);
