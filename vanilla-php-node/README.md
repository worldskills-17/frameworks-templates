# vanilla-php-node

Static HTML/CSS/JS + raw PHP + raw Node in a single container. Intended for
modules made of small independent tasks (one folder per task) where each
backend task may be solved in either raw PHP or raw Node - mixing stacks
between tasks in the same repo is fine.

## Layout

One folder per task; the competitor puts the chosen stack's solution DIRECTLY
in the task folder (no `php/` or `node/` subfolders in submissions):

```
F1/index.html          static task            -> /F1/
F6/index.php           PHP task               -> /F6/?group_by=...
F7/server.js           Node task (whole /F7/ proxied to it)
F9/index.html + index.php + .htaccess   full-stack PHP: page at /F9/,
                                        API routed to index.php
F9/server.js + index.html + ...         full-stack Node: server serves
                                        its own page + API under /F9/
```

- The repo root serves a landing page (`index.php`) listing all task folders.
- Task folder names are free-form (`F1`, `task-3`, ...).
- `DirectoryIndex` order is `index.html` then `index.php` - a full-stack PHP
  task shows its page at `/<task>/` while `.htaccess` routes API paths to PHP.

## How each stack is served

| Task shape | How it runs | URL |
|------------|-------------|-----|
| Static | Apache, as-is | `/<task>/` |
| PHP (`<task>/*.php`) | Apache mod_php | `/<task>/` (index.php) or `/<task>/file.php` |
| Node (`<task>/server.js`) | started at boot, own internal port, the WHOLE `/<task>/` path is proxied to it | `/<task>/...` |
| Node (`<task>/node/server.js`) | same, but only `/<task>/node/` is proxied (starter layout with both stacks present) | `/<task>/node/...` |

## Node specifics

- Every `<task>/server.js` (and legacy `<task>/node/server.js`) found at
  container start is launched automatically and restarted after 2s if it
  crashes. A task-root `server.js` gets the whole `/<task>/` path proxied,
  so it serves its own static files and API exactly as when run standalone.
- The container assigns each task its own port and **forces it at runtime**:
  a preload shim overrides whatever port is passed to `listen()`, so
  hardcoded ports (`server.listen(8080)`) work unchanged and cannot collide
  between tasks. Reading `process.env.PORT` still works and is the cleaner
  pattern for standalone runs.
- The `/<task>/node/` prefix is stripped by the proxy - the server sees
  root-relative paths (`/status`, `/transform`), exactly as when run
  standalone with `node server.js`.
- Raw Node needs no dependencies. If a task does add a `package.json`, keep
  it inside the task's `node/` folder (never at the repo root) and install
  during development; committed `node_modules` are served/executed as-is.

## PHP specifics

- Any `.php` file executes in place - no configuration needed.
- To emulate `php -S localhost:PORT router.php` (all requests through one
  router), drop an `.htaccess` next to the router:

  ```
  RewriteEngine On
  RewriteCond %{REQUEST_FILENAME} !-f
  RewriteRule ^ router.php [QSA,L]
  ```

- Keep `composer.json` (if a task ever needs one) inside the task folder,
  never at the repo root.

## Demo task

`demo/` shows all three stacks working together: a static page that fetches
the task's PHP and Node endpoints and prints their JSON. Open `/demo/` after
the first deploy to confirm the container works, then delete the folder.

## No database

This template is intentionally DB-free (self-contained tasks). Tasks needing
MySQL/MongoDB belong in one of the dedicated backend framework templates.
