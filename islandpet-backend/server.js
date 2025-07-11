// Add this block to the top of server.js
process.on('uncaughtException', (err, origin) => {
    console.error('!!!!!!!!!! UNCAUGHT EXCEPTION !!!!!!!!!!!');
    console.error('Error:', err);
    console.error('Origin:', origin);
    // It's recommended to exit gracefully after an uncaught exception
    process.exit(1);
});

import app from './app.js';

const PORT = process.env.PORT || 8080;
console.log('[server] NODE_ENV:', process.env.NODE_ENV);
console.log('[server] APNS_ENV =', process.env.APNS_ENV);
console.log('[server] DATABASE_URL =', process.env.DATABASE_URL);
console.log('[server] Starting server on port', PORT);
console.log('[server] Process PID:', process.pid);
app.listen(PORT, () => console.log('[server] Listening on port', PORT));