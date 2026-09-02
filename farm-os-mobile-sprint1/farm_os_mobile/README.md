# Farm OS — Mobile App (Sprint 1: Foundation)

Flutter client for Farm OS. Talks to the NestJS backend built in Stage 3.

## ⚠️ Important: unverified in this environment

This code was written in a sandbox with **no Flutter/Dart SDK installed and no
network access to pub.dev** — so unlike the backend (which I could partially
verify), I could not run `flutter pub get`, `flutter analyze`, or `flutter
test` against this code at all. I did a careful manual review (brace/paren
balance across all 40 files, import-path tracing, type-consistency checks on
every cross-file reference), but that is not a substitute for the real
compiler. **Please run the commands below and treat the first `flutter
analyze` pass as expected/normal**, then share any errors it turns up and
I'll fix them immediately.

## Sprint 1 scope (this delivery)

- Project architecture (`core/` + `features/`, per the approved structure)
- Material 3 theme (light + dark) matching the Stage 2 design system tokens
- `go_router` navigation with centralized auth-based redirect logic
- Centralized Dio API client: attaches JWT, auto-refreshes on 401 with
  single-flight de-duplication, retries the original request once
- Secure token storage (`flutter_secure_storage`) — tokens only, never passwords
- Riverpod state management (chosen per "select one and use it consistently")
- Error handling: every raw exception is translated to a farmer-readable
  `AppFailure` before it can reach a screen (see `core/errors/error_mapper.dart`)
- Full **Authentication** feature, end-to-end: Splash → Login/Register →
  (placeholder Home) → Logout, plus Forgot/Reset Password
- Unit tests for validators, error mapping, and the `Result` type

Livestock/Feed/Drugs/Equipment/Finance/Reports/Notifications/Settings are
scaffolded as empty directories under `lib/features/` per the approved
structure, but intentionally have no code yet — those are Sprints 2–7.

## Getting started

```bash
flutter pub get
flutter analyze              # please run this and report anything back to me
flutter test                 # runs the Sprint 1 unit tests
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000   # Android emulator -> host machine
```

If testing against a physical device, replace `10.0.2.2` with your machine's
LAN IP (both device and backend need to be on the same network), e.g.:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.50:3000
```

Make sure the Sprint 1 backend (from Stage 3) is running first:
`docker compose up` in the backend project, or `npm run start:dev` after
`prisma migrate dev` + `prisma db seed`.

## Verifying the vertical slice manually

1. Launch the app → Splash → Login screen (no session yet)
2. Tap **Register** → create an account → you should land on the temporary
   "You're logged in" screen
3. Tap the logout icon → back to Login
4. Log back in with the same credentials → same placeholder screen

If any step fails, the error banner should show a plain-English message —
if you ever see raw JSON or a stack trace on screen, that's a bug in
`ErrorMapper`, please flag it.

## Project structure

```
lib/
  core/
    config/      API base URL, environment
    constants/   storage keys, API endpoint paths
    errors/      AppFailure, ErrorMapper, Result<T>
    network/     ApiClient (the only place HTTP calls are made)
    storage/     SecureStorageService (tokens), LocalStorageService (prefs)
    theme/       AppColors, AppSpacing, AppTheme (Material 3, light/dark)
    utils/       Validators, FormSubmissionState
    widgets/     LoadingIndicator, ErrorView, EmptyStateView, PrimaryButton,
                 AppTextField -- shared across every future feature screen
  features/
    auth/        the only fully-built feature this sprint
      data/          models, remote data source, repository
      application/   AuthController (session state) + AuthState
      presentation/  screens + per-form controllers (Login/Register/
                     ForgotPassword/ResetPassword)
    farm/ dashboard/ livestock/ feed/ drugs/ equipment/ finance/
    reports/ notifications/ settings/    <- empty, Sprints 2-7
  routing/       app_router.dart (go_router + auth redirect)
  app.dart       MaterialApp.router
  main.dart      entry point
test/
  core/          validators, error mapper, Result unit tests
```

## Notes on a few design decisions

- **Riverpod chosen over Bloc**: less boilerplate for this size of app, and
  `StateNotifier` maps cleanly onto the idle/submitting/success/error pattern
  every form in this app needs.
- **No code generation** (no `freezed`/`json_serializable`/`build_runner`):
  models use hand-written `fromJson`/`toJson`. This was a deliberate choice
  given I couldn't run `build_runner` in this sandbox to verify generated
  code — once you've confirmed the app builds, migrating to `freezed` for
  the larger models coming in Sprint 2+ (Livestock, Feed, etc.) is a
  reasonable follow-up if you'd like less boilerplate.
- **Refresh-token race condition**: `ApiClient._refreshInFlight` ensures that
  if multiple requests 401 at nearly the same time, only one refresh call is
  made and all callers await the same result.

## Next sprint

**Sprint 2 — Farm & Dashboard**: farm onboarding (Create Farm screen wired to
`POST /farms`), the real Dashboard (replacing the placeholder), quick actions,
and a notifications summary — per the approved development sequence.
