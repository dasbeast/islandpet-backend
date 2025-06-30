import dotenv from 'dotenv';
dotenv.config();

export default {
    databaseUrl: process.env.DATABASE_URL,
    apnsEnv:    process.env.APNS_ENV === 'sandbox' ? 'sandbox' : 'production',
    teamId:     process.env.TEAM_ID,
    keyId:      process.env.KEY_ID,
    bundleId:   process.env.BUNDLE_ID,
};