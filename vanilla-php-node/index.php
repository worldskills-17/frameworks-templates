<?php
// Landing page - lists task folders in this repo with links.
// Replaced automatically as tasks are added; safe to customise or delete.
$tasks = array_filter(glob('*'), function ($f) {
    return is_dir($f) && !in_array($f, ['css', 'js', 'img', 'assets']);
});
sort($tasks);
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Tasks</title>
    <style>
        body { font-family: system-ui, sans-serif; background: #f5f5f5; color: #333; margin: 0; padding: 2rem; }
        h1 { color: #003764; }
        ul { list-style: none; padding: 0; max-width: 480px; }
        li a { display: block; background: #fff; border: 1px solid #ddd; border-radius: 4px;
               padding: 0.75rem 1rem; margin-bottom: 0.5rem; text-decoration: none; color: #003764; }
        li a:hover { border-color: #0066b3; background: #e8f4fc; }
        p.empty { color: #666; }
    </style>
</head>
<body>
    <h1>Tasks</h1>
    <?php if (empty($tasks)): ?>
        <p class="empty">No task folders yet. Push a folder per task (e.g. F1/, F2/ ...).</p>
    <?php else: ?>
        <ul>
            <?php foreach ($tasks as $task): ?>
                <li><a href="<?= htmlspecialchars($task) ?>/"><?= htmlspecialchars($task) ?></a></li>
            <?php endforeach; ?>
        </ul>
    <?php endif; ?>
</body>
</html>
