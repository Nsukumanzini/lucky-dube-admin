# Lucky Dube — Administration web application

A separate Flutter frontend developed and owned by **Optimal Growth Technologies SA**. The administrator workspace is independent of the learner and teacher applications. It has its own project, deployment and local storage key (`lucky_dube_admin_v1`). No backend or cross-app synchronisation is implemented.

Hosted application: https://lucky-dube-admin.vercel.app/

Source repository: https://github.com/Nsukumanzini/lucky-dube-admin

## Sign in

Administrator number: **A1001**
Password: **Learn123!**
Fictional profile: Nomsa Mthembu, School administrator. Teacher and learner credentials cannot sign in here. Remember me restores the local session. English and isiZulu are available before sign-in and throughout the workspace.

## Run and build

Verified toolchain: Flutter 3.50.1 stable / Dart 3.14.0.

```sh
flutter pub get
flutter run -d chrome

dart format .
flutter analyze
flutter test
flutter build web --release --no-web-resources-cdn --no-wasm-dry-run
python3 -m http.server 8080 --directory build/web
```

The web release bundles fonts, icons, original illustrations, application translations and rendering assets. Application operations use local data only. A hosted app needs an initial load; offline reload after closing the browser is not guaranteed because no service-worker installation is claimed. No API keys, Firebase, Supabase or external application APIs are used.

## Dashboard design

The professional dashboard adapts the grouped navigation, metric cards, management tables and activity panels from the owner’s [OG Vibes admin source](https://github.com/Nsukumanzini/og-vibes-admin). It adds workspace-wide search, sorted and paginated directories, attendance bars, a review queue, and a school agenda while retaining the local school workflows. See `docs/DESIGN_SOURCE.md` for the source-to-implementation mapping.

## Implemented workflows

- School overview: calculated enrolment/staff/class counts, pending reviews and attendance summary.
- Learners and staff: create and edit records; inactive states; reversible archiving/restoration. Identifiers are stable after creation, and duplicate identifiers are rejected by the create form.
- Academic structure: create classes with grade and capacity, configure subject grades and maintain academic term dates.
- Teaching allocations: assign active teachers, subjects and classes. Duplicate class/subject allocations and invalid grades are rejected.
- Timetable: create/edit weekday slots. Time ranges and class, teacher and room clashes are checked, including allocation changes that would introduce a clash.
- Attendance: review a dated class register and save corrections with a mandatory reason. Changes appear in the activity log. New enrolments and unsaved dates remain unrecorded instead of being treated as present.
- Results and resources review: release or hold submitted records with a review note. Submitted marks and teacher feedback stay read-only. Published-result reports include only released records.
- Notices and events: create drafts, choose class/grade/school audiences and publish local announcements, examinations, rehearsals, performances and other school activities. Newly created classes are available as audiences.
- Support cases: assign a staff member, track open/in-review/resolved states and require a resolution note. Emergency guidance is explicit; no case is delivered to real staff or emergency services.
- Reports: preview/export enrolment, presentation-date attendance and published-result CSV files. CSV escaping and spreadsheet-formula protection are included.
- Activity log: read-only actor, target, action and timestamp history for local mutations. This is a browser-local audit history, not a tamper-proof server ledger.
- School settings: institution name, application display name, academic year and contact details.
- Preferences: language, text size, sign out and confirmed reset of local information.

## Relationships and boundaries

Archiving retains records and IDs. Active allocations and populated classes cannot be orphaned; staff with teaching allocations or unresolved support cases must be reassigned first. Class capacities and learner grades are validated. Subject grade changes cannot invalidate existing allocations. Academic terms cannot overlap. Review actions preserve submitted mark values. Attendance changes require a complete current roster and a correction reason.

All people, scores and school records are fictional fixtures. Do not enter real sensitive information. No official school endorsement is implied. Creating a learner or staff record here does **not** create a login in either separate application. Publishing notices or results updates this browser only. There are no live emails, messages, account invitations, password provisioning, push services, fees or payments.

Administrator sign-in is a local frontend mechanism. Production security must be implemented on a future backend; do not use this client as a security boundary for real records. No administrative permissions in external systems are granted by this app.

## Architecture and future integration

- `lib/data/admin_repository.dart`: immutable typed records, relationship rules, local authentication, persistence, audit history and report generation.
- `lib/data/schemas.dart`: feature-specific editor field definitions and reference relationships.
- `lib/app`: GoRouter authentication redirect, Material 3 light theme and bundled localisation.
- `lib/features`: adaptive primary workspace, full-screen editors, record review/detail screens, school settings and attendance registers.
- `lib/shared/components`: responsive pages, navigation components, reusable cards, language selector and original vector artwork.

Riverpod injects the repository. `AdminRepository` defines core operations and the current local implementation provides the remaining query/report helpers. A backend integration should expand that contract to typed asynchronous operations, enforce server-side RBAC/validation, implement invitation/reset workflows, and connect shared identities and events across the three independent frontends. Staff/learner data must not be synchronised by sharing browser preferences or embedding privileged credentials in the apps.

Translations are maintained in `lib/app/localization/zu.json`. Run `python3 tool/generate_catalog.py` after editing, then format the generated Dart catalogue. Unknown authored content is displayed in its entered language. Ask an isiZulu-speaking educator to review school-specific terminology before broader use.

See `docs/VALIDATION.md` for checks actually run. Only web is targeted; no native platform build success is claimed.
