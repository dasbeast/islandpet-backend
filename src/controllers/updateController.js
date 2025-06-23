import * as petState   from '../models/petState.js';
import * as petSession from '../models/petSession.js';
import { pushToAPNs }  from '../services/apnsService.js';

export async function update(req, res, next) {
    try {
        const { petID, state } = req.body;
        await petState.updatePetState(petID, state.hunger, state.happiness);

        const sessions = await petSession.getActiveSessions()
            .then(rows => rows.filter(r => r.pet_id === petID && r.token));

        for (let sess of sessions) {
            await pushToAPNs(sess.token, state);
        }
        res.sendStatus(200);
    } catch (err) {
        next(err);
    }
}