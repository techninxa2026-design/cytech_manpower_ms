# Cytech Manpower Management System — Flutter Android v5

The approved Cytech Engineering mobile UI has been implemented as a fully interactive, **offline-only Android prototype**. It uses the real Cytech orange/navy branding and custom icon. No domain, cloud server or database is required to review the workflows.

## Run on Android

```powershell
git pull --ff-only origin main
flutter pub get
flutter analyze --no-fatal-infos
flutter test
flutter run
```

The Android CI workflow also produces an installable debug APK in **GitHub → Actions → Flutter Android CI → Artifacts** when the build passes.

## Features

- Cytech branded splash screen, public registration and sign-in demo screens. Sign-in bypasses verification for this preview. Passwords are not checked, stored, or sent anywhere.
- Admin dashboard, custom five-item floating navigation dock with orange active state, group management, team management, profile access, and quick operations.
- Team creation and editing: multiple registered users can belong to multiple teams.
- Group creation/editing with optional gallery cover; absent image uses a custom illustrated badge.
- Assign team members to group with a date and **Supervisor / Engineer / Member** group role.
- Local group chat for assigned people; highlighted attendance and complaint cards; dedicated Notices, Issues and People tabs.
- Attendance: supervisor and admin record present/absent, individual working hours in 0.5h increments, date, normal 8-hour day and hours over 8 as overtime. Detailed worker-by-worker attendance can be viewed by all assigned group members.
- Public work notices: Admin and any assigned Supervisor can select multiple workers across teams, specify company, work site, date, reporting time and instructions. Only selected members, the publisher and Admin can see the notice.
- Engineer text complaints: assigned engineers create highlighted complaints; Admin and group Supervisor can mark Open, Under Review or Resolved.
- Accounts (Admin only): create/edit registered worker profiles with an agreed hourly wage in BDT; monthly payroll with a month picker and group filter; regular hours/pay, overtime hours/pay, gross wages, worker statements and attendance ledger.
- PDF: generates a multi-page A4 gross wage register and opens Android’s **Share / Save to Files** system dialog via the printing plugin. The file name follows `Cytech_Payroll_YYYY-MM.pdf`.
- Overtime multiplier: configurable by Admin as 1.0×, 1.5× or 2.0×. The default is 1.0× and applies only to newly published reports.

## Accounting rules

For each present worker per attendance shift:

```text
regular_hours = min(hours_worked, 8)
overtime_hours = max(hours_worked - 8, 0)
regular_pay = regular_hours * hourly_rate_at_publication
overtime_pay = overtime_hours * hourly_rate_at_publication * saved_ot_multiplier
gross_pay = regular_pay + overtime_pay
```


- Absent = 0 hours / 0 earnings.
- 8 hours = 1 normal day; 9 hours = 8 regular hours + 1 overtime hour; under 8 hours = partial shift.
- The newest report for each **group + date** is used in the monthly gross totals. Separate group shifts on one date remain separate entries.
- New attendance stores a **wage-rate snapshot** and overtime multiplier. Editing a worker’s current rate does not change published payroll. Legacy reports created before v5 have no snapshot; they fall back to the current rate and should be reviewed.
- The export is an *estimated gross wages register*, not a statutory payslip, payment approval, payment ledger or proof of disbursement.
- No overtime premium beyond 1× is implied by default; establish and verify your real company policy before operational use.

## Local preview accounts

| Username | Demo role |
| --- | --- |
| `admin` | Administrator, Accounts |
| `ayesha` | Supervisor in Industrial Site Alpha |
| `fahim` | Engineer in Site Alpha, Supervisor in Warehouse |
| `nabila` | Supervisor in Project Delta |
| `rafi` | Member |

Enter any password (or leave it blank); sign-in skips verification. Profile contains a demo persona switcher.

## Storage and deployment warning

`shared_preferences` persists local JSON records on the **same device**. It is not a cross-device database. There are no push messages, online authentication, network sync, central payroll approvals, backend role enforcement or server-side data backups. Demo role switching makes access control only illustrative. Do **not** use this version for real employee pay or confidential workforce information.

When moving to a production system, implement authenticated users, a backend and database, server-side authorization, audit trails for wage/attendance edits, and legally compliant payroll validation.

## Key Flutter files

| Path | Purpose |
| --- | --- |
| `lib/core/app_store.dart` | Local models, seed data, roles, attendance, wages, public notices, persistence |
| `lib/core/payroll.dart` | Attendance-to-monthly-gross calculations |
| `lib/core/payroll_pdf.dart` | Offline A4 payroll PDF and Android share/save |
| `lib/core/cytech_theme.dart` | Brand typography, logo and reusable widgets |
| `lib/screens/entry_flow.dart` | Splash, registration and sign-in demo |
| `lib/screens/main_shell.dart` | Premium dock, dashboard, groups, teams, profile |
| `lib/screens/public_notices.dart` | Work notice feed, details and publishing workflow |
| `lib/screens/accounts_page.dart` | Admin payroll overview, worker wage edits, ledger and policy |
| `lib/screens/group_room.dart` | Chat, attendance-hours form, notices and engineer complaints |
| `lib/screens/management_pages.dart` | Team, group and group-member editors |
| `test/widget_test.dart` | Role, payroll, duplicate-date, PDF and widget smoke tests |
