<?php

$config = [
    'id' => 'basic-console',
    'basePath' => dirname(__DIR__),
    'bootstrap' => ['log'],
    'controllerNamespace' => 'app\commands',
    'aliases' => [
        '@bower' => '@vendor/bower-asset',
        '@npm'   => '@vendor/npm-asset',
    ],
    'components' => [
        'cache' => [
            'class' => 'yii\caching\FileCache',
        ],
        'log' => [
            'targets' => [
                [
                    'class' => 'yii\log\FileTarget',
                    'levels' => ['error', 'warning'],
                ],
            ],
        ],
        'db' => [
            'class' => 'yii\db\Connection',
            'dsn' => $_ENV['DB_DSN'] ?? getenv('DB_DSN') ?: 'mysql:host=localhost;dbname=yii2basic',
            'username' => $_ENV['DB_USERNAME'] ?? getenv('DB_USERNAME') ?: 'root',
            'password' => $_ENV['DB_PASSWORD'] ?? getenv('DB_PASSWORD') ?: '',
            'charset' => 'utf8mb4',
        ],
    ],
    'params' => [],
];

return $config;
