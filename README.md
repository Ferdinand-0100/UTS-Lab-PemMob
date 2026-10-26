# Quiz Master

A Flutter-based mobile quiz application built following clean architecture and industry-standard software practices.

## Architecture

The project uses a layered clean-architecture layout to keep domain logic independent of data and UI concerns:

```
lib/
  main.dart                      Entry point; wraps app in ProviderScope
  app.dart                       MaterialApp.router config
  core/
    constants/                   App-wide constants
    theme/                       Material 3 theme
    errors/                      Sealed Failure hierarchy
    utils/                       Result (Either) type
  data/
    models/                      DTOs with fromJson/toJson
    datasources/local/           Bundled-JSON data source
    repositories/                Repository implementation
  domain/
    entities/                    Pure business objects
    repositories/                Abstract contracts
    usecases/                    One class per use case
  presentation/
    providers/                   Riverpod state notifiers
    routes/                      GoRouter configuration
    pages/                       Home, QuizPlay, QuizResult
```

### Key decisions

- **Clean Architecture**: `domain` defines contracts (entities + abstract repositories); `data` implements them; `presentation` consumes use cases via Riverpod providers. Dependency direction is always presentation -> domain <- data.
- **Riverpod** for dependency injection and state management, exposing providers as the seam between layers. Tests can override providers with `ProviderContainer(overrides: ...)`.
- **go_router** for declarative, named navigation with path parameters.
- **Repository pattern** with an in-memory-cached implementation backed by a bundled JSON asset. Swapping in a REST API only requires a new data source and repository implementation; the domain layer is untouched.
- **Result type** (`Success`/`FailureResult`) makes success/failure paths explicit in signatures rather than relying on exceptions.
- **Use cases** encapsulate single-responsibility operations so business logic is reusable and testable in isolation.

## Getting started

```bash
flutter pub get
flutter run
```

Run tests:

```bash
flutter test
```

Analyze code:

```bash
flutter analyze
```

## Features

- Browse a list of quizzes.
- Play a quiz one question at a time with a progress indicator.
- See a score breakdown with per-question correctness.
- Bundled JSON data source, ready to be swapped for a remote API.

## Adding a new quiz

Append a new object to `assets/data/quizzes.json` following the existing shape (id, title, description, questions[]).
