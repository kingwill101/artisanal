# Ormed Fullstack Example: Movie Catalog

This is a comprehensive example of a full-stack application built with **Ormed**, **Shelf**, and **Liquify**.

## Features

- **Ormed ORM**: Database interactions, migrations, and seeding.
- **Shelf Web Server**: Routing, middleware, and request handling.
- **Liquify Templates**: Server-side rendering with Liquid templates.
- **Structured Logging**: Contextual logging for better observability.
- **File Storage**: Local file storage for movie posters.
- **Testing**: Comprehensive test suite including unit, integration, and property-based tests.

## Getting Started

### 1. Install Dependencies

```bash
dart pub get
```

### 2. Run Migrations and Seed Data

```bash
dart run ormed migrate
dart run ormed seed
```

### 3. Run the Server

```bash
dart run bin/server.dart
```

The server will be running at `http://localhost:8080`.

## Project Structure

- `bin/`: Server entry point.
- `lib/src/database/`: Database configuration, migrations, and seeders.
- `lib/src/models/`: Ormed models.
- `lib/src/server/`: Shelf application logic and routes.
- `lib/src/templates/`: Liquid templates.
- `test/`: Comprehensive test suite.

## Documentation

For a detailed walkthrough of how this application was built, check out the [Fullstack Guide](https://ormed.vercel.app/docs/guides/fullstack/ormed-shelf-tutorial).
