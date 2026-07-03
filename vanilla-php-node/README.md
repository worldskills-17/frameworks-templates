# Vanilla + PHP + Node

One folder per task. Solve each task in the stack of your choice - mixing is allowed.

```
F1/index.html        static task (served as-is)
F2/index.php         PHP task (mod_php, .htaccess supported)
F3/server.js         Node task (whole /F3/ routed to your server)
```

- Node: hardcoded ports are fine (`listen(8080)` etc.) - the port is injected at runtime, no collisions.
- The root page lists your task folders automatically.
- Put the solution directly in the task folder - no `php/` or `node/` subfolders.
