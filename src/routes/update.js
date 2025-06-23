import express from 'express';
import { update } from '../controllers/updateController.js';
const router = express.Router();
router.post('/', update);
export default router;