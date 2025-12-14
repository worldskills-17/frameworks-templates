import dotenv from 'dotenv';
dotenv.config();

import app from './app.js';

const port = process.env.PORT || 80;

app.listen(port, '0.0.0.0', () => {
    console.log(`Server running on http://localhost:${port}`);
});
