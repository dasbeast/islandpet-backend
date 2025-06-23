import express from 'express';
import routes  from './src/routes/index.js';
import { logger } from './src/utils/logger.js';

const app = express();
app.use(express.json());
app.use('/', routes);

// global error handler
app.use((err, req, res, next) => {
    logger.error(err.stack || err);
    res.status(500).json({ error: 'Internal Server Error' });
});

export default app;