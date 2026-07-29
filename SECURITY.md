# Security Policy

## Supported version

ConnectUs is under active development. Security fixes are applied to the latest
commit on the `main` branch.

## Reporting a vulnerability

Do not open a public GitHub issue for a vulnerability or suspected credential
exposure. Contact the repository owner privately through the contact method on
their GitHub profile and include:

- A clear description of the issue
- Reproduction steps
- The affected screen, API, table, or policy
- The potential impact
- A suggested fix, when available

Please allow reasonable time for investigation before disclosing the issue.

## Secrets

The Flutter client may contain only the Supabase project URL and publishable
client key. Never commit database passwords, Supabase secret or service-role
keys, signing credentials, Firebase service-account files, or production
environment files.

## Backend controls

Production data must remain protected by Supabase Row Level Security. Database
functions that use `security definer` must validate `auth.uid()`, use a fixed
`search_path`, and grant execution only to the roles that require it.

## Release checks

Before a production release:

1. Run formatting, static analysis, and automated tests.
2. Review dependency updates and platform permissions.
3. Audit Row Level Security policies and database functions.
4. Confirm `.env` and signing files are absent from Git history.
5. Rotate any credential that may have been exposed.
6. Test authentication, account recovery, data isolation, and logout.

