# TrustRAG — 구현 로드맵

> 각 Phase 완료 후 TRUSTRAG.md의 "현재 진행 단계" 섹션을 업데이트하세요.

---

## Phase 0 — 프로젝트 초기 설정 ✅

- [x] GitHub 저장소 `TrustRAG` 생성
- [x] 폴더 구조 생성 (db/, n8n/, docs/, work-logs/)
- [x] TRUSTRAG.md 작성 (Claude/Cursor 공용 컨텍스트)
- [x] ROADMAP.md 작성
- [x] WORK_HISTORY.md 작성
- [ ] .env.example 작성
- [ ] Supabase 새 프로젝트 생성 (사용자 직접)
- [ ] TRUSTRAG.md에 Supabase 정보 기입

---

## Phase 1 — DB 스키마 (Supabase) 🔲

### 생성할 테이블
| 파일 | 내용 |
|------|------|
| `db/01_tables.sql` | companies, users, categories, user_category_access, files, audit_logs |
| `db/02_rls.sql` | Row Level Security 정책 (company_id 기반 격리) |
| `db/03_functions.sql` | match_documents_* RPC 함수 (권한 필터링 포함) |
| `db/04_seed.sql` | super_admin 계정, 샘플 데이터 |

### 체크리스트
- [ ] `db/01_tables.sql` 작성
- [ ] `db/02_rls.sql` 작성
- [ ] `db/03_functions.sql` 작성
- [ ] `db/04_seed.sql` 작성
- [ ] Supabase에 SQL 실행 (Management API 또는 대시보드)
- [ ] pgvector extension 활성화 확인
- [ ] documents_{category} 테이블 구조 확정

---

## Phase 2 — 인증/권한 n8n 워크플로우 🔲

### 워크플로우: `TrustRAG-Auth`
**Webhook**: `POST /webhook/trustrag/auth`

```
Webhook → Validate API Key (Supabase users 조회)
        → Load User Permissions (user_category_access JOIN categories)
        → Return { user, company_id, allowed_categories[] }
```

### 체크리스트
- [ ] n8n에 TrustRAG-Auth 워크플로우 생성
- [ ] Supabase users 테이블 조회 노드 설정
- [ ] user_category_access 권한 조회 노드 설정
- [ ] 역할별 응답 분기 (super_admin은 전체 허용)
- [ ] Audit Log: login 이벤트 기록
- [ ] n8n/01_auth.json 백업

---

## Phase 3 — RAG 채팅 워크플로우 🔲

### 워크플로우: `TrustRAG-Chat`
**Webhook**: `POST /webhook/trustrag/chat`

```
Webhook
  → TrustRAG-Auth (권한 확인)
  → Check Category Access (요청 category가 허용 목록에 있는지)
  → Get Query Embedding (OpenAI)
  → Search Source Docs (Supabase RPC, company_id + category_id 필터 강제)
  → Extract Sources
  → Build System Prompt (카테고리별 역할)
  → RAG AI Agent (GPT-4.1 + 메모리)
  → Deduct Token
  → Write Audit Log (action=search, query, response_summary)
  → Return Response { success, response, tokens_remaining, sources }
```

### 핵심: 권한 필터링 메타데이터
```json
{
  "filter": {
    "company_id": "{{ company_id }}",
    "category_id": "{{ category_id }}"
  }
}
```

### 체크리스트
- [ ] n8n에 TrustRAG-Chat 워크플로우 생성
- [ ] Auth 서브워크플로우 연동
- [ ] company_id 강제 필터 적용
- [ ] Audit Log: search 이벤트 기록
- [ ] 토큰 차감 로직 (Supabase users.tokens_remaining 업데이트)
- [ ] n8n/02_chat.json 백업

---

## Phase 4 — 파일 업로드 워크플로우 🔲

### 워크플로우: `TrustRAG-Upload`
**Webhook**: `POST /webhook/trustrag/upload`

```
Webhook
  → TrustRAG-Auth (group_admin 이상만 허용)
  → Check Upload Permission (해당 category 업로드 권한)
  → Base64 → Binary
  → Upload to Google Drive (경로: TrustRAG/{company}/{category}/{file})
  → Supabase Vector Store (임베딩 생성 + 저장)
  → Save File Metadata (files 테이블: file_id, drive_url, company_id, category_id)
  → Write Audit Log (action=upload)
  → Return Response
```

### 체크리스트
- [ ] n8n에 TrustRAG-Upload 워크플로우 생성
- [ ] 업로드 권한 확인 (group_admin 이상)
- [ ] Google Drive 경로 구조화 (TrustRAG/{company}/{category}/)
- [ ] files 테이블에 메타데이터 저장
- [ ] Audit Log: upload 이벤트 기록
- [ ] n8n/03_upload.json 백업

---

## Phase 5 — 프론트엔드 🔲

**배포 경로**: office-ai.app/trust/

### 페이지 구성
| 파일 | 설명 |
|------|------|
| `trust/index.html` | 로그인/API키 입력 |
| `trust/chat.html` | RAG 채팅 (권한별 카테고리 표시) |
| `trust/admin.html` | Company Admin 관리 페이지 |
| `trust/upload.html` | Group Admin 파일 업로드 |

### 체크리스트
- [ ] office-ai 저장소에 /trust/ 폴더 생성
- [ ] trust/index.html (로그인)
- [ ] trust/chat.html (채팅, 1차 demo.html 참고)
- [ ] trust/admin.html (권한 관리)
- [ ] trust/upload.html (파일 업로드, 1차 admin-upload.html 참고)

---

## Phase 6 — 감사 로그 + 보안 강화 🔲

### 임시 다운로드 URL
```
클라이언트 요청 → TrustRAG-Download Webhook
  → 권한 확인 (해당 파일 접근 가능?)
  → 임시 토큰 생성 (유효 10분, audit_logs에 기록)
  → 서명된 임시 URL 반환
  → Audit Log: download 이벤트 (IP, User, File, Timestamp)
```

### 관리자 감사 로그 뷰
- Company Admin: 자사 유저 활동 조회
- Super Admin: 전체 시스템 로그 조회

### 체크리스트
- [ ] TrustRAG-Download 워크플로우 (임시 URL 생성)
- [ ] Audit Log 조회 API
- [ ] 관리자 페이지에 로그 뷰 추가
- [ ] IP 기록 로직

---

## 마일스톤 요약

| 마일스톤 | 포함 Phase | 결과물 |
|----------|-----------|--------|
| M1: 백엔드 기반 완성 | Phase 1 + 2 | DB + 인증 API 동작 |
| M2: 채팅 MVP | Phase 3 | 권한 기반 RAG 채팅 동작 |
| M3: 업로드 + 프론트 | Phase 4 + 5 | 전체 사용 가능한 시스템 |
| M4: 보안 완성 | Phase 6 | 감사 로그 + 임시 URL |
