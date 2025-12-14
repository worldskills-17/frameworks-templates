<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PHP Application</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            background: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        h1 { color: #333; }
        .info { background: #e3f2fd; padding: 15px; border-radius: 4px; margin: 20px 0; }
        .success { color: #4caf50; }
        .error { color: #f44336; }
        pre { background: #f5f5f5; padding: 10px; border-radius: 4px; overflow-x: auto; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Welcome to Your PHP Application</h1>

        <div class="info">
            <strong>PHP Version:</strong> <?php echo PHP_VERSION; ?><br>
            <strong>Server:</strong> <?php echo $_SERVER['SERVER_SOFTWARE']; ?><br>
            <strong>Document Root:</strong> <?php echo $_SERVER['DOCUMENT_ROOT']; ?>
        </div>

        <h2>Quick Start</h2>
        <p>This is a vanilla PHP template. You can:</p>
        <ul>
            <li>Edit this <code>index.php</code> file</li>
            <li>Create new PHP files in the root directory</li>
            <li>Build APIs in the <code>api/</code> directory</li>
            <li>Connect to MySQL database using provided credentials</li>
        </ul>

        <h2>Database Connection</h2>
        <?php
        // Database credentials from environment
        $db_host = getenv('DB_HOST') ?: 'db.worldskills.uk';
        $db_name = getenv('DB_NAME') ?: 'your_database';
        $db_user = getenv('DB_USER') ?: 'your_username';
        $db_pass = getenv('DB_PASSWORD') ?: 'your_password';

        try {
            $pdo = new PDO(
                "mysql:host=$db_host;dbname=$db_name;charset=utf8mb4",
                $db_user,
                $db_pass,
                [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
            );
            echo '<p class="success">✓ Database connection successful!</p>';

            // Example query
            $stmt = $pdo->query("SELECT DATABASE() as db_name, VERSION() as version");
            $result = $stmt->fetch(PDO::FETCH_ASSOC);
            echo '<pre>';
            echo "Connected to: " . $result['db_name'] . "\n";
            echo "MySQL Version: " . $result['version'];
            echo '</pre>';

        } catch (PDOException $e) {
            echo '<p class="error">✗ Database connection failed: ' . htmlspecialchars($e->getMessage()) . '</p>';
            echo '<p><small>Make sure to set DB_HOST, DB_NAME, DB_USER, and DB_PASSWORD environment variables.</small></p>';
        }
        ?>

        <h2>Example Routes</h2>
        <ul>
            <li><a href="/api/hello.php">/api/hello.php</a> - Simple API endpoint</li>
            <li><a href="/api/data.php">/api/data.php</a> - JSON API example</li>
        </ul>

        <h2>PHP Info</h2>
        <p><a href="/info.php">View PHP Info</a> (create info.php with phpinfo())</p>
    </div>
</body>
</html>
