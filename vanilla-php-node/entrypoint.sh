#!/bin/bash
# Start one Node process per Node task, then run Apache.
#
# Two supported task shapes:
#   <task>/server.js       - the whole task is a self-contained Node app
#                            (serves its own static files + API). The ENTIRE
#                            /<task>/ path is proxied to it.
#   <task>/node/server.js  - Node lives beside other stacks in the task;
#                            only /<task>/node/ is proxied.
# In both cases the proxy strips the prefix, so the server sees root-relative
# paths (/, /api/deliveries, /assign) - exactly as when run standalone.
#
# Ports are FORCED via the preloaded port-inject.js shim, so servers that
# hardcode a port (e.g. listen(8080)) still bind the assigned one - no
# task-code changes needed. A crashed server is restarted after 2s so a
# broken push doesn't kill the whole container.
export NODE_OPTIONS="--require /usr/local/lib/port-inject.js"

PROXY_CONF=/etc/apache2/conf-enabled/zz-node-proxy.conf
: > "$PROXY_CONF"

start_node() {
    local dir="$1" port="$2"
    (
        export PORT="$port"
        cd "$dir"
        while true; do
            node server.js
            echo "Node server in '$dir' exited - restarting in 2s"
            sleep 2
        done
    ) &
}

port=3001
cd /var/www/html
for task in */; do
    task="${task%/}"
    [ "$task" = "*" ] && break
    if [ -f "$task/server.js" ]; then
        echo "Task '$task': self-contained Node app on internal port $port (whole /$task/ proxied)"
        start_node "/var/www/html/$task" "$port"
        {
            echo "ProxyPass /$task/ http://127.0.0.1:$port/"
            echo "ProxyPassReverse /$task/ http://127.0.0.1:$port/"
        } >> "$PROXY_CONF"
        port=$((port + 1))
    elif [ -f "$task/node/server.js" ]; then
        echo "Task '$task': Node stack on internal port $port (/$task/node/ proxied)"
        start_node "/var/www/html/$task/node" "$port"
        {
            echo "ProxyPass /$task/node/ http://127.0.0.1:$port/"
            echo "ProxyPassReverse /$task/node/ http://127.0.0.1:$port/"
        } >> "$PROXY_CONF"
        port=$((port + 1))
    fi
done

exec apache2-foreground
