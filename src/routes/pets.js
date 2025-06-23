import express from 'express';
import { getPet } from '../controllers/petsController.js';
const router = express.Router();
router.get('/:petID', getPet);
export default router;