# TrustRAG — 작업 히스토리

> **Claude Code / Cursor 공용 작업 이력입니다.**
> 새 세션 시작 전 반드시 이 파일과 TRUSTRAG.md를 먼저 읽으세요.
> 최신 작업이 위에 옵니다.

---

## 프로젝트 현황 요약 (항상 최신 상태 유지)

| 항목 | 현재 상태 |
|------|-----------|
| **진행 Phase** | Phase 0 완료 → Phase 1 (DB) 대기 |
| **Supabase** | 새 프로젝트 생성 필요 (사용자 직접) |
| **n8n 워크플로우** | 미생성 |
| **프론트엔드** | 미생성 |
| **마지막 작업일** | 2026-02-28 |

---

## 작업 이력

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
