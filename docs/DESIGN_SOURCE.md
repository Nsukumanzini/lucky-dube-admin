# OG Vibes administrator design adaptation

Reference source: https://github.com/Nsukumanzini/og-vibes-admin
Reference revision: `871c305423a94e9468aea40f05d59a20e58ca249`.

The repository was inspected at the owner's request. Its `src/App.tsx`, `src/components/Overview.tsx` and `src/styles.css` informed the Lucky Dube dashboard. The source repository remains unchanged.

| OG Vibes pattern | Lucky Dube implementation |
| --- | --- |
| Grouped sidebar and account footer | `lib/shared/components/admin_shell.dart`; school-specific navigation and profile |
| Breadcrumb toolbar and management search | Adaptive toolbar and full-screen `/search` route, including local record search |
| Eight compact metric cards | `lib/features/dashboard/admin_dashboard.dart`; counts and attendance from the local repository |
| Communication spotlight and shortcuts | Targeted notices, enrolment, school events and reports |
| Activity and operational panels | Local administrator history, attendance by class, review queue and published agenda |
| Searchable management tables | Desktop record directory with sorting, status filters and pagination; touch-friendly cards on mobile |

The React/TypeScript presentation patterns were reimplemented in Flutter, retaining Lucky Dube's existing repository, validation rules, routes and local state. The theme uses light surfaces, restrained blue/cyan/violet accents and locally rendered artwork. Short entrance motion respects reduced-motion preferences. No OG Vibes backend, Supabase connection, worker, keys, remote fonts, identities, emergency tooling, or other live services were imported.

Existing saved Lucky Dube information continues using `lucky_dube_admin_v1`. English and isiZulu labels are bundled in the app.
