<?php
// DirectoryIndex fallback - renders a styled listing for any folder that has
// no index.html/index.php of its own (backend-only task folders would
// otherwise return 403, since directory listing is disabled).
$uri = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH);
$rel = trim(urldecode($uri), '/');
$root = realpath(__DIR__);
$dir = realpath(__DIR__ . '/' . $rel);

// Only render real directories inside the web root
if ($rel === '' || $dir === false || strpos($dir, $root) !== 0 || !is_dir($dir)) {
    http_response_code(404);
    exit('Not found');
}

$entries = array_diff(scandir($dir), ['.', '..']);
sort($entries);
$isNodeDir = basename($dir) === 'node' && file_exists("$dir/server.js");
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= htmlspecialchars($rel) ?></title>
    <style>
        body { font-family: system-ui, sans-serif; background: #f5f5f5; color: #333; margin: 0; padding: 2rem; }
        h1 { color: #003764; font-size: 1.2rem; }
        ul { list-style: none; padding: 0; max-width: 480px; }
        li a { display: block; background: #fff; border: 1px solid #ddd; border-radius: 4px;
               padding: 0.6rem 1rem; margin-bottom: 0.5rem; text-decoration: none; color: #003764; }
        li a:hover { border-color: #0066b3; background: #e8f4fc; }
        .note { color: #666; font-size: 0.85rem; max-width: 480px; }
        .up { color: #666; }
    </style>
</head>
<body>
    <h1>/<?= htmlspecialchars($rel) ?>/</h1>
    <ul>
        <li><a class="up" href="/<?= htmlspecialchars(dirname($rel) === '.' ? '' : dirname($rel) . '/') ?>">&larr; up</a></li>
        <?php foreach ($entries as $entry): ?>
            <?php $suffix = is_dir("$dir/$entry") ? '/' : ''; ?>
            <li><a href="<?= htmlspecialchars($entry . $suffix) ?>"><?= htmlspecialchars($entry . $suffix) ?></a></li>
        <?php endforeach; ?>
    </ul>
    <?php if ($isNodeDir): ?>
        <p class="note">This folder is served by its own Node process - request the task's
        endpoint paths directly (e.g. <code>/<?= htmlspecialchars($rel) ?>/&lt;endpoint&gt;</code>).</p>
    <?php elseif (is_dir("$dir/node") && file_exists("$dir/node/server.js")): ?>
        <p class="note"><code>node/</code> is a live Node server - request its endpoints
        directly, e.g. <code>/<?= htmlspecialchars($rel) ?>/node/&lt;endpoint&gt;</code>.
        Opening <code>node/</code> itself hits the server's root route, which returns
        404 unless the task defines one.</p>
    <?php endif; ?>
</body>
</html>
