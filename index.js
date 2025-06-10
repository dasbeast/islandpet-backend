import express from 'express';
import fs      from 'fs';
import http2   from 'http2';
import jwt     from 'jsonwebtoken';

// decide which APNs host to use
const APNS_HOST =
  process.env.APNS_ENV === 'production'
    ? 'https://api.push.apple.com'          // release builds
    : 'https://api.sandbox.push.apple.com'; // debug builds
const { TEAM_ID, KEY_ID, BUNDLE_ID } = process.env;
const key = fs.readFileSync(`./AuthKey_${KEY_ID}.p8`, 'utf8');
const app = express();
app.use(express.json());

// in-memory store – swap for Postgres later
const store = new Map();               // activityID → token

app.post('/register', (req, res) => {
  const { activityID, token } = req.body;
  store.set(activityID, token);
  res.sendStatus(200);
});

app.post('/update', (req, res) => {
  const { activityID, state } = req.body;
  const token = store.get(activityID);
  if (!token) return res.status(404).end();
  pushAPNs(token, state)
    .then(() => res.sendStatus(200))
    .catch(err => { console.error(err); res.sendStatus(500); });
});

function pushAPNs(token, state) {
  return new Promise((resolve, reject) => {
    const client = http2.connect('https://api.push.apple.com');
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
    req.on('response', h => {
      client.close();
      h[':status'] === 200 ? resolve() : reject(new Error(`APNs ${h[':status']}`));
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
