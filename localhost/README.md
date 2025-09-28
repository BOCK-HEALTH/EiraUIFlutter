# Eira Health Assistant - Local Development Guide

This folder contains resources and notes for running the Eira application in a local development environment. The instructions below are for running the full stack (Flutter frontend and Node.js backend) on a single machine.

## Prerequisites

1.  **Flutter SDK:** For running the frontend.
2.  **Node.js & npm:** For running the backend server.
3.  **PostgreSQL:** A local PostgreSQL database instance must be installed and running.
4.  **Code Editor:** Visual Studio Code is recommended.

## Running the Backend Server Locally

1.  **Navigate to the backend project directory** (e.g., `EiraFlutterBackend`).

2.  **Install dependencies:**
    ```bash
    npm install
    ```

3.  **Set up the `.env` file:**
    *   Create a file named `.env` in the root of the backend directory.
    *   Populate it with your credentials. For local development, this will point to your local PostgreSQL instance.

    **Example `.env` for local development:**
    ```
    # --- DATABASE ---
    DATABASE_URL="postgresql://YOUR_LOCAL_USER:YOUR_LOCAL_PASSWORD@localhost:5432/eira_db"

    # --- JWT SECRET ---
    JWT_SECRET="a-long-and-random-secret-for-development"

    # --- AWS (Optional) ---
    # You can use test credentials or a tool like MinIO for local S3 simulation.
    AWS_ACCESS_KEY_ID="..."
    AWS_SECRET_ACCESS_KEY="..."
    AWS_REGION="..."
    S3_BUCKET_NAME="..."
    ```

4.  **Set up the Database:**
    *   Ensure your local PostgreSQL server is running.
    *   Create a new database (e.g., `eira_db`).
    *   Run the setup script to create the necessary tables:
        ```bash
        node setupDatabase.js
        ```

5.  **Start the Server:**
    ```bash
    npm start 
    # Or use a tool like nodemon for automatic restarts:
    # npm install -g nodemon
    # nodemon server.js
    ```
    The backend server will now be running, typically on `http://localhost:8080`.

## Running the Flutter Frontend Locally

1.  **Navigate to the Flutter project root directory.**

2.  **Ensure the Backend URL is Correct:**
    *   Open `lib/api_service.dart`.
    *   Verify that the `_baseUrl` variable is pointing to your local backend server:
        ```dart
        final String _baseUrl = "http://localhost:8080";
        ```

3.  **Run the App:**
    *   Select your desired device (e.g., Chrome for web, or an Android/iOS simulator).
    *   Run the application from your IDE or the command line:
        ```bash
        flutter run
        ```

The application will launch and connect to your local backend, allowing you to test the full stack on your machine.
