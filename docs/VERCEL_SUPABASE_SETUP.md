# Vercel + Supabase setup

This app is being moved away from Firebase so it can match the ProjectOS style:

- Flutter web app hosted on Vercel
- Vercel API routes as the server-side gateway
- Supabase Postgres as the database
- OpenAI API called only from the Vercel server side

## 1. Create Supabase tables

Open the Supabase SQL editor and run:

```text
supabase/migrations/001_community_log_initial.sql
```

## 2. Set Vercel environment variables

In the Vercel project settings, add:

```text
SUPABASE_URL
SUPABASE_SERVICE_ROLE_KEY
OPENAI_API_KEY
OPENAI_MODEL
```

`OPENAI_MODEL` is optional. If it is not set, the API uses `gpt-5.5`.

The Vercel build command in `vercel.json` installs Flutter during deployment,
then runs `flutter pub get` and `flutter build web --release`.

## 3. Local Flutter run against Vercel API

After Vercel is deployed, run the Flutter app locally with:

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=https://your-vercel-domain.vercel.app
```

When the app is hosted on the same Vercel domain as the API, `API_BASE_URL` can be omitted.

## 4. Important security note

Do not put `SUPABASE_SERVICE_ROLE_KEY` or `OPENAI_API_KEY` into Flutter code.
Those values belong only in Vercel environment variables.
