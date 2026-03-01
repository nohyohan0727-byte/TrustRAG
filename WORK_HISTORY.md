# TrustRAG — 작업 히스토리

> **Claude Code / Cursor 공용 작업 이력입니다.**
> 새 세션 시작 전 반드시 이 파일과 TRUSTRAG.md를 먼저 읽으세요.
> 최신 작업이 위에 옵니다.

---

## 프로젝트 현황 요약 (항상 최신 상태 유지)

| 항목 | 현재 상태 |
|------|-----------|
| **진행 Phase** | Phase 0~4.5 완료 (UI 전면 개선 + 회원관리 완성) |
| **Supabase** | `ryzkcdvywxblsbyujtfv` (활성) |
| **n8n 워크플로우** | 4개 전체 동작 / Admin 액션 6개 지원 |
| **프론트엔드** | 테스트 페이지: office-ai.app/trustrag/{chat,upload,admin}.html |
| **마지막 작업일** | 2026-03-01 |

---

## 작업 이력

---

### [2026-03-01] Phase 4.5 — UI 전면 개선 + 회원관리 + 버그수정

| 항목 | 내용 |
|------|------|
| **작업자** | nohyohan0727-byte + Claude (Sonnet 4.6) |
| **상태** | ✅ 완료 |
| **커밋** | office-ai `63c6288`, `187eb10` / TrustRAG `5594d64` |

#### UI 개선 (office-ai.app/trustrag/)

**chat.html**
- 레이아웃: 최대 680px 중앙 정렬 (기존 전체 너비 → 좁은 채팅 UI)
- 카테고리: raw table_name 직접 노출 → 드롭다운 선택 (categoryMap으로 내부 변환)
- 세션 ID: 사용자에게 숨기고 자동 생성 (`'session-' + Date.now().toString(36)`)
- 보안: API 키 입력 → 인증 성공 후 카테고리 목록 동적 표시

**upload.html**
- 카테고리: table_name 직접 입력 → 드롭다운 (can_upload 권한 필터링)
- 파일 상태: 파일별 성공(초록 테두리) / 실패(빨간 테두리) 표시 + 제거 버튼
- 결과 표시: JSON dump → 요약 박스 (성공/실패 건수 + 아이콘)

**admin.html — 전면 재설계 (역할별 회원관리)**
- 탭 구조: 회원관리 / 카테고리관리 / 권한관리 / 감사로그
- 역할 계층: super_admin(운영자) > company_admin(회사관리자) > group_admin(그룹관리자) > user(사용자)
- 탭 노출 기준:
  - 회원관리: company_admin 이상
  - 카테고리관리: company_admin 이상
  - 권한관리: group_admin 이상
  - 감사로그: company_admin 이상
- 회원 목록: 테이블 형식, 역할 배지 색상 구분
- 회원 등록: 이메일/이름/역할/초기토큰 입력 → 등록 성공 시 API 키 화면 표시
- 토큰 관리: 드롭다운으로 회원 선택 → 수량 입력 → 추가
- 권한 관리: UUID 직접 입력 제거 → 회원/카테고리 드롭다운 선택 방식

#### n8n Admin 워크플로우 신기능

**`add_tokens` 액션 추가**
- Route Action Switch에 케이스 추가 (index 5)
- 노드 체인: Get User Tokens (HTTP GET) → Compute New Tokens (Code) → Update Tokens (HTTP PATCH) → Return Add Tokens
- 테스트: +500 토큰 정상 처리 (99,996 → 100,496)

**`create_user` 버그 수정**
- 원인: `api_key` 컬럼 NOT NULL인데 INSERT 시 누락 → Supabase 오류 → 빈 응답
- 해결: `Prepare Create User` Code 노드 추가 → `'trust_user_' + uuid()` 자동 생성
- 추가: `is_active: true` 기본값 설정
- 추가: `neverError: true` 설정 → Supabase 오류도 응답으로 반환
- 추가: Return 노드에 중복 이메일 등 에러 메시지 처리

