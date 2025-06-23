import * as petState   from '../models/petState.js';
import * as petSession from '../models/petSession.js';
import { pushToAPNs }  from './apnsService.js';

export async function performDecay() {
    // 1) decay hunger/happiness in pet_states
    const decayed = await petState.decayStates();

    // 2) fetch all live sessions + their state
    const sessions = await petSession.getActiveSessions();

    // 3) push each session, delete if token invalid
    for (let sess of sessions) {
        if (!sess.token) continue;
        try {
            await pushToAPNs(sess.token, {
                hunger:    sess.hunger,
                happiness: sess.happiness
            });
        } catch (err) {
            const msg = err.message || '';
            if (
                msg.includes('BadDeviceToken') ||
                msg.includes('ExpiredToken')   ||
                msg.includes('Unregistered')
            ) {
                await petSession.deleteSession(sess.activity_id);
            } else {
                throw err;
            }
        }
    }
}