-- ═══════════════════════════════════════════════════════════════
-- AntimatterAI Command Hub — Supabase Schema
-- Run this in the Supabase SQL Editor (Dashboard → SQL Editor)
-- ═══════════════════════════════════════════════════════════════

-- 1. Hub state table — stores the full JSON state, one row per hub
CREATE TABLE IF NOT EXISTS hub_state (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  hub_name TEXT NOT NULL DEFAULT 'AntimatterAI Command Hub',
  state JSONB NOT NULL DEFAULT '{}',
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_by UUID REFERENCES auth.users(id)
);

-- 2. Hub members table — maps users to hubs for team access
CREATE TABLE IF NOT EXISTS hub_members (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  hub_id UUID NOT NULL REFERENCES hub_state(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'editor' CHECK (role IN ('owner', 'editor', 'viewer')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(hub_id, user_id)
);

-- 3. Enable RLS
ALTER TABLE hub_state ENABLE ROW LEVEL SECURITY;
ALTER TABLE hub_members ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies — team members can read/write their hubs

-- hub_members: users can see their own memberships
CREATE POLICY "Users can view own memberships"
  ON hub_members FOR SELECT
  USING (auth.uid() = user_id);

-- hub_members: owners can manage memberships
CREATE POLICY "Owners can manage memberships"
  ON hub_members FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM hub_members hm
      WHERE hm.hub_id = hub_members.hub_id
        AND hm.user_id = auth.uid()
        AND hm.role = 'owner'
    )
  );

-- hub_state: team members can view their hubs
CREATE POLICY "Team members can view hub state"
  ON hub_state FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM hub_members
      WHERE hub_members.hub_id = hub_state.id
        AND hub_members.user_id = auth.uid()
    )
  );

-- hub_state: editors and owners can update hub state
CREATE POLICY "Editors can update hub state"
  ON hub_state FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM hub_members
      WHERE hub_members.hub_id = hub_state.id
        AND hub_members.user_id = auth.uid()
        AND hub_members.role IN ('owner', 'editor')
    )
  );

-- hub_state: anyone authenticated can insert (for first-time setup)
CREATE POLICY "Authenticated users can create hubs"
  ON hub_state FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

-- hub_members: authenticated users can insert their own membership
CREATE POLICY "Users can add themselves to hubs they create"
  ON hub_members FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- 5. Enable Realtime on hub_state for live sync
ALTER PUBLICATION supabase_realtime ADD TABLE hub_state;

-- 6. Index for fast lookups
CREATE INDEX IF NOT EXISTS idx_hub_members_user ON hub_members(user_id);
CREATE INDEX IF NOT EXISTS idx_hub_members_hub ON hub_members(hub_id);
