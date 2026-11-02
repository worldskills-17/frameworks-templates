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

Database credentials are injected into the container by the platform. Read them with `getenv()`:

```php
$db_host = getenv('DB_HOST');
$db_name = getenv('DB_NAME');
$db_user = getenv('DB_USER');
$db_pass = getenv('DB_PASSWORD');

if ($db_host === false || $db_name === false || $db_user === false || $db_pass === false) {
    throw new RuntimeException('Database environment variables are not set');
}

$pdo = new PDO(
    "mysql:host=$db_host;dbname=$db_name;charset=utf8mb4",
    $db_user,
    $db_pass,
    [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
);
```

Three things that cause an `Access denied for user ''@'...'` error:

- **Use `getenv()`, not `$_ENV`.** In the official PHP image `$_ENV` is empty (`variables_order` does not include `E`), so `$_ENV['DB_USER']` returns nothing. `$_SERVER` does not hold these variables either.
- **The variable is `DB_USER`, not `DB_USERNAME`.** `DB_USERNAME` is only the name of the build argument; inside the container it is exposed as `DB_USER`.
- **Do not add hardcoded fallbacks** (`?: 'myuser'`). If a variable is missing you want the error, not a silent connection with the wrong credentials. For local development pass the variables to the container instead (see Local Development).

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

// Database connection (see Database Connection above)
$pdo = new PDO(
    "mysql:host=" . getenv('DB_HOST') . ";dbname=" . getenv('DB_NAME') . ";charset=utf8mb4",
    getenv('DB_USER'),
    getenv('DB_PASSWORD'),
    [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
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

Set automatically by the platform when your repository is built. Read them with `getenv()`:

- `DB_HOST` - hostname of the shared MySQL server
- `DB_NAME` - the database created for this module
- `DB_USER` - database user
- `DB_PASSWORD` - database password

The values are shown on your landing page. Do not copy them into the code.

## Deployment

Automatic deployment on push to main branch:

```bash
git add .
git commit -m "Update application"
git push
```

Your application will be available at the module address shown on your landing page.

## Local Development

The database variables only exist inside the platform's container. On your own machine you have to provide them, otherwise you get `Access denied for user ''@'localhost'`:

```bash
# Start PHP built-in server with the variables set for this shell
DB_HOST=<host> DB_NAME=<database> DB_USER=<user> DB_PASSWORD=<password> php -S localhost:8000

# Or use Docker, passing the database variables yourself
docker build -t php-app .
docker run -p 8080:80 \
  -e DB_HOST=<host> -e DB_NAME=<database> -e DB_USER=<user> -e DB_PASSWORD=<password> \
  php-app
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
