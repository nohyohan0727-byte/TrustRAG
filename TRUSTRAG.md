# TrustRAG — 프로젝트 컨텍스트

> **이 파일은 Claude Code / Cursor가 대화 시작 시 반드시 읽는 컨텍스트 파일입니다.**
> 새 세션을 시작할 때 이 파일을 먼저 읽고 현재 상태를 파악하세요.

---

## 프로젝트 개요

| 항목 | 내용 |
|------|------|
| **프로젝트명** | TrustRAG |
| **목표** | 기업용 멀티테넌트 계층형 권한 관리 RAG 시스템 |
| **참고 프로젝트** | office-ai RAG 1차 (성공적 완성, 구조 참고) |
| **핵심 차별점** | 멀티테넌트 + 역할 기반 접근제어(RBAC) + 감사 로그(Audit Log) |

---

## 기술 스택

| 레이어 | 기술 | 비고 |
|--------|------|------|
| **DB / 벡터** | Supabase PostgreSQL + pgvector | 새 프로젝트 (1차와 별도) |
| **워크플로우** | n8n Cloud | 기존 인스턴스에 새 워크플로우 추가 |
| **AI / 임베딩** | OpenAI (GPT-4o-mini + text-embedding-ada-002) | HTTP 직접 호출 방식 |
| **파일 저장** | Supabase PostgreSQL (벡터 직접 저장) | Google Drive 불필요 |
| **프론트엔드** | 정적 HTML + Netlify | office-ai.app/trust/ 서브 경로 |
| **소스관리** | GitHub | 저장소: nohyohan0727-byte/TrustRAG |
| **개발 도구** | Claude Code + Cursor (병행) | 단계별 히스토리 공유 |

---

## 역할 체계 (Role Hierarchy)

```
Super Admin
  └── Company Admin (테넌트별 1명 이상)
        └── Group Admin (카테고리별 관리자)
              └── User (최종 사용자)
```

| 역할 | 권한 |
|------|------|
| `super_admin` | 전체 시스템 + 회사(Tenant) 생성/관리 |
| `company_admin` | 자사 카테고리 생성 + 중간관리자/유저 권한 부여 |
| `group_admin` | 부여받은 카테고리에 파일 업로드 + 하위 유저 관리 |
| `user` | 허용된 카테고리 내 문서 검색·질문만 가능 |

---

## 저장소 구조

```
TrustRAG/
├── TRUSTRAG.md          ← 이 파일 (컨텍스트)
├── ROADMAP.md           ← 단계별 구현 계획
├── WORK_HISTORY.md      ← 작업 이력 (Claude/Cursor 공용)
├── .env.example         ← 환경변수 목록 (키값 없이)
├── db/
│   ├── 01_tables.sql    ← 테이블 스키마
│   ├── 02_rls.sql       ← Row Level Security 정책
│   ├── 03_functions.sql ← RPC 함수 (match_documents_*)
│   └── 04_seed.sql      ← 초기 데이터 (super_admin 등)
├── n8n/
│   ├── 01_auth.json          ← 인증/권한 확인 워크플로우
│   ├── 02_chat.json          ← RAG 채팅 워크플로우
│   ├── 03_upload.json        ← 파일 업로드 워크플로우
│   └── 04_admin.json         ← 관리자 API 워크플로우
├── docs/
│   ├── api-reference.md      ← Webhook API 명세
│   └── schema-erd.md         ← DB ERD 설명
└── work-logs/
    └── YYYY-MM-DD-*.md       ← 날짜별 상세 작업 로그
```

---

## Supabase 정보

| 항목 | 값 |
|------|-----|
| **프로젝트 ID** | `ryzkcdvywxblsbyujtfv` |
| **URL** | `https://ryzkcdvywxblsbyujtfv.supabase.co` |
| **Region** | ap-southeast-1 (싱가포르) |
| **Anon Key** | `.env`에서 관리 (TRUSTRAG_SUPABASE_ANON_KEY) |
| **Service Key** | `.env`에서 관리 (TRUSTRAG_SUPABASE_SERVICE_KEY) |
| **DB Password** | `.env`에서 관리 (TRUSTRAG_DB_PASSWORD) |
| **n8n Supabase Cred ID** | `sqACFCNh6c9Vg6iY` |

---

## n8n 워크플로우 현황

| 워크플로우 | ID | 웹훅 경로 | 상태 |
|-----------|-----|-----------|------|
| TrustRAG_Auth | `rDRKlBnQpPNyAcHH` | `POST /trustrag/validate-key` | ✅ 활성화됨 |
| TrustRAG_Chat | `Oo9ThEBXSg3QUv4L` | `POST /trustrag/chat` | ✅ 활성화됨 |
| TrustRAG_Upload | `ZrdgEqchaCSoycyP` | `POST /trustrag/upload` | ✅ 활성화됨 |
| TrustRAG_Admin | `9c5kGAC7xHGXgvtX` | `POST /trustrag/admin` | ✅ 활성화됨 |