**callAdmin 프론트엔드 방어 코드**
- 기존: `res.json()` 직접 호출 → 빈 응답 시 "Unexpected end of JSON input"
- 수정: `res.text()` → empty 체크 → `JSON.parse()` 순서로 안전 처리

#### 발견된 중요 패턴

| 패턴 | 내용 |
|------|------|
| `$helpers.httpRequest` 불가 | n8n Cloud Code 노드에서 HTTP 호출 지원 안 됨 → 별도 HTTP Request 노드 사용 |
| n8n 빈 응답 | 워크플로우 오류 시 Status 200, Body "" 반환 → 프론트에서 text()로 읽어야 함 |
| neverError 필수 | Supabase 4xx 오류 시 neverError 없으면 워크플로우 중단 |

---

### [2026-03-01] Phase 4 — 엔드투엔드 테스트 + 워크플로우 버그 수정

| 항목 | 내용 |
|------|------|
| **작업자** | nohyohan0727-byte + Claude (Sonnet 4.6) |
| **상태** | ✅ 완료 |

**버그 수정:**
- Admin, Chat, Upload 워크플로우의 IF 노드 boolean 비교 버그 → `error` 필드 empty 체크 패턴으로 수정
- Chat 워크플로우: OpenAI LangChain 크레덴셜 문제 → HTTP Request 직접 호출로 교체
- Upload 워크플로우: Google Drive binary 오류 → HTTP 임베딩+Supabase 직접 저장 방식으로 재설계
- Extract Sources: `$input.first()` → `$input.all()` 수정으로 검색 결과 정상 반환
- Supabase 벡터 테이블 수동 생성 (`tr_jknetworks_ks_cert`, `tr_jknetworks_iso_cert`)

**최종 테스트 결과:**
- Auth: ✅ `trust_super_25a70cd8-5535-4197-b086-624203db2d9e` API 키 인증 성공
- Admin: ✅ create_category / list_users / get_audit_logs 동작
- Upload: ✅ `KS인증_개요.txt` 업로드 → 임베딩 → Supabase 저장 성공
- Chat: ✅ 실제 문서 기반 RAG 답변 (유사도 0.89, 내부 문서 참조)

**현재 구조:**
- OpenAI: HTTP Request 직접 호출 (text-embedding-ada-002, gpt-4o-mini)
- Supabase: REST API 직접 호출 (벡터 저장/검색)
- 토큰 차감: 정상 동작 (99999 → 99996)

**테스트 페이지:**
- https://office-ai.app/trustrag/chat.html
- https://office-ai.app/trustrag/upload.html
- https://office-ai.app/trustrag/admin.html

---

### [2026-02-28] Phase 2~3 — Supabase 연결 + 워크플로우 활성화

| 항목 | 내용 |
|------|------|
| **작업자** | nohyohan0727-byte + Claude (Sonnet 4.6) |
| **상태** | ✅ 완료 |

**Supabase 프로젝트:**
- Project ID: `ryzkcdvywxblsbyujtfv`
- URL: `https://ryzkcdvywxblsbyujtfv.supabase.co`
- Region: ap-southeast-1 (싱가포르)
- DB Schema: 01_tables, 02_rls, 03_functions, 04_seed 모두 실행 완료

**n8n 크레덴셜:**
- TrustRAG Supabase 크레덴셜 생성 (ID: `sqACFCNh6c9Vg6iY`)
- OpenAI 기존 크레덴셜 재사용 (ID: `3Ce5sE9uZ6LPb2sk`)
- 4개 워크플로우 모두 활성화 완료

**초기 Super Admin 계정:**
- Email: admin@jknetworks.co.kr
- API Key: `trust_super_CHANGE_THIS_KEY` (04_seed.sql — **반드시 변경 필요**)
- Role: super_admin / Company: JK Networks

**다음 단계:**
1. super_admin API 키 변경 (Supabase SQL Editor)
2. Admin API로 테스트 회사/유저/카테고리 생성
3. 엔드투엔드 테스트 (Auth → Chat → Upload)

---

### [2026-02-28] Phase 1 — n8n 워크플로우 생성

