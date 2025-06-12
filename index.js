import express from 'express';
import fs      from 'fs';
import http2   from 'http2';
import jwt     from 'jsonwebtoken';
import { Pool } from 'pg';
import cron    from 'node-cron';

// Initialize Postgres pool
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false }
});

// Create pets table if it doesn't exist
pool.query(`
  CREATE TABLE IF NOT EXISTS pets (
    activity_id   TEXT PRIMARY KEY,
    pet_id        TEXT,
    token         TEXT,
    hunger        INTEGER NOT NULL,
    happiness     INTEGER NOT NULL,
    last_updated  TIMESTAMPTZ DEFAULT NOW()
  )
`).catch(err => console.error('Error creating pets table', err));

// decide which APNs host to use
const APNS_HOST =
  process.env.APNS_ENV === 'production'
    ? 'https://api.push.apple.com'          // release builds
    : 'https://api.sandbox.push.apple.com'; // debug builds
const { TEAM_ID, KEY_ID, BUNDLE_ID } = process.env;
const key = fs.readFileSync(`./AuthKey_${KEY_ID}.p8`, 'utf8');
const app = express();
app.use(express.json());


app.post('/register', async (req, res) => {
  const { activityID, token, petID } = req.body;
  try {
    await pool.query(`
      INSERT INTO pets(activity_id, pet_id, token, hunger, happiness)
      VALUES($1, $2, $3, 0, 100)
      ON CONFLICT(activity_id) DO UPDATE
        SET token = EXCLUDED.token,
            pet_id = EXCLUDED.pet_id
    `, [activityID, petID, token]);
    res.sendStatus(200);
  } catch (err) {
    console.error('Error in /register', err);
    res.sendStatus(500);
  }
});

app.post('/update', async (req, res) => {
  const { activityID, state } = req.body;
  try {
    // Fetch token and existing state
    const { rows } = await pool.query(
      'SELECT token FROM pets WHERE activity_id = $1',
      [activityID]
    );
    if (!rows.length) return res.status(404).end();
    const token = rows[0].token;

    // Send APNs push
    await pushAPNs(token, state);

    // Persist new state
    await pool.query(`
      UPDATE pets
         SET hunger = $1,
             happiness = $2,
             last_updated = NOW()
       WHERE activity_id = $3
    `, [state.hunger, state.happiness, activityID]);

    res.sendStatus(200);
  } catch (err) {
    console.error('Error in /update', err);
    res.sendStatus(500);
  }
});

function pushAPNs(token, state) {
  return new Promise((resolve, reject) => {
    const client = http2.connect(APNS_HOST);
    const req = client.request({
      ':method': 'POST',
      ':path'  : `/3/device/${token}`,
      'apns-topic'    : `${BUNDLE_ID}.push-type.liveactivity`,
      'apns-push-type': 'liveactivity',
      authorization   : `Bearer ${makeJWT()}`
    });

    const payload = {
      aps: {
        timestamp: Math.floor(Date.now() / 1000),
        event: 'update',
        'content-state': state
      }
    };

    req.end(JSON.stringify(payload));
    req.on('response', headers => {
      let body = '';
      req.setEncoding('utf8');
      req.on('data', chunk => { body += chunk; });
      req.on('end', () => {
        console.log('APNs status', headers[':status'], body);
        client.close();
        headers[':status'] === 200
          ? resolve()
          : reject(new Error(`APNs ${headers[':status']} ${body}`));
      });
    });
  });
}

function makeJWT() {
  return jwt.sign({}, key, {
    algorithm: 'ES256',
    issuer: TEAM_ID,
    header: { alg: 'ES256', kid: KEY_ID },
    expiresIn: '20m'
  });
}

app.listen(8080, () => console.log('Backend running on :8080'))

// Schedule automatic state decay every 5 minutes
cron.schedule('*/5 * * * *', async () => {
  console.log('⏰ Running decay job');
  try {
    const { rows } = await pool.query(
      'SELECT activity_id, token, hunger, happiness FROM pets'
    );
    for (let pet of rows) {
      const newHunger    = Math.min(100, pet.hunger + 1);
      const newHappiness = Math.max(0, pet.happiness - 1);
      // Persist new state
      await pool.query(
        `UPDATE pets
           SET hunger = $1,
               happiness = $2,
               last_updated = NOW()
         WHERE activity_id = $3`,
        [newHunger, newHappiness, pet.activity_id]
      );
      // Push update to APNs
      await pushAPNs(pet.token, { hunger: newHunger, happiness: newHappiness });
      console.log(`🐾 Updated ${pet.activity_id}: hunger=${newHunger}, happiness=${newHappiness}`);
    }
  } catch (err) {
    console.error('Error running decay job', err);
  }
});
