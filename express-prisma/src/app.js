import express from 'express';
import cors from 'cors';
import { PrismaClient } from '@prisma/client';

const app = express();
const prisma = new PrismaClient();

app.use(cors());
app.use(express.json());

// Health check
app.get('/health', (req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Welcome page
app.get('/', (req, res) => {
    res.send('<div style="padding: 2rem; font-family: system-ui, sans-serif;"><h1 style="color: #5a67d8; font-size: 2rem; font-weight: bold;">Express + Prisma - It works!</h1><p style="margin-top: 1rem; color: #666;">Your Express + Prisma application is running successfully.</p></div>');
});

// Example API routes
app.get('/api/users', async (req, res) => {
    try {
        const users = await prisma.user.findMany();
        res.json(users);
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch users' });
    }
});

app.post('/api/users', async (req, res) => {
    try {
        const { email, name } = req.body;
        const user = await prisma.user.create({
            data: { email, name }
        });
        res.status(201).json(user);
    } catch (error) {
        res.status(500).json({ error: 'Failed to create user' });
    }
});

// Graceful shutdown
process.on('beforeExit', async () => {
    await prisma.$disconnect();
});

export default app;
