# Farm OS — Mobile App (Sprint 1: Foundation, Sprint 2: Farm & Dashboard)

Flutter client for Farm OS. Talks to the NestJS backend built in Stage 3.

## Sprint 2 (this delivery) — Farm Management & Dashboard

Built on top of Sprint 1's foundation without introducing a second state
management, networking, or storage architecture -- everything below reuses
`ApiClient`, `Result`/`AppFailure`/`ErrorMapper`, `LocalStorageService`, and
the existing Riverpod + go_router patterns.

**New:**
- `FarmModel` / `CreateFarmInput` / `UpdateFarmInput` -- fields verified
  against the actual Stage 3 Prisma schema and DTOs, not guessed
- Farms data layer: `FarmsRemoteDataSource` (uses the existing `ApiClient`,
  no second Dio instance) + `FarmsRepository` (same `Result` pattern as auth)
- `FarmsController` / `FarmsState`: loads the user's farms and reconciles
  the locally stored `activeFarmId` against what the backend actually
  returns (never trusts a stale local value) -- auto-clears an invalid
  stored id, and auto-selects when the farmer has exactly one farm
- `CreateFarmController` / `EditFarmController`: mirror the existing
  `LoginController`/`RegisterController` pattern exactly (idle → submitting
  → success/error), rather than inventing a new state shape
- Screens: Farm Onboarding (Create Farm), Farm Selection, Farm Dashboard
  (shell only -- see below), Farm Details, Edit Farm, Farm Switcher (bottom
  sheet)
- Router: farm-gated redirect logic layered on top of the unchanged Sprint 1
  auth redirect logic (unauthenticated → auth stack; authenticated + no
  farms → onboarding; authenticated + farms, none active → selection;
  active farm → dashboard)
- `FailureType.forbidden` added to the existing error model, so a 403
  ("You don't have access to this farm") is now distinct from a 401
  ("Your session has expired") -- previously both were conflated under
  `unauthorized`

**Deliberately NOT built (per the Sprint 2 scope boundary):** livestock,
feed, drugs, equipment, finance, reports, notifications, alerts, audit UI,
offline sync engine. The dashboard's module cards for these are shown as
disabled "Coming soon" placeholders, not fake screens.

**A backend limitation, not invented around:** there is no `/auth/me`
endpoint yet, so a locally stored refresh token is treated as "probably
still authenticated" only until the first real authenticated call (loading
farms, right after login) either succeeds or 401s and forces a logout via
the existing `ApiClient` refresh-failure path. This is flagged as
recommended Sprint 3 backend work, not silently worked around.

---

## Sprint 1 — Foundation

## ⚠️ Important: unverified in this environment

This code was written in a sandbox with **no Flutter/Dart SDK installed and no
network access to pub.dev** -- so unlike the backend (which I could partially
verify), I could not run `flutter pub get`, `flutter analyze`, or `flutter
test` against this code at all, in either Sprint 1 or Sprint 2.

What I could do, and did: brace/paren balance checks and a small Python
script that verifies every relative and package import actually resolves to
a real file, across all 65 files. **This caught two genuine bugs left over
from Sprint 1** (wrong relative-import depth in `auth_providers.dart` and
`form_submission_state.dart`) that my earlier manual review missed, plus a
syntax typo I introduced while writing this sprint's tests -- all now fixed
and re-verified. This is real signal, but it is still not a substitute for
the actual Dart analyzer, which checks types, not just import paths.
**Please run the commands below and treat the first `flutter analyze` pass
as expected/normal**, then share any errors it turns up and I'll fix them
immediately.

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

**Sprint 1 flow (auth only):**
1. Launch the app -> Splash -> Login screen (no session yet)
2. Tap **Register** -> create an account

**Sprint 2 flow (continues from registration):**
3. You should land on **Farm Onboarding** ("Let's set up your farm") since
   a brand-new account has zero farms
4. Fill in a farm name (only field required) and tap **Create Farm**
5. You should land on the **Dashboard** showing that farm's name, active
   immediately -- no manual farm-ID entry, no extra selection step
