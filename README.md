# WorldSkills UK Competition Templates

Pre-configured framework templates for offline competition environments.

## Templates

### Frontend
- **react** - React with Vite
- **vuejs** - Vue.js with Vite
- **svelte** - SvelteKit with static adapter
- **angular** - Angular CLI
- **nextjs** - Next.js
- **vanillajs** - Vanilla JavaScript

### Backend (Node.js)
- **expressjs** - Express.js with Sequelize
- **express-prisma** - Express.js with Prisma ORM
- **express-mongo** - Express.js with MongoDB
- **nestjs** - NestJS (TypeScript, no DB)
- **nestjs-prisma** - NestJS with Prisma ORM + MySQL
- **nextjs-prisma** - Next.js (App Router) with Prisma ORM + MySQL

### Backend (PHP)
- **php** - Plain PHP with Apache
- **laravel** - Laravel 12 with MySQL auto-configuration
- **codeigniter** - CodeIgniter 4
- **yii** - Yii 2

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
