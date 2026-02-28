-- ============================================================
-- TrustRAG DB 스키마 — 01_tables.sql
-- 실행 순서: 01 → 02 → 03 → 04
-- Supabase SQL Editor 또는 Management API로 실행
-- ============================================================

-- pgvector 확장 활성화 (Supabase에서 기본 제공)
CREATE EXTENSION IF NOT EXISTS vector;

-- ── 1. 회사(테넌트) ──────────────────────────────────────────
CREATE TABLE companies (
  id          uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  name        text NOT NULL,
  slug        text UNIQUE NOT NULL,       -- URL 식별자 (예: jknetworks)
  is_active   boolean DEFAULT true,
  plan        text DEFAULT 'starter',    -- starter / pro / enterprise
  created_at  timestamptz DEFAULT now(),
  updated_at  timestamptz DEFAULT now()
);

-- ── 2. 사용자 ────────────────────────────────────────────────
CREATE TABLE users (
  id                uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  company_id        uuid REFERENCES companies(id) ON DELETE CASCADE,
  email             text UNIQUE NOT NULL,
  name              text,
  role              text NOT NULL CHECK (role IN ('super_admin','company_admin','group_admin','user')),
  api_key           text UNIQUE NOT NULL,
  tokens_remaining  int DEFAULT 100,
  tokens_total      int DEFAULT 100,
  expires_at        timestamptz,
  is_active         boolean DEFAULT true,
  created_by        uuid REFERENCES users(id),
  last_login_at     timestamptz,
  created_at        timestamptz DEFAULT now(),
  updated_at        timestamptz DEFAULT now()
);

-- ── 3. 카테고리 (회사별) ─────────────────────────────────────
CREATE TABLE categories (
  id           uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  company_id   uuid REFERENCES companies(id) ON DELETE CASCADE,
  name         text NOT NULL,             -- 표시명 (예: KS인증)
  table_name   text NOT NULL,             -- Supabase 문서 테이블명 (예: tr_ks_cert_jknetworks)
  description  text,
  is_active    boolean DEFAULT true,
  created_by   uuid REFERENCES users(id),
  created_at   timestamptz DEFAULT now(),
  UNIQUE(company_id, table_name)
);

-- ── 4. 유저-카테고리 접근 권한 ──────────────────────────────
CREATE TABLE user_category_access (
  id           uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id      uuid REFERENCES users(id) ON DELETE CASCADE,
  category_id  uuid REFERENCES categories(id) ON DELETE CASCADE,
  can_upload   boolean DEFAULT false,     -- 업로드 권한 (group_admin 이상)
  granted_by   uuid REFERENCES users(id),
  created_at   timestamptz DEFAULT now(),
  UNIQUE(user_id, category_id)
);

-- ── 5. 파일 메타데이터 ──────────────────────────────────────
CREATE TABLE files (
  id              uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  company_id      uuid REFERENCES companies(id) ON DELETE CASCADE,
  category_id     uuid REFERENCES categories(id) ON DELETE CASCADE,
  file_name       text NOT NULL,
  file_path       text,                   -- Drive 경로: TrustRAG/{company}/{category}/{file}
  drive_file_id   text,
  drive_url       text,
  file_size       bigint,
  mime_type       text,
  upload_user_id  uuid REFERENCES users(id),
  is_active       boolean DEFAULT true,
  created_at      timestamptz DEFAULT now()
);

-- ── 6. 감사 로그 (Audit Log) ────────────────────────────────
CREATE TABLE audit_logs (
  id               bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id          uuid REFERENCES users(id),
  company_id       uuid REFERENCES companies(id),
  action           text NOT NULL CHECK (action IN (
                     'login', 'search', 'download', 'upload',
                     'permission_grant', 'permission_revoke', 'user_create'
                   )),
  category_id      uuid REFERENCES categories(id),
  file_id          uuid REFERENCES files(id),
  query_text       text,                  -- 검색 질문 (action=search)
  response_summary text,                 -- 답변 앞 300자
  session_id       text,
  ip_address       text,
  user_agent       text,
  created_at       timestamptz DEFAULT now()
);

-- ── 7. 문서 테이블 템플릿 (카테고리별 동적 생성) ────────────
-- 실제 문서 테이블은 카테고리 생성 시 동적으로 만듦
-- 네이밍 규칙: tr_{company_slug}_{category_slug}
-- 예시 테이블 (직접 실행하지 말고, 카테고리 생성 API가 자동 생성):
--
-- CREATE TABLE tr_jknetworks_ks_cert (
--   id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
--   company_id uuid NOT NULL,
--   category_id uuid NOT NULL,
--   content    text NOT NULL,
--   metadata   jsonb DEFAULT '{}',
--   embedding  vector(1536),
--   created_at timestamptz DEFAULT now()
-- );

-- ── 인덱스 ──────────────────────────────────────────────────
CREATE INDEX idx_users_api_key       ON users(api_key);
CREATE INDEX idx_users_company_id    ON users(company_id);
CREATE INDEX idx_categories_company  ON categories(company_id);
CREATE INDEX idx_uca_user_id         ON user_category_access(user_id);
CREATE INDEX idx_uca_category_id     ON user_category_access(category_id);
CREATE INDEX idx_files_company       ON files(company_id);
CREATE INDEX idx_files_category      ON files(category_id);
CREATE INDEX idx_audit_user          ON audit_logs(user_id);
CREATE INDEX idx_audit_company       ON audit_logs(company_id);
CREATE INDEX idx_audit_action        ON audit_logs(action);
CREATE INDEX idx_audit_created       ON audit_logs(created_at DESC);
