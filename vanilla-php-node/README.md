# Vanilla + PHP + Node

One folder per task, named however the test project requires (`task01/`, `T1/`, `F3/`, ...). Solve each task in the stack of your choice - mixing is allowed.

```
<folder_name>/index.html    static task (served as-is)
<folder_name>/index.php     PHP task (mod_php, .htaccess supported)
<folder_name>/server.js     Node task (whole /<folder_name>/ routed to your server)
```

- Node: hardcoded ports are fine (`listen(8080)` etc.) - the port is injected at runtime, no collisions.
- The root page lists your task folders automatically, whatever they are named.
- Put the solution directly in the task folder - no `php/` or `node/` subfolders.