### Admin 워크플로우 지원 액션 (`POST /trustrag/admin`)

| 액션 | 설명 | 필요 역할 |
|------|------|----------|
| `create_user` | 신규 유저 생성 (api_key 자동 발급) | company_admin+ |
| `create_category` | 카테고리 생성 + 동적 벡터 테이블 생성 | company_admin+ |
| `grant_permission` | 카테고리 접근 권한 부여 | company_admin+ |
| `list_users` | 회사 유저 목록 조회 | company_admin+ |
| `get_audit_logs` | 감사 로그 조회 | company_admin+ |
| `add_tokens` | 유저 토큰 추가 | company_admin+ |

---

## 핵심 설계 원칙

1. **데이터 격리**: Supabase RLS로 company_id 기준 테넌트 격리 강제
2. **권한 필터링**: 모든 RAG 검색에 `user_category_access` 기반 메타데이터 필터 적용
3. **감사 추적**: 모든 검색·다운로드·업로드 → `audit_logs` 테이블 기록
4. **임시 다운로드**: 파일 다운로드는 원본 URL 직접 노출 금지 → 유효시간 제한 토큰 방식
5. **1차 프로젝트 패턴 재사용**: n8n 노드 구조, Supabase RPC 패턴, HTML 템플릿

---

## 현재 진행 단계

> **업데이트 규칙**: 작업 완료 후 반드시 이 섹션을 갱신하세요.

| Phase | 내용 | 상태 |
|-------|------|------|
| Phase 0 | 프로젝트 초기 설정 (저장소, 문서, DB 스키마 파일) | ✅ 완료 |
| Phase 1 | n8n 워크플로우 생성 (Auth/Chat/Upload/Admin) | ✅ 완료 |
| Phase 2 | Supabase 프로젝트 생성 + DB 스키마 실행 | ✅ 완료 |
| Phase 3 | n8n 워크플로우 Supabase 연결 + 활성화 | ✅ 완료 |
| Phase 4 | 엔드투엔드 테스트 (Auth → Chat → Upload → Admin) | ✅ 완료 |
| Phase 4.5 | 테스트 페이지 UI 전면 개선 + 회원관리 + 버그수정 | ✅ 완료 |
| Phase 5 | 프론트엔드 (office-ai.app/trust/) | 🔲 대기 |
| Phase 6 | 감사 로그 대시보드 + 보안 강화 | 🔲 대기 |

### 테스트 페이지 (Phase 4.5 완료)

| 페이지 | URL | 설명 |
|--------|-----|------|
| 채팅 | https://office-ai.app/trustrag/chat.html | RAG 검색 + AI 답변 |
| 업로드 | https://office-ai.app/trustrag/upload.html | 문서 업로드 + 임베딩 |
| 관리자 | https://office-ai.app/trustrag/admin.html | 회원/카테고리/권한/토큰 관리 |

**관리자 키**: `.env`의 `TRUSTRAG_SUPER_ADMIN_API_KEY` 사용

---

## n8n 개발 교훈 (TrustRAG 작업 중 발견)

| 교훈 | 상황 | 해결책 |
|------|------|--------|
| **IF 노드 boolean 비교 버그** | `=== true` 비교가 n8n에서 신뢰 불가 | `error` 필드 empty 체크 패턴으로 대체 |
| **LangChain 크레덴셜 접근 불가** | 타 워크플로우의 OpenAI 크레덴셜 재사용 실패 | HTTP Request 노드로 OpenAI API 직접 호출 |
| **`$helpers.httpRequest` 불가** | n8n Cloud Code 노드에서 HTTP 호출 불가 | 별도 HTTP Request 노드를 연결해 처리 |
| **`$input.first()` vs `$input.all()`** | Supabase 배열 응답을 n8n이 개별 item으로 분리 | 여러 결과 수집 시 반드시 `$input.all()` 사용 |
| **URL 표현식 혼용 오류** | `=https://url/{{ expr }}` 방식 오류 | `={{ 'https://url/' + expr }}` 로 통일 |
| **neverError 필수** | Supabase 4xx 시 워크플로우 중단 | HTTP 노드에 `neverError: true` 설정 |
| **api_key NOT NULL** | users INSERT 시 api_key 누락 → DB 오류 | Code 노드에서 `'trust_user_' + uuid()` 자동 생성 |
| **callAdmin 빈 응답** | n8n 워크플로우 오류 시 200 빈 body 반환 | `res.text()` → empty 체크 → `JSON.parse()` 순서 |

---

## 1차 프로젝트 참고 정보 (office-ai RAG)

| 항목 | 값 |
|------|-----|
| n8n 채팅 워크플로우 | `DUhC36eo7SJNw2Wc` |
| n8n 업로드 워크플로우 | `BnNM5zFuBsqrSyeM` |
| Supabase 프로젝트 | `mkmxhmoocqnkltjxdfbm` (TrustRAG와 별도) |
| 프론트엔드 | https://office-ai.app/demo.html |
| 히스토리 | `C:/dev/my-dev-workspace/WORK_HISTORY.md` |
