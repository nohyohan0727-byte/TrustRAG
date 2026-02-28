-- ============================================================
-- TrustRAG DB 스키마 — 03_functions.sql
-- RPC 함수: 권한 기반 벡터 검색
-- ============================================================

-- ── 1. 사용자 권한 확인 함수 ─────────────────────────────────
-- API Key로 사용자 + 허용 카테고리 목록 반환
CREATE OR REPLACE FUNCTION get_user_permissions(p_api_key text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user users%ROWTYPE;
  v_categories jsonb;
BEGIN
  -- 사용자 조회
  SELECT * INTO v_user
  FROM users
  WHERE api_key = p_api_key AND is_active = true;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', 'Invalid API key');
  END IF;

  -- 만료 확인
  IF v_user.expires_at IS NOT NULL AND v_user.expires_at < now() THEN
    RETURN jsonb_build_object('error', 'API key expired');
  END IF;

  -- 토큰 확인
  IF v_user.tokens_remaining <= 0 THEN
    RETURN jsonb_build_object('error', 'No tokens remaining');
  END IF;

  -- super_admin은 전체 카테고리 접근 허용
  IF v_user.role = 'super_admin' THEN
    SELECT jsonb_agg(jsonb_build_object(
      'category_id', c.id,
      'name', c.name,
      'table_name', c.table_name,
      'can_upload', true
    )) INTO v_categories
    FROM categories c WHERE c.is_active = true;
  ELSE
    -- 일반 사용자: user_category_access 기준
    SELECT jsonb_agg(jsonb_build_object(
      'category_id', c.id,
      'name', c.name,
      'table_name', c.table_name,
      'can_upload', uca.can_upload
    )) INTO v_categories
    FROM user_category_access uca
    JOIN categories c ON c.id = uca.category_id
    WHERE uca.user_id = v_user.id AND c.is_active = true;
  END IF;

  RETURN jsonb_build_object(
    'user_id',           v_user.id,
    'company_id',        v_user.company_id,
    'name',              v_user.name,
    'email',             v_user.email,
    'role',              v_user.role,
    'tokens_remaining',  v_user.tokens_remaining,
    'categories',        COALESCE(v_categories, '[]'::jsonb)
  );
END;
$$;

-- ── 2. 벡터 검색 함수 템플릿 ─────────────────────────────────
-- 카테고리별 문서 테이블(tr_*)에 동일 패턴으로 생성
-- 아래는 예시 (카테고리 생성 시 n8n이 자동 생성)

-- match_documents_{table_name}(query_embedding, company_id, match_count, filter)
-- 예시: match_documents_tr_jknetworks_ks_cert

CREATE OR REPLACE FUNCTION match_documents_template(
  query_embedding  vector(1536),
  p_company_id     uuid,
  match_count      int     DEFAULT 5,
  filter           jsonb   DEFAULT '{}'
)
RETURNS TABLE (
  id          bigint,
  content     text,
  metadata    jsonb,
  similarity  float
)
LANGUAGE plpgsql
AS $$
BEGIN
  -- 실제 구현은 각 테이블별로 생성
  -- company_id 필터는 항상 강제 적용
  RAISE EXCEPTION 'Use table-specific match function';
END;
$$;

-- ── 3. 토큰 차감 함수 ────────────────────────────────────────
CREATE OR REPLACE FUNCTION deduct_token(p_user_id uuid)
RETURNS int
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_remaining int;
BEGIN
  UPDATE users
  SET tokens_remaining = GREATEST(tokens_remaining - 1, 0),
      updated_at = now()
  WHERE id = p_user_id
  RETURNING tokens_remaining INTO v_remaining;

  RETURN v_remaining;
END;
$$;

-- ── 4. 감사 로그 기록 함수 ───────────────────────────────────
CREATE OR REPLACE FUNCTION write_audit_log(
  p_user_id          uuid,
  p_company_id       uuid,
  p_action           text,
  p_category_id      uuid    DEFAULT NULL,
  p_file_id          uuid    DEFAULT NULL,
  p_query_text       text    DEFAULT NULL,
  p_response_summary text    DEFAULT NULL,
  p_session_id       text    DEFAULT NULL,
  p_ip_address       text    DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO audit_logs (
    user_id, company_id, action,
    category_id, file_id,
    query_text, response_summary,
    session_id, ip_address
  ) VALUES (
    p_user_id, p_company_id, p_action,
    p_category_id, p_file_id,
    p_query_text, LEFT(p_response_summary, 300),
    p_session_id, p_ip_address
  );
END;
$$;

-- ── 5. 카테고리별 문서 테이블 + match 함수 동적 생성 ─────────
-- n8n 카테고리 생성 워크플로우에서 호출
CREATE OR REPLACE FUNCTION create_category_table(
  p_table_name  text,
  p_company_id  uuid,
  p_category_id uuid
)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- 문서 테이블 생성
  EXECUTE format('
    CREATE TABLE IF NOT EXISTS %I (
      id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
      company_id  uuid NOT NULL DEFAULT %L,
      category_id uuid NOT NULL DEFAULT %L,
      content     text NOT NULL,
      metadata    jsonb DEFAULT %L,
      embedding   vector(1536),
      created_at  timestamptz DEFAULT now()
    )', p_table_name, p_company_id, p_category_id, '{}');

  -- RLS 활성화
  EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', p_table_name);
  EXECUTE format('
    CREATE POLICY "service_all" ON %I
    FOR ALL TO service_role USING (true) WITH CHECK (true)',
    p_table_name);

  -- 벡터 인덱스 생성
  EXECUTE format('
    CREATE INDEX IF NOT EXISTS %I ON %I
    USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100)',
    p_table_name || '_embedding_idx', p_table_name);

  -- match 함수 생성
  EXECUTE format('
    CREATE OR REPLACE FUNCTION match_documents_%I(
      query_embedding  vector(1536),
      p_company_id     uuid,
      match_count      int  DEFAULT 5,
      similarity_threshold float DEFAULT 0.5
    )
    RETURNS TABLE (id bigint, content text, metadata jsonb, similarity float)
    LANGUAGE plpgsql AS $fn$
    #variable_conflict use_column
    BEGIN
      RETURN QUERY
      SELECT t.id, t.content, t.metadata,
             1 - (t.embedding <=> query_embedding) AS similarity
      FROM %I t
      WHERE t.company_id = p_company_id
        AND 1 - (t.embedding <=> query_embedding) > similarity_threshold
      ORDER BY t.embedding <=> query_embedding
      LIMIT match_count;
    END;
    $fn$', p_table_name, p_table_name);

  RETURN 'Created: ' || p_table_name;
END;
$$;
