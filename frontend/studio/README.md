# 음하 스튜디오 (Ummha Studio)

블로그 컨텐츠를 관리하고 개인 실험실 기능을 체험할 수 있는 관리자 콘솔입니다.

## 🚀 기술 스택

- **Framework**: Nuxt 4
- **UI Library**: Vue 3
- **Component Library**: shadcn-vue 스타일 컴포넌트
- **Styling**: Tailwind CSS v4
- **State Management**: Pinia
- **HTTP Client**: Axios
- **Markdown**: markdown-it
- **Icons**: @nuxt/icon (Lucide Icons)
- **Type Safety**: TypeScript

## 📦 주요 기능

### 1. 게시글 관리
- ✅ 게시글 목록 조회
- ✅ 게시글 상태 필터링 (전체, 임시저장, 게시됨, 보관됨)
- ✅ 검색 기능 (제목, 내용, 태그)
- ✅ 게시글 생성/수정/삭제
- ✅ 게시/게시 취소

### 2. 마크다운 에디터
- ✅ 실시간 마크다운 미리보기
- ✅ 분할 화면 (에디터 + 미리보기)
- ✅ 마크다운 도구 모음 (굵게, 기울임, 제목, 링크, 코드, 목록)
- ✅ 구문 강조 지원

### 3. 게시글 메타데이터
- ✅ 제목, 슬러그, 요약
- ✅ 카테고리, 태그
- ✅ 상태 관리

### 4. 대시보드
- ✅ 게시글 통계 (전체, 게시됨, 임시저장)
- ✅ 상태별 필터링
- ✅ 반응형 디자인

## 🏗️ 프로젝트 구조

```
frontend/studio/
├── app/
│   ├── layouts/
│   │   └── default.vue          # 메인 레이아웃
│   ├── pages/
│   │   ├── index.vue            # 게시글 목록 페이지
│   │   └── editor/
│   │       └── [id].vue         # 에디터 페이지 (생성/수정)
│   └── app.vue                  # 앱 루트
├── components/
│   ├── ui/                      # shadcn 스타일 UI 컴포넌트
│   │   ├── Button.vue
│   │   ├── Card.vue
│   │   ├── Input.vue
│   │   ├── Table.vue
│   │   ├── Badge.vue
│   │   └── ...
│   ├── MarkdownEditor.vue       # 마크다운 에디터
│   ├── MarkdownPreview.vue      # 마크다운 미리보기
│   ├── PostList.vue             # 게시글 목록
│   └── StatusBadge.vue          # 상태 뱃지
├── stores/
│   └── posts.ts                 # Pinia 스토어 (게시글 관리)
├── lib/
│   └── utils.ts                 # 유틸리티 함수
├── assets/
│   └── css/
│       └── main.css             # Tailwind CSS 설정
├── types/
│   └── index.ts                 # TypeScript 타입 정의
└── nuxt.config.ts               # Nuxt 설정
```

## 🛠️ 개발 환경 설정

### 설치

```bash
cd frontend/studio
npm install
```

### 개발 서버 실행

```bash
npm run dev
```

개발 서버가 `http://localhost:3000`에서 실행됩니다.

### 빌드

```bash
npm run build
```

### 프리뷰

```bash
npm run preview
```

## 📝 사용 가이드

### 게시글 작성하기

1. 상단 네비게이션에서 "새 글 작성" 클릭 또는 메인 페이지에서 "+ 새 글 작성" 버튼 클릭
2. 제목과 내용 입력 (마크다운 형식)
3. 필요시 슬러그, 요약, 카테고리, 태그 추가
4. "임시저장" 또는 "게시" 버튼 클릭

### 마크다운 문법

```markdown
# 제목 1
## 제목 2
### 제목 3

**굵은 텍스트**
*기울임 텍스트*

[링크 텍스트](https://example.com)

`인라인 코드`

- 목록 항목 1
- 목록 항목 2

1. 번호 목록 1
2. 번호 목록 2
```

### 게시글 관리

- **수정**: 목록에서 연필 아이콘 클릭
- **게시/게시 취소**: 눈 아이콘 클릭
- **삭제**: 휴지통 아이콘 클릭 (확인 필요)

### 필터링 및 검색

- 상태별 필터: "전체", "임시저장", "게시됨", "보관됨" 버튼 클릭
- 검색: 검색창에 키워드 입력 (제목, 내용, 태그 검색)

## 🎨 디자인 시스템

### 색상 팔레트

- **Primary**: 파란색 계열 (#3B82F6)
- **Secondary**: 회색 계열
- **Success**: 녹색 (게시 상태)
- **Warning**: 노란색
- **Destructive**: 빨간색 (삭제 작업)

### 다크 모드

자동으로 시스템 테마를 따릅니다. 라이트/다크 모드 전환이 지원됩니다.

## 🔌 API 통합 (향후 예정)

현재는 Pinia 스토어를 사용한 로컬 상태 관리를 사용합니다.
향후 백엔드 API와 통합 시:

```typescript
// stores/posts.ts에서 API 호출 추가
const apiClient = axios.create({
  baseURL: 'http://localhost:8081/api',
})

async function fetchPosts() {
  const response = await apiClient.get('/posts')
  posts.value = response.data
}
```

## 📚 향후 개발 계획

- [ ] 이미지 업로드 기능
- [ ] 코드 블록 구문 강조
- [ ] 게시글 버전 관리
- [ ] 댓글 관리
- [ ] 사용자 권한 관리
- [ ] 분석 대시보드
- [ ] 실험실 기능 (채팅 등)
- [ ] 다국어 지원

## 🐛 알려진 이슈

현재 알려진 이슈가 없습니다.

## 📄 라이선스

이 프로젝트는 개인 포트폴리오 목적으로 제작되었습니다.
