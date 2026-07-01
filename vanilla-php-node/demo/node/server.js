// Demo Node endpoint - replace with the task's real handler.
//
// The container assigns each task its own port and FORCES it at runtime
// (hardcoded ports are overridden by a preload shim), so a plain
// listen(8080) works too. Reading process.env.PORT is still the cleaner
// pattern and keeps standalone runs (node server.js) predictable.
const http = require('http');

const PORT = process.env.PORT || 8080;

const server = http.createServer((req, res) => {
    // Paths arrive root-relative (the /<task>/node/ prefix is stripped by the
    // proxy), so route on req.url exactly as when running standalone.
    if (req.url === '/status') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
            stack: 'node',
            status: 'ok',
            node_version: process.version,
        }));
        return;
    }
    res.writeHead(404, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'not found' }));
});

server.listen(PORT, () => {
    console.log(`Demo Node server listening on ${PORT}`);
});
