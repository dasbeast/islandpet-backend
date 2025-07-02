# IslandPet

![IslandPet](https://placehold.co/800x200/A7D3A3/333333?text=IslandPet)

**IslandPet** is a full-stack virtual pet application that brings a delightful, interactive companion to your iPhone's Dynamic Island and Lock Screen. This monorepo contains the complete source code for the iOS frontend and the Node.js backend service that powers the experience.

---

## Table of Contents

- [Project Overview](#project-overview)
- [Monorepo Structure](#monorepo-structure)
- [Technology Stack](#technology-stack)
- [Frontend (iOS App)](#frontend-ios-app)
  - [Setup](#frontend-setup)
  - [Key Features](#frontend-key-features)
- [Backend (Node.js Server)](#backend-nodejs-server)
  - [Prerequisites](#backend-prerequisites)
  - [Setup & Installation](#backend-setup--installation)
  - [Configuration](#backend-configuration)
  - [Running the Server](#running-the-server)
  - [API Endpoints](#api-endpoints)
- [How It Works](#how-it-works)
- [License](#license)

---

## Project Overview

IslandPet allows users to adopt and care for a virtual pet. The pet's status (hunger and happiness) is displayed in a Live Activity on the iPhone's Lock Screen and in the Dynamic Island. Users can interact with their pet directly from the Live Activity, and the pet's state will change over time, requiring care and attention.

The system is designed to be persistent. Even when the app is closed, the backend service periodically updates the pet's state and sends push notifications to keep the Live Activity on the user's device in sync.

## Monorepo Structure

The project is organized into a monorepo containing two main packages:

-   **`/islandPet-frontend`**: The native iOS application written in Swift and SwiftUI. This includes the main app, the Live Activity widget, and all UI components.
-   **`/islandpet-backend`**: The Node.js backend service built with Express.js. It manages pet state, user sessions, and communication with Apple Push Notification service (APNs).

.├── .github/              # GitHub Actions workflows (e.g., for the decay job)├── islandpet-backend/    # Node.js backend service└── islandPet-frontend/   # Xcode project for the iOS App
## Technology Stack

| Component | Technology                                       |
| :-------- | :----------------------------------------------- |
| **Frontend** | Swift, SwiftUI, ActivityKit, WidgetKit           |
| **Backend** | Node.js, Express.js, PostgreSQL                |
| **Push Notifications** | Apple Push Notification service (APNs) |
| **Database** | PostgreSQL                                       |

---

## Frontend (iOS App)

The frontend is a modern iOS application built with SwiftUI.

### Frontend Setup

1.  Navigate to the `islandPet-frontend/` directory.
2.  Open the `IslandPet.xcodeproj` file in Xcode.
3.  Select a target simulator or a physical device.
4.  Run the project (Cmd+R).

All dependencies are managed by Xcode.

### Frontend Key Features

-   **PetSelectionView.swift**: A carousel view allowing users to choose which pet to adopt.
-   **PetDashboardView.swift**: The main screen of the app where users can see their pet's stats and initiate the Live Activity.
-   **PetActivityWidget.swift**: The Widget Extension that defines the UI for the Lock Screen, Dynamic Island, and Apple Watch complications.
-   **PetIntents.swift**: Handles user interactions (feeding, playing) directly from the Live Activity using App Intents.

---

## Backend (Node.js Server)

The backend is a Node.js service that acts as the brain for the pet's persistent state.

### Backend Prerequisites

-   Node.js (v14 or newer)
-   npm
-   A running PostgreSQL instance
-   An Apple Developer account with an APNs Auth Key (`.p8` file).

### Backend Setup & Installation

1.  Navigate to the `islandpet-backend/` directory.
2.  Install the dependencies:
    ```bash
    npm install
    ```

### Backend Configuration

1.  In the `islandpet-backend/` directory, create a `.env` file. You can copy the existing `README.md`'s example as a template.
2.  Fill in the required environment variables:

    ```ini
    # .env file

    # Your PostgreSQL connection string
    DATABASE_URL=postgres://user:password@host:port/database

    # APNs Environment: "sandbox" for development, "production" for TestFlight/App Store
    APNS_ENV=sandbox

    # Your Apple Developer Team ID
    TEAM_ID=YOUR_TEAM_ID

    # The Key ID for your APNs Auth Key
    KEY_ID=YOUR_KEY_ID

    # Your app's bundle identifier
    BUNDLE_ID=com.yourcompany.IslandPet
    ```

3.  Place your APNs Auth Key file (e.g., `AuthKey_YOUR_KEY_ID.p8`) in the root of the `islandpet-backend/` directory. Ensure this file is listed in your `.gitignore` and is **never** committed to version control.

The database tables (`pet_states`, `pet_sessions`) will be created automatically when the server starts for the first time.

### Running the Server

-   **For development (with hot-reloading):**
    ```bash
    npm run dev
    ```
-   **For production:**
    ```bash
    npm start
    ```

### API Endpoints

The server exposes the following REST API endpoints:

| Method | Path                       | Description                                                     |
| :----- | :------------------------- | :-------------------------------------------------------------- |
| `POST` | `/register`                | Creates a new pet and session when a user adopts a pet.         |
| `POST` | `/register/token`          | Updates the APNs push token for an existing Live Activity session. |
| `PATCH`| `/register/rename-session` | Updates the activity ID for a session (used for restarts).      |
| `POST` | `/update`                  | Receives state updates from the client (e.g., after feeding).   |
| `GET`  | `/pets/:petID`             | Retrieves the current state (hunger, happiness) for a pet.      |
| `POST` | `/decay`                   | Triggers the periodic decay of all pets' stats.                 |
| `POST` | `/end`                     | Ends a Live Activity session.                                   |
| `DELETE`| `/pets/:petID`            | Deletes all data associated with a specific pet.                |


---

## How It Works

1.  **Adoption**: A user selects a pet in the iOS app. The app sends a request to the `/register` endpoint, creating a new pet record in the backend database.
2.  **Start Live Activity**: The user taps "Start Live Activity". The iOS app uses `ActivityKit` to start the activity and receives a unique push token from Apple.
3.  **Token Registration**: The app sends this push token to the `/register/token` endpoint on the backend, which saves it to the database, linking the device to the pet.
4.  **Interaction**: When the user interacts with the Live Activity (e.g., taps "Feed"), the `PetIntents.swift` file handles the action, immediately updates the UI for a responsive feel, and sends a debounced request to the `/update` endpoint on the backend.
5.  **State Decay**: A scheduled job (like the GitHub Action in `.github/workflows/decay.yml`) periodically calls the `/decay` endpoint. This causes the backend to slightly decrease happiness and increase hunger for all active pets.
6.  **Push Notifications**: After the state decay, the backend sends a silent push notification via APNs to all devices with an active Live Activity. This push contains the updated pet state, which the system uses to refresh the Live Activity UI on the Lock Screen and Dynamic Island.

---

## License

This project is licensed under the terms of the license agreement in the `LICENSE.txt` file.