6. Tap **Farm Details** -> confirm the fields you entered display correctly,
   and any field you left blank is simply absent (not shown as "null")
7. Tap **Edit Farm**, change the location, save -> confirm the dashboard/
   details reflect the change immediately
8. Tap the farm name in the app bar (or **Switch Farm**) -> with only one
   farm this sheet will just show that one farm marked active; creating a
   second farm via the Farm Selection screen's "+" button lets you test
   actually switching
9. Tap the logout icon -> back to Login
10. Log back in with the same credentials -> should land directly on the
    Dashboard with the same farm active (the reconciliation logic in
    `FarmsController.loadFarms()` re-validates and restores it)

If any step fails, the error banner should show a plain-English message --
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
    storage/     SecureStorageService (tokens), LocalStorageService (prefs,
                 including activeFarmId)
    providers/   core_providers.dart -- async-initialized services provided
                 via ProviderScope override at startup
    theme/       AppColors, AppSpacing, AppTheme (Material 3, light/dark)
    utils/       Validators, FormSubmissionState
    widgets/     LoadingIndicator, ErrorView, EmptyStateView, PrimaryButton,
                 AppTextField -- shared across every feature screen
  features/
    auth/        Sprint 1
      data/          models, remote data source, repository
      application/   AuthController (session state) + AuthState
      presentation/  screens + per-form controllers (Login/Register/
                     ForgotPassword/ResetPassword)
    farms/       Sprint 2
      data/          FarmModel/CreateFarmInput/UpdateFarmInput, remote data
                     source, repository
      application/   FarmsController (which farms + which is active) +
                     FarmsState
      presentation/  Onboarding/Selection/Dashboard/Details/Edit screens,
                     FarmCard, FarmSwitcherSheet, and the Create/Edit form
                     controllers
    dashboard/ livestock/ feed/ drugs/ equipment/ finance/
    reports/ notifications/ settings/    <- empty, Sprints 3+
  routing/       app_router.dart (go_router + auth + farm-gated redirect)
  app.dart       MaterialApp.router
  main.dart      entry point (now async -- initializes LocalStorageService)
test/
  core/          validators, error mapper, Result unit tests
  features/farms/  model, repository, controller, and widget tests
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
- **Single farm auto-selected, no forced "select your farm" screen**: not
  explicitly specified in the Sprint 2 brief, but asking a farmer with one
  farm to "select" it is pure friction. Flagged here as a judgment call,
  easy to remove from `FarmsController.loadFarms()` if you'd rather every
  farmer see the selection screen at least once.
- **`farmsControllerProvider` rebuilds on every auth state change**: it
  `ref.watch`es `authControllerProvider`, so logging out and a different
  farmer logging back in on the same device never shows stale farm data --
  this was a deliberate design decision beyond what the brief specified.

## Known gaps / recommended Sprint 3 work

- **No `/auth/me` endpoint on the backend.** Session restoration on cold
  start currently treats "a refresh token exists locally" as tentatively
  authenticated, then relies on the first real API call (loading farms) to
  actually validate it -- if that call 401s, the existing `ApiClient`
  refresh-failure path forces a logout. This works, but a dedicated
  `GET /auth/me` would let the app show the real user profile immediately
  on restore instead of waiting. Documented here rather than invented.
- **No backend endpoint for "leave/delete a farm."** The switcher and
  selection screens only support choosing among existing farms; there's no
  UI for removing one, since `DELETE /farms/:id` doesn't exist yet.
- **Widget tests don't cover `EditFarmScreen` or full router navigation
  end-to-end** (e.g. actually tapping through onboarding -> dashboard via
  go_router). Unit tests cover the underlying logic
  (`FarmsController`, `FarmsRepository`); this is a coverage gap worth
  closing before Sprint 3, not a claim that it's untested-and-fine.

## Next sprint

**Sprint 3**: the first real domain module (Livestock is the natural next
step given the backend's `AnimalMovement`/`Species` tables already exist)
-- per the approved development sequence, once this sprint's farm shell is
confirmed working end-to-end against a live backend.
