# persis_app

Flutter app for `Iuran Pemuda Persis`.

## `/lib` structure

### App entry

- `lib/main.dart`: app bootstrap, initializes Flutter, Hive, and starts `MyApp`.
- `lib/app/app.dart`: root `MaterialApp` setup.
- `lib/app/routes.dart`: central route names and temporary page wiring.

### Core

- `lib/core/network/api_client.dart`: shared HTTP client wrapper for `GET/POST/PUT/DELETE`.
- `lib/core/network/api_result.dart`: simple success/failure result wrapper for API responses.
- `lib/core/storage/hive_service.dart`: local box initialization and generic Hive read/write helpers.
- `lib/core/storage/secure_storage_service.dart`: secure token/session storage wrapper.
- `lib/core/widgets/offline_warning_banner.dart`: reusable offline state banner widget.

### Helpers and services

- `lib/helpers/auth_helper.dart`: session helpers on top of secure storage.
- `lib/helpers/app_navigation_helper.dart`: small abstraction over Flutter navigation calls.
- `lib/helpers/object_id_helper.dart`: generates local temporary IDs for offline/local records.
- `lib/services/access_control_service.dart`: role-based access checks for approval/payment flows.

### Features

- `lib/features/anggota/`: feature module example using feature-first structure.
- `lib/features/anggota/data/models/`: data models for anggota.
- `lib/features/anggota/data/datasources/`: local and remote data sources.
- `lib/features/anggota/data/repositories/`: repository layer that should coordinate datasource access.
- `lib/features/anggota/presentation/`: UI/controller layer for anggota screens.
- `lib/features/anggota/presentation/widgets/`: feature-specific reusable widgets such as `anggota_card.dart`.

## Developer note

Current implemented foundation is mostly in `app`, `core`, `helpers`, and `services`. Most files under `lib/features/anggota` are still scaffolding/placeholders and can be used as the pattern for future feature modules.