| 항목 | 내용 |
|------|------|
| **작업자** | nohyohan0727-byte + Claude (Sonnet 4.6) |
| **상태** | ✅ 완료 |

**생성된 워크플로우:**

| 이름 | n8n ID | 웹훅 경로 | 설명 |
|------|--------|-----------|------|
| TrustRAG_Auth | `rDRKlBnQpPNyAcHH` | `POST /trustrag/validate-key` | API 키 검증, 권한 반환 |
| TrustRAG_Chat | `Oo9ThEBXSg3QUv4L` | `POST /trustrag/chat` | RAG 검색 + AI 응답 |
| TrustRAG_Upload | `ZrdgEqchaCSoycyP` | `POST /trustrag/upload` | 파일 업로드 + 벡터화 |
| TrustRAG_Admin | `9c5kGAC7xHGXgvtX` | `POST /trustrag/admin` | 관리자 API (유저/카테고리/권한) |

**Admin 워크플로우 지원 액션:**
- `create_user` — 신규 유저 생성
- `create_category` — 카테고리 생성 + 동적 벡터 테이블 생성
- `grant_permission` — 카테고리 접근 권한 부여
- `list_users` — 회사 유저 목록 조회
- `get_audit_logs` — 감사 로그 조회

**중요 사항:**
- 모든 Supabase URL은 `TRUSTRAG_SUPABASE_URL_HERE` 플레이스홀더 사용
- Supabase 프로젝트 생성 후 n8n 노드에서 실제 URL/KEY로 교체 필요
- n8n 백업: `n8n/` 폴더에 4개 JSON 파일 저장됨

**다음 단계:**
1. 사용자가 Supabase 새 프로젝트 생성 (supabase.com)
2. `TRUSTRAG_SUPABASE_URL_HERE` → 실제 URL, `TRUSTRAG_SERVICE_KEY_HERE` → 실제 Key 교체
3. db/01~04 SQL 실행하여 스키마 구성
4. n8n 워크플로우 활성화

---

### [2026-02-28] Phase 0 — 프로젝트 초기 설정

| 항목 | 내용 |
|------|------|
| **작업자** | nohyohan0727-byte + Claude (Sonnet 4.6) |
| **상태** | ✅ 완료 |
| **상세 로그** | [work-logs/2026-02-28-phase0-init.md](work-logs/2026-02-28-phase0-init.md) |

**작업 내용:**
- GitHub 저장소 `TrustRAG` 생성
- 폴더 구조 생성: db/, n8n/, docs/, work-logs/
- TRUSTRAG.md 작성 (Claude/Cursor 공용 컨텍스트 파일)
- ROADMAP.md 작성 (Phase 0~6 전체 계획)
- WORK_HISTORY.md 작성 (이 파일)
- .env.example 작성
- db/01_tables.sql 작성 (전체 스키마)
- db/02_rls.sql 작성 (RLS 정책)
- db/03_functions.sql 작성 (RPC 함수)
- db/04_seed.sql 작성 (초기 데이터)

**다음 단계:**
1. **사용자 직접**: Supabase 새 프로젝트 생성 후 Project ID / API Key를 .env에 기입
2. **AI**: db/ 폴더의 SQL을 Supabase에 실행하여 스키마 구성

---

## 참고: 1차 프로젝트 (office-ai RAG) 주요 교훈

| 교훈 | 내용 |
|------|------|
| `alwaysOutputData: true` | 빈 결과 노드가 있으면 이후 노드 실행 안 됨 |
| `dimensions` 옵션 제거 | text-embedding-ada-002는 dimensions 미지원 |
| 함수명 동적 연결 | queryName을 `match_{{ tableName }}` 표현식으로 |
| `#variable_conflict use_column` | pgvector 함수에서 id 컬럼 ambiguous 방지 |
| 테이블 별칭 `t.` | SELECT에서 컬럼 충돌 방지 |
| catch 블록 세분화 | 모든 에러를 "연결 오류"로 뭉치면 디버깅 어려움 |
| getFileIcon 누락 | renderSources 호출 함수 반드시 먼저 정의 |
