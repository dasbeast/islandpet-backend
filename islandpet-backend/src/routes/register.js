import express from 'express';
import {
    register,
    refreshToken,
    renameSession      // ← import it
} from '../controllers/registerController.js';

const router = express.Router();
router.post('/',        register);
router.post('/token',   refreshToken);
router.patch(
    '/rename-session',   // ← matches your original path
    renameSession
);
export default router;