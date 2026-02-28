-- ============================================================
-- TrustRAG DB 스키마 — 04_seed.sql
-- 초기 데이터: Super Admin + 첫 번째 회사
-- ============================================================

-- ── 1. Super Admin 회사 생성 ─────────────────────────────────
INSERT INTO companies (id, name, slug, plan)
VALUES (
  '00000000-0000-0000-0000-000000000001',
  'JK Networks',
  'jknetworks',
  'enterprise'
);

-- ── 2. Super Admin 계정 생성 ─────────────────────────────────
-- api_key는 배포 전 반드시 변경할 것
INSERT INTO users (
  id, company_id, email, name, role, api_key,
  tokens_remaining, tokens_total, is_active
) VALUES (
  '00000000-0000-0000-0000-000000000010',
  '00000000-0000-0000-0000-000000000001',
  'admin@jknetworks.co.kr',
  '노진광',
  'super_admin',
  'trust_super_CHANGE_THIS_KEY',  -- ← 반드시 변경
  99999,
  99999,
  true
);

-- ── 확인 쿼리 ────────────────────────────────────────────────
-- SELECT * FROM companies;
-- SELECT id, email, role, api_key FROM users;
