# WorldSkills UK Competition Templates

Pre-configured framework templates for offline competition environments.

## Templates

### Frontend
- **react** - React 19 with Vite 8, Tailwind 4, ESLint 10
- **vuejs** - Vue 3.5 with Vite 8, Vue Router 5, Pinia 4, Tailwind 4, Vitest 5
- **svelte** - SvelteKit 3 (Svelte 5) with the static adapter, Vite 8, Tailwind 4, Vitest 5
- **angular** - Angular 22 (zoneless, standalone), Tailwind 4, Vitest
- **nextjs** - Next.js 16 (React 19, App Router), Tailwind 4
- **nuxtjs** - Nuxt 4 (Vue 3.5, Vite 8), Tailwind 4
- **vanilla** - Plain HTML/CSS/JavaScript served by nginx

### Backend (Node.js)
- **expressjs** - Express 5 with MySQL (mysql2)
- **express-prisma** - Express 5 with Prisma 7 + MySQL (MariaDB driver adapter)
- **express-mongo** - Express 5 with the MongoDB driver 7
- **nestjs** - NestJS 12 (TypeScript 6, no DB)
- **nestjs-prisma** - NestJS 12 with Prisma 7 + MySQL
- **nextjs-prisma** - Next.js 16 (App Router) with Prisma 7 + MySQL

### Backend (PHP)
- **php** - Plain PHP with Apache
- **laravel** - Laravel 13 (PHP 8.4) with MySQL auto-configuration, Passport API auth and roles (spatie/laravel-permission) ready to use
- **codeigniter** - CodeIgniter 4.7
- **yii** - Yii 2.0 (PHP 8.4)

### Mixed stack
- **vanilla-php-node** - Static HTML/CSS/JS + raw PHP + raw Node in one container. For modules made of small independent tasks (one folder per task) where each backend task may be solved in either raw PHP or raw Node - mixing stacks between tasks in the same repo. Node servers auto-start with per-task port injection (hardcoded ports overridden); PHP runs via mod_php with .htaccess router support. No database.

## Features

All templates include:
- Dockerfile for containerized deployment
- GitHub Actions workflow for CI/CD
- Verdaccio npm registry configuration (Node.js templates)
- Production-ready nginx configuration (frontend templates)
- Auto-deployment to Gitea with Docker registry

## Laravel Template

Includes MySQL auto-configuration:
- Auto-migrations on container start
- Dynamic database credentials via build args
- Database naming: `{username}_module_{letter}`

## Usage

Clone individual template:
```bash
git clone https://github.com/worldskills-17/frameworks-templates.git
cd frameworks-templates/react
```

Import to Gitea (via setup script):
```bash
./import_framework.sh
```
