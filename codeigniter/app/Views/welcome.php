<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CodeIgniter 4</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: system-ui, -apple-system, sans-serif;
            background: linear-gradient(135deg, #dd4814 0%, #f58220 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .container {
            text-align: center;
            color: white;
            padding: 2rem;
        }
        h1 { font-size: 3rem; margin-bottom: 1rem; }
        p { font-size: 1.25rem; opacity: 0.9; }
        .version { margin-top: 2rem; font-size: 0.9rem; opacity: 0.7; }
    </style>
</head>
<body>
    <div class="container">
        <h1>CodeIgniter 4</h1>
        <p>Your application is ready!</p>
        <div class="version">PHP <?= PHP_VERSION ?></div>
    </div>
</body>
</html>
