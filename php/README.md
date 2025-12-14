# PHP Template

A vanilla PHP template for WorldSkills UK competitions. This template provides a minimal PHP 8.3 + Apache environment for building web applications and APIs.

## Features

- **PHP 8.3** with Apache
- **MySQL** database support (PDO and MySQLi)
- **Docker** containerized deployment
- **CI/CD** with GitHub Actions
- **Zero configuration** - just code and deploy

## Quick Start

1. **Edit `index.php`** - Main entry point
2. **Create API endpoints** in `api/` directory
3. **Push to deploy** - Automatic build and deployment

## Database Connection

Database credentials are provided via environment variables:

```php
$db_host = getenv('DB_HOST') ?: 'db.worldskills.uk';
$db_name = getenv('DB_NAME') ?: 'compXX_module_x';
$db_user = getenv('DB_USER') ?: 'compXX';
$db_pass = getenv('DB_PASSWORD') ?: 'your_password';

$pdo = new PDO(
    "mysql:host=$db_host;dbname=$db_name;charset=utf8mb4",
    $db_user,
    $db_pass,
    [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
);
```

## Directory Structure

```
php/
├── index.php           # Main entry point
├── api/                # API endpoints
│   ├── hello.php       # Example endpoint
│   └── data.php        # JSON API example
├── Dockerfile          # Docker configuration
└── .github/workflows/  # CI/CD
```

## Creating API Endpoints

Create new PHP files in the `api/` directory:

**api/users.php**
```php
<?php
header('Content-Type: application/json');

// Database connection
$pdo = new PDO(
    "mysql:host=db.worldskills.uk;dbname=" . getenv('DB_NAME'),
    getenv('DB_USER'),
    getenv('DB_PASSWORD')
);

// Query
$stmt = $pdo->query("SELECT * FROM users");
$users = $stmt->fetchAll(PDO::FETCH_ASSOC);

// Return JSON
echo json_encode([
    'success' => true,
    'data' => $users
]);
```

## Environment Variables

Set in your deployment environment (automatically configured in production):

- `DB_HOST` - Database host (db.worldskills.uk)
- `DB_NAME` - Database name (compXX_module_x)
- `DB_USER` - Database user (compXX)
- `DB_PASSWORD` - Database password

## Deployment

Automatic deployment on push to main branch:

```bash
git add .
git commit -m "Update application"
git push
```

Your application will be available at:
`https://wsXX.worldskills.uk/module-x/`

## Local Development

```bash
# Start PHP built-in server
php -S localhost:8000

# Or use Docker
docker build -t php-app .
docker run -p 8080:80 php-app
```

## Installed PHP Extensions

- PDO
- PDO_MySQL
- MySQLi

## Apache Configuration

- mod_rewrite enabled
- DocumentRoot: `/var/www/html`

## Tips

1. Use PDO with prepared statements for security
2. Set appropriate CORS headers for API endpoints
3. Use `http_response_code()` for proper status codes
4. Enable error reporting during development only

## Support

See competition documentation for database credentials and deployment details.
