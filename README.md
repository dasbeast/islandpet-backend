# IslandPet Backend Service

This repository contains the server-side code for the IslandPet iOS application. It handles persistent pet state, Live Activity pushes via APNs, and exposes a REST API for client interactions.

---

## Technology Stack

- Node.js (v14 or newer)
- Express.js
- PostgreSQL
- TypeScript
- HTTP/2 (built-in Node.js module)

---

## Prerequisites

- Node.js and npm installed
- A running PostgreSQL instance
- An Apple Developer account with APNs Auth Key

---

## Configuration

1. Copy `.env.example` to `.env` in the project root.  
2. Fill in the following variables:

```ini
DATABASE_URL=postgres://user:password@host:port/database
APNS_ENV=sandbox
TEAM_ID=YOUR_TEAM_ID
KEY_ID=YOUR_KEY_ID          # matches AuthKey_<KEY_ID>.p8 filename
BUNDLE_ID=com.yourcompany.islandpet
```

3. Add the private key file `AuthKey_<KEY_ID>.p8` alongside your `.env` (ensure it is in `.gitignore`).

---

## Project Structure

```
islandpet-backend/
├── app.js            # Express application setup
├── server.js         # HTTP server entry point
├── package.json      # Project metadata and scripts
├── tsconfig.json     # TypeScript configuration
├── .env.example      # Sample environment variables
├── README.md         # This file
└── src/
    ├── config/       # Environment and feature-flag setup
    │   └── index.ts
    ├── db/           # Database connection and table creation
    │   └── index.ts
    ├── models/       # SQL wrappers for pet state and session tables
    │   ├── petState.ts
    │   └── petSession.ts
    ├── services/     # Business logic for decay and APNs push
    │   ├── petService.ts
    │   └── apnsService.ts
    ├── controllers/  # Request handlers for each endpoint
    │   ├── registerController.ts
    │   ├── updateController.ts
    │   ├── petsController.ts
    │   └── maintenanceController.ts
    ├── routes/       # Express routers mapping URLs to controllers
    │   ├── register.ts
    │   ├── update.ts
    │   ├── pets.ts
    │   ├── maintenance.ts
    │   └── index.ts
    ├── utils/        # Helper modules (JWT, logger)
    │   ├── jwt.ts
    │   └── logger.ts
    └── cron/         # Standalone script for scheduled decay runs
        └── decayJob.ts
```

---

## Installation

```bash
git clone https://github.com/yourusername/islandpet-backend.git
cd islandpet-backend
npm install
npm run build      
```

---

## Available Scripts

| Command        | Description                                       |
| -------------- | ------------------------------------------------- |
| `npm run dev`  | Run in development mode with hot reload           |
| `npm run build`| Compile TypeScript to the `dist/` directory       |
| `npm start`    | Start the compiled server                         |
| `npm test`     | Run unit and integration tests                    |
| `npm run lint` | Run ESLint across the codebase                    |

---

## API Endpoints

| Method | Path                            | Description                                   |
| ------ | ------------------------------- | --------------------------------------------- |
| POST   | `/register`                     | Create or update pet state and session        |
| POST   | `/register/token`               | Refresh APNs device token for a session       |
| PATCH  | `/register/rename-session`      | Rename an existing session ID                 |
| POST   | `/update`                       | Update pet state and push Live Activity       |
| POST   | `/decay`                        | Trigger global decay job                      |
| POST   | `/end`                          | End a Live Activity session                   |
| POST   | `/debug/clear-tables`           | Delete all pet state and session data         |
| DELETE | `/pets/:petID`                  | Remove state and session for a specific pet   |
| GET    | `/pets/:petID`                  | Retrieve current state for a specific pet     |

---

## Testing

Tests can be run with:

```bash
npm test
```

Ensure coverage reports and test scripts are configured in `package.json`.

---

## Deployment

1. Build the project: `npm run build`  
2. Start the server: `npm start`  
3. Configure a scheduler (Cron or GitHub Actions) to hit the `/decay` endpoint at your desired interval.

---

## Contributing

1. Fork the repository  
2. Create a feature branch  
3. Commit changes with clear messages  
4. Submit a pull request  

Please follow existing code style and run lint before creating a PR.

---

## License

## License

This project is licensed “All Rights Reserved.” See [LICENSE](LICENSE) for full details.

---