// Load .env before any other module is evaluated (ESM imports are hoisted,
// so a dotenv.config() call here would run after app.js is imported)
import 'dotenv/config';
import app from './app.js';

const port = process.env.PORT || 80;

// Express 5 passes listen errors (e.g. EADDRINUSE) to this callback
app.listen(port, '0.0.0.0', (error) => {
    if (error) {
        throw error;
    }
    console.log(`Listening on http://localhost:${port}`);
});
