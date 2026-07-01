# vanilla-php-node - static HTML/CSS/JS + raw PHP + raw Node in one container.
#
# For modules made of small independent tasks where each backend task may be
# solved in EITHER raw PHP or raw Node - even mixing stacks between tasks in
# the same repo. One container serves all three stacks:
#   - static task folders     -> Apache (as-is)
#   - <task>/php/*.php        -> Apache mod_php (with .htaccess routing support)
#   - <task>/node/server.js   -> started by the entrypoint on an internal port,
#                                reverse-proxied at /<task>/node/
#
# No database, no build args - tasks are self-contained by design.

# Node runtime (binaries only) - grafted onto the PHP image below
FROM node:22-bookworm-slim AS node-runtime

FROM php:8.3-apache

# Node binary + npm (npm only needed if a task brings dependencies)
COPY --from=node-runtime /usr/local/bin/node /usr/local/bin/node
COPY --from=node-runtime /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -sf /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
    && ln -sf /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx

# rewrite: per-task .htaccess routers (php -S router.php equivalent)
# proxy/proxy_http: route Node tasks to their servers
# DirectoryIndex: index.html BEFORE index.php (a full-stack PHP task serves its
# page at /<task>/ and its API from index.php via .htaccess), then the styled
# /task-view.php listing for folders with no index at all (instead of a 403).
# Must be a zz- conf AND start with "DirectoryIndex disabled": DirectoryIndex
# directives in the same context CONCATENATE, so without the reset the image's
# docker-php.conf entries (index.php first) stay ahead of ours.
RUN a2enmod rewrite proxy proxy_http \
    && sed -i 's/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf \
    && printf 'DirectoryIndex disabled\nDirectoryIndex index.html index.php /task-view.php\n' > /etc/apache2/conf-available/zz-task-view.conf \
    && a2enconf zz-task-view

COPY . /var/www/html/
RUN chown -R www-data:www-data /var/www/html \
    && cp /var/www/html/entrypoint.sh /usr/local/bin/vanilla-php-node-entrypoint \
    && chmod +x /usr/local/bin/vanilla-php-node-entrypoint \
    && cp /var/www/html/port-inject.js /usr/local/lib/port-inject.js \
    && rm /var/www/html/entrypoint.sh /var/www/html/port-inject.js

EXPOSE 80

CMD ["vanilla-php-node-entrypoint"]
