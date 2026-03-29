# AntimatterAI Command Hub — Cross-Device Sync Setup

## Quick Start (5 minutes)

### 1. Create a Supabase Project

1. Go to [supabase.com](https://supabase.com) and sign up / sign in
2. Click **New Project**
3. Name it `antimatterai-command-hub`
4. Choose a strong database password (save it somewhere safe)
5. Select a region close to you (e.g., East US)
6. Click **Create new project** — wait ~2 minutes for setup

### 2. Run the Database Schema

1. In your Supabase dashboard, go to **SQL Editor** (left sidebar)
2. Click **New query**
3. Copy the entire contents of `supabase-setup.sql` and paste it
4. Click **Run** — you should see "Success" for all statements

### 3. Configure Authentication

1. Go to **Authentication** → **URL Configuration**
2. Under **Site URL**, enter: `https://antimatter-ai-command-center.vercel.app`
3. Under **Redirect URLs**, add: `https://antimatter-ai-command-center.vercel.app`
4. Go to **Authentication** → **Providers**
5. Make sure **Email** is enabled (it should be by default)
6. Under Email settings, enable **Confirm Email** and **Magic Link**

### 4. Get Your API Keys

1. Go to **Settings** → **API**
2. Copy your **Project URL** (looks like `https://xyzproject.supabase.co`)
3. Copy your **anon public** key (the long one under "Project API keys")

### 5. Update the App

Open `index.html` and find these two lines near the top of the `<script>` section:

```javascript
const SUPABASE_URL = 'YOUR_SUPABASE_URL';
const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY';
```

Replace them with your actual values:

```javascript
const SUPABASE_URL = 'https://xyzproject.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbG...your_actual_key...';
```

### 6. Deploy

Commit and push to GitHub — Vercel will auto-deploy.

```bash
git add -A
git commit -m "Configure Supabase sync"
git push
```

---

## How It Works

- **Sign in**: Users enter their email on the login screen and receive a magic link
- **First sign-in**: Their current local data is uploaded to Supabase as the "hub"
- **Subsequent sign-ins**: Data is loaded from Supabase (cloud wins over local)
- **Real-time sync**: When a teammate edits something, all connected browsers get the update instantly via Supabase Realtime
- **Offline fallback**: If Supabase is down, everything still works locally via localStorage
- **Skip sign-in**: Users can click "Continue without sign-in" for local-only mode

## Adding Team Members

When a new team member signs in with their email for the first time, they'll automatically create their own hub. To share a single hub across the team:

**Option A — Manual (SQL Editor)**:
```sql
-- Find the hub ID (run this first)
SELECT id, hub_name FROM hub_state;

-- Find the new user's ID
SELECT id, email FROM auth.users;

-- Add them to the hub
INSERT INTO hub_members (hub_id, user_id, role)
VALUES ('hub-uuid-here', 'user-uuid-here', 'editor');
```

**Option B** — I can build an "Invite Team" modal into the app UI. Just ask.

## Environment Variables (Alternative)

Instead of hardcoding keys in `index.html`, you can use Vercel environment variables:
1. Go to Vercel → Project Settings → Environment Variables
2. Add `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY`
3. Reference them in the code (requires migrating to a build step)

For a single `index.html` app, the direct approach above is simplest.
