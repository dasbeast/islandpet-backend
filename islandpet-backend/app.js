import express from 'express';
import morgan from 'morgan';
import routes  from './src/routes/index.js';
import { logger } from './src/utils/logger.js';

const app = express();
console.log('[app] Express application initialized');
app.use(morgan(':method :url :status :response-time ms'));
app.use(express.json());
app.use('/', routes);

// global error handler
app.use((err, req, res, next) => {
    logger.error(err.stack || err);
    res.status(500).json({ error: 'Internal Server Error' });
});

export default app;