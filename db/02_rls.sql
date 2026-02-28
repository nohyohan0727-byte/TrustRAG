-- ============================================================
-- TrustRAG DB 스키마 — 02_rls.sql
-- Row Level Security: company_id 기준 테넌트 격리
-- ============================================================

-- RLS 활성화
ALTER TABLE companies              ENABLE ROW LEVEL SECURITY;
ALTER TABLE users                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories             ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_category_access   ENABLE ROW LEVEL SECURITY;
ALTER TABLE files                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs             ENABLE ROW LEVEL SECURITY;

-- ── companies ────────────────────────────────────────────────
-- Service Role은 전체 접근 (n8n에서 service key 사용)
CREATE POLICY "service_all_companies" ON companies
  FOR ALL TO service_role USING (true) WITH CHECK (true);

-- ── users ────────────────────────────────────────────────────
CREATE POLICY "service_all_users" ON users
  FOR ALL TO service_role USING (true) WITH CHECK (true);

-- ── categories ───────────────────────────────────────────────
CREATE POLICY "service_all_categories" ON categories
  FOR ALL TO service_role USING (true) WITH CHECK (true);

-- ── user_category_access ─────────────────────────────────────
CREATE POLICY "service_all_uca" ON user_category_access
  FOR ALL TO service_role USING (true) WITH CHECK (true);

-- ── files ────────────────────────────────────────────────────
CREATE POLICY "service_all_files" ON files
  FOR ALL TO service_role USING (true) WITH CHECK (true);

-- ── audit_logs ───────────────────────────────────────────────
CREATE POLICY "service_all_audit" ON audit_logs
  FOR ALL TO service_role USING (true) WITH CHECK (true);

-- ============================================================
-- 주의: n8n은 항상 service_role key로 Supabase에 접근합니다.
-- 위 정책은 service_role에게 전체 접근을 허용하되,
-- 애플리케이션 레벨(n8n 코드)에서 company_id 필터를 강제합니다.
--
-- 문서 테이블(tr_*) 은 카테고리 생성 시 아래 패턴으로 RLS 추가:
-- ALTER TABLE tr_{company}_{cat} ENABLE ROW LEVEL SECURITY;
-- CREATE POLICY "service_all" ON tr_{company}_{cat}
--   FOR ALL TO service_role USING (true) WITH CHECK (true);
-- ============================================================
