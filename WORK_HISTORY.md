# TrustRAG — 작업 히스토리

> **Claude Code / Cursor 공용 작업 이력입니다.**
> 새 세션 시작 전 반드시 이 파일과 TRUSTRAG.md를 먼저 읽으세요.
> 최신 작업이 위에 옵니다.

---

## 프로젝트 현황 요약 (항상 최신 상태 유지)

| 항목 | 현재 상태 |
|------|-----------|
| **진행 Phase** | Phase 0~3 완료 → Phase 4 (엔드투엔드 테스트) |
| **Supabase** | `ryzkcdvywxblsbyujtfv` (활성) |
| **n8n 워크플로우** | 4개 생성 + 활성화 완료 |
| **프론트엔드** | 미생성 |
| **마지막 작업일** | 2026-02-28 |

---

## 작업 이력

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
