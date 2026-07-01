// Preloaded into every task's Node process (via NODE_OPTIONS --require).
//
// Forces the server to bind the container-assigned PORT even when the task
// code hardcodes one (e.g. server.listen(8080)). Two tasks hardcoding the
// same port would otherwise collide, and the per-task reverse proxy needs
// each server on its assigned port. Covers http/https/express/raw net -
// they all go through net.Server.prototype.listen.
const net = require('net');

const assignedPort = parseInt(process.env.PORT, 10);

if (assignedPort) {
    const originalListen = net.Server.prototype.listen;
    net.Server.prototype.listen = function (...args) {
        if (args.length && typeof args[0] === 'object' && args[0] !== null && typeof args[0] !== 'function') {
            // listen({ port, host, ... }, cb)
            args[0] = Object.assign({}, args[0], { port: assignedPort });
        } else if (args.length && (typeof args[0] === 'number' || /^\d+$/.test(args[0]))) {
            // listen(port[, host][, backlog][, cb])
            args[0] = assignedPort;
        } else if (!args.length || typeof args[0] === 'function') {
            // listen() / listen(cb) - prepend the port
            args.unshift(assignedPort);
        }
        return originalListen.apply(this, args);
    };
}
