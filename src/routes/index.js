import express from 'express';
import registerRouter    from './register.js';
import updateRouter      from './update.js';
import petsRouter        from './pets.js';
import maintenanceRouter from './maintenance.js';

const router = express.Router();
router.use('/register',    registerRouter);
router.use('/update',      updateRouter);
router.use('/pets',        petsRouter);
router.use('/',            maintenanceRouter);

export default router;