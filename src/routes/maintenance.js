import express from 'express';
import {
  decay,
  endSession,
  clearAll,
  deletePet
} from '../controllers/maintenanceController.js';

const router = express.Router();
router.post('/decay',         decay);
router.post('/end',           endSession);
router.post('/debug/clear-tables',   clearAll);
router.delete('/pets/:petID', deletePet);

export default router;