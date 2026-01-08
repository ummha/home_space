-- ============================================
-- Content Service Database Schema
-- 콘텐츠 서비스 데이터베이스 스키마
--
-- 목적: 블로그 게시글, 카테고리, 태그, 댓글 관리
-- 버전: 1.0.0
-- 작성일: 2025-01-09
-- ============================================

-- ============================================
-- 게시글 테이블 (Aggregate Root)
-- ============================================
CREATE TABLE posts
(
    id               BIGSERIAL PRIMARY KEY,
    title            VARCHAR(200)        NOT NULL,
    slug             VARCHAR(250) UNIQUE NOT NULL,
    content          TEXT                NOT NULL,
    excerpt          VARCHAR(500),

    status           VARCHAR(20)         NOT NULL DEFAULT 'DRAFT',
    published_at     TIMESTAMP,

    meta_title       VARCHAR(200),
    meta_description VARCHAR(300),
    og_image_url     VARCHAR(500),

    view_count       INT                          DEFAULT 0,
    like_count       INT                          DEFAULT 0,
    comment_count    INT                          DEFAULT 0,

    created_at       TIMESTAMP                    DEFAULT NOW(),
    updated_at       TIMESTAMP                    DEFAULT NOW(),
    deleted_at       TIMESTAMP,

    CONSTRAINT chk_status CHECK (status IN ('DRAFT', 'PUBLISHED', 'ARCHIVED'))
);

-- 테이블 코멘트
COMMENT ON TABLE posts IS '게시글 테이블 - 블로그의 핵심 콘텐츠를 저장합니다. Aggregate Root로 설계되었습니다.';

-- 컬럼 코멘트
COMMENT ON COLUMN posts.id IS '게시글 고유 식별자 (Primary Key)';
COMMENT ON COLUMN posts.title IS '게시글 제목 - 최대 200자';
COMMENT ON COLUMN posts.slug IS 'SEO 친화적 URL 경로 (예: spring-boot-tutorial) - UNIQUE 제약조건';
COMMENT ON COLUMN posts.content IS '게시글 본문 - Markdown 형식';
COMMENT ON COLUMN posts.excerpt IS '게시글 요약문 - 목록 페이지에 표시됨 (최대 500자)';
COMMENT ON COLUMN posts.status IS '게시글 상태 - DRAFT(초안), PUBLISHED(발행), ARCHIVED(보관)';
COMMENT ON COLUMN posts.published_at IS '최초 발행 일시 - NULL이면 미발행 상태';
COMMENT ON COLUMN posts.meta_title IS 'SEO용 메타 제목 - 검색 엔진 최적화';
COMMENT ON COLUMN posts.meta_description IS 'SEO용 메타 설명 - 검색 결과에 표시됨';
COMMENT ON COLUMN posts.og_image_url IS 'Open Graph 이미지 URL - 소셜 미디어 공유 시 사용';
COMMENT ON COLUMN posts.view_count IS '조회수 - post_views 테이블과 동기화되는 비정규화 데이터';
COMMENT ON COLUMN posts.like_count IS '좋아요 수 - 비정규화 데이터';
COMMENT ON COLUMN posts.comment_count IS '댓글 수 - comments 테이블과 동기화되는 비정규화 데이터';
COMMENT ON COLUMN posts.created_at IS '생성 일시';
COMMENT ON COLUMN posts.updated_at IS '최종 수정 일시';
COMMENT ON COLUMN posts.deleted_at IS 'Soft Delete 일시 - NULL이면 활성 상태';

-- 인덱스
CREATE INDEX idx_posts_status ON posts (status);
COMMENT ON INDEX idx_posts_status IS '상태별 게시글 조회 최적화';

CREATE INDEX idx_posts_published_at ON posts (published_at DESC) WHERE status = 'PUBLISHED';
COMMENT ON INDEX idx_posts_published_at IS '발행된 게시글을 최신순으로 조회 최적화 - Partial Index';

CREATE INDEX idx_posts_slug ON posts (slug) WHERE deleted_at IS NULL;
COMMENT ON INDEX idx_posts_slug IS 'Slug로 게시글 조회 최적화 - 삭제되지 않은 게시글만';

CREATE INDEX idx_posts_search_en ON posts USING gin (to_tsvector('english', title || ' ' || content));
COMMENT ON INDEX idx_posts_search_en IS '영어 전문 검색(Full Text Search) 인덱스 - GIN 타입';

CREATE INDEX idx_posts_search_ko ON posts USING gin (to_tsvector('simple', title || ' ' || content));
COMMENT ON INDEX idx_posts_search_ko IS '한글 전문 검색 인덱스 - Simple Dictionary 사용';

-- ============================================
-- 카테고리 테이블
-- ============================================
CREATE TABLE categories
(
    id            BIGSERIAL PRIMARY KEY,
    name          VARCHAR(100)        NOT NULL,
    slug          VARCHAR(100) UNIQUE NOT NULL,
    description   TEXT,
    parent_id     BIGINT REFERENCES categories (id),

    display_order INT       DEFAULT 0,
    is_active     BOOLEAN   DEFAULT true,

    created_at    TIMESTAMP DEFAULT NOW(),
    updated_at    TIMESTAMP DEFAULT NOW()
);

COMMENT ON TABLE categories IS '카테고리 테이블 - 게시글 분류를 위한 계층 구조 지원';

COMMENT ON COLUMN categories.id IS '카테고리 고유 식별자';
COMMENT ON COLUMN categories.name IS '카테고리 이름 (예: 기술, 일상, 리뷰)';
COMMENT ON COLUMN categories.slug IS 'URL 경로용 슬러그 (예: tech, life, review)';
COMMENT ON COLUMN categories.description IS '카테고리 설명';
COMMENT ON COLUMN categories.parent_id IS '상위 카테고리 ID - NULL이면 최상위 카테고리, Self-Reference FK';
COMMENT ON COLUMN categories.display_order IS '정렬 순서 - 낮을수록 먼저 표시';
COMMENT ON COLUMN categories.is_active IS '활성화 여부 - false면 비활성화';
COMMENT ON COLUMN categories.created_at IS '생성 일시';
COMMENT ON COLUMN categories.updated_at IS '최종 수정 일시';

CREATE INDEX idx_categories_parent_id ON categories (parent_id);
COMMENT ON INDEX idx_categories_parent_id IS '계층 구조 조회 최적화 - 하위 카테고리 조회';

CREATE INDEX idx_categories_slug ON categories (slug);
COMMENT ON INDEX idx_categories_slug IS 'Slug로 카테고리 조회 최적화';

-- ============================================
-- 태그 테이블
-- ============================================
CREATE TABLE tags
(
    id          BIGSERIAL PRIMARY KEY,
    name        VARCHAR(50)        NOT NULL UNIQUE,
    slug        VARCHAR(50) UNIQUE NOT NULL,
    usage_count INT       DEFAULT 0,
    created_at  TIMESTAMP DEFAULT NOW()
);

COMMENT ON TABLE tags IS '태그 테이블 - 게시글에 부여할 수 있는 키워드';

COMMENT ON COLUMN tags.id IS '태그 고유 식별자';
COMMENT ON COLUMN tags.name IS '태그 이름 (예: Java, Spring Boot, MSA)';
COMMENT ON COLUMN tags.slug IS 'URL 경로용 슬러그 (예: java, spring-boot, msa)';
COMMENT ON COLUMN tags.usage_count IS '사용 횟수 - post_tags와 동기화되는 비정규화 데이터, 인기 태그 정렬용';
COMMENT ON COLUMN tags.created_at IS '생성 일시';

CREATE INDEX idx_tags_slug ON tags (slug);
COMMENT ON INDEX idx_tags_slug IS 'Slug로 태그 조회 최적화';

CREATE INDEX idx_tags_usage ON tags (usage_count DESC);
COMMENT ON INDEX idx_tags_usage IS '인기 태그 정렬 최적화 - 사용 횟수 내림차순';

-- ============================================
-- 게시글-카테고리 매핑 테이블 (M:N)
-- ============================================
CREATE TABLE post_categories
(
    post_id     BIGINT REFERENCES posts (id) ON DELETE CASCADE,
    category_id BIGINT REFERENCES categories (id) ON DELETE CASCADE,
    created_at  TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (post_id, category_id)
);

COMMENT ON TABLE post_categories IS '게시글-카테고리 다대다 관계 매핑 테이블 - 하나의 게시글이 여러 카테고리에 속할 수 있음';

COMMENT ON COLUMN post_categories.post_id IS '게시글 ID - posts 테이블 참조';
COMMENT ON COLUMN post_categories.category_id IS '카테고리 ID - categories 테이블 참조';
COMMENT ON COLUMN post_categories.created_at IS '연결 생성 일시';

CREATE INDEX idx_post_categories_category ON post_categories (category_id);
COMMENT ON INDEX idx_post_categories_category IS '카테고리별 게시글 조회 최적화';

-- ============================================
-- 게시글-태그 매핑 테이블 (M:N)
-- ============================================
CREATE TABLE post_tags
(
    post_id    BIGINT REFERENCES posts (id) ON DELETE CASCADE,
    tag_id     BIGINT REFERENCES tags (id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (post_id, tag_id)
);

COMMENT ON TABLE post_tags IS '게시글-태그 다대다 관계 매핑 테이블 - 하나의 게시글에 여러 태그 부여 가능';

COMMENT ON COLUMN post_tags.post_id IS '게시글 ID - posts 테이블 참조';
COMMENT ON COLUMN post_tags.tag_id IS '태그 ID - tags 테이블 참조';
COMMENT ON COLUMN post_tags.created_at IS '연결 생성 일시';

CREATE INDEX idx_post_tags_tag ON post_tags (tag_id);
COMMENT ON INDEX idx_post_tags_tag IS '태그별 게시글 조회 최적화';

-- ============================================
-- 댓글 테이블
-- ============================================
CREATE TABLE comments
(
    id           BIGSERIAL PRIMARY KEY,
    post_id      BIGINT       NOT NULL REFERENCES posts (id) ON DELETE CASCADE,
    parent_id    BIGINT REFERENCES comments (id),

    author_id    BIGINT,
    author_name  VARCHAR(100) NOT NULL,
    author_email VARCHAR(200),

    content      TEXT         NOT NULL,
    status       VARCHAR(20) DEFAULT 'PENDING',
    like_count   INT         DEFAULT 0,

    created_at   TIMESTAMP   DEFAULT NOW(),
    updated_at   TIMESTAMP   DEFAULT NOW(),
    deleted_at   TIMESTAMP,

    CONSTRAINT chk_comment_status CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED', 'DELETED'))
);

COMMENT ON TABLE comments IS '댓글 테이블 - 게시글에 달리는 댓글 및 대댓글 지원';

COMMENT ON COLUMN comments.id IS '댓글 고유 식별자';
COMMENT ON COLUMN comments.post_id IS '게시글 ID - posts 테이블 참조, CASCADE DELETE';
COMMENT ON COLUMN comments.parent_id IS '상위 댓글 ID - NULL이면 최상위 댓글, Self-Reference FK로 대댓글 구조 지원';
COMMENT ON COLUMN comments.author_id IS '작성자 ID - Auth Service의 user_id, NULL이면 익명 댓글';
COMMENT ON COLUMN comments.author_name IS '작성자 이름 - 비정규화 데이터, 익명 댓글 표시용';
COMMENT ON COLUMN comments.author_email IS '작성자 이메일 - 익명 댓글의 경우 알림 발송용';
COMMENT ON COLUMN comments.content IS '댓글 내용';
COMMENT ON COLUMN comments.status IS '댓글 상태 - PENDING(승인대기), APPROVED(승인), REJECTED(거부), DELETED(삭제)';
COMMENT ON COLUMN comments.like_count IS '좋아요 수 - 비정규화 데이터';
COMMENT ON COLUMN comments.created_at IS '작성 일시';
COMMENT ON COLUMN comments.updated_at IS '최종 수정 일시';
COMMENT ON COLUMN comments.deleted_at IS 'Soft Delete 일시 - NULL이면 활성 상태';

CREATE INDEX idx_comments_post_id ON comments (post_id);
COMMENT ON INDEX idx_comments_post_id IS '게시글별 댓글 조회 최적화';

CREATE INDEX idx_comments_parent_id ON comments (parent_id);
COMMENT ON INDEX idx_comments_parent_id IS '대댓글 조회 최적화';

CREATE INDEX idx_comments_status ON comments (status);
COMMENT ON INDEX idx_comments_status IS '상태별 댓글 조회 최적화 - 관리자 페이지용';

-- ============================================
-- 이벤트 아웃박스 테이블
-- ============================================
CREATE TABLE outbox_events
(
    id             BIGSERIAL PRIMARY KEY,
    aggregate_type VARCHAR(50)  NOT NULL,
    aggregate_id   BIGINT       NOT NULL,
    event_type     VARCHAR(100) NOT NULL,
    payload        JSONB        NOT NULL,
    published      BOOLEAN   DEFAULT false,
    published_at   TIMESTAMP,
    created_at     TIMESTAMP DEFAULT NOW(),

    CONSTRAINT chk_aggregate_type CHECK (aggregate_type IN ('POST', 'COMMENT'))
);

COMMENT ON TABLE outbox_events IS 'Transactional Outbox 패턴 구현 테이블 - 도메인 이벤트를 Kafka로 발행하기 전 저장';

COMMENT ON COLUMN outbox_events.id IS '이벤트 고유 식별자';
COMMENT ON COLUMN outbox_events.aggregate_type IS 'Aggregate 타입 - POST, COMMENT';
COMMENT ON COLUMN outbox_events.aggregate_id IS 'Aggregate 인스턴스 ID - 예: post_id, comment_id';
COMMENT ON COLUMN outbox_events.event_type IS '이벤트 타입 - PostPublished, PostUpdated, PostDeleted, CommentCreated 등';
COMMENT ON COLUMN outbox_events.payload IS '이벤트 페이로드 - JSON 형식으로 이벤트 데이터 저장';
COMMENT ON COLUMN outbox_events.published IS '발행 여부 - false면 미발행, true면 Kafka로 발행 완료';
COMMENT ON COLUMN outbox_events.published_at IS 'Kafka 발행 완료 일시';
COMMENT ON COLUMN outbox_events.created_at IS '이벤트 생성 일시';

CREATE INDEX idx_outbox_unpublished ON outbox_events (created_at) WHERE published = false;
COMMENT ON INDEX idx_outbox_unpublished IS '미발행 이벤트 조회 최적화 - Partial Index, 배치 처리용';

CREATE INDEX idx_outbox_published_at ON outbox_events (published_at) WHERE published = true;
COMMENT ON INDEX idx_outbox_published_at IS '발행 완료 이벤트 조회 최적화 - 감사 및 디버깅용';

-- ============================================
-- 조회수 추적 테이블
-- ============================================
CREATE TABLE post_views
(
    id        BIGSERIAL PRIMARY KEY,
    post_id   BIGINT NOT NULL REFERENCES posts (id) ON DELETE CASCADE,
    viewer_ip VARCHAR(45),
    viewer_id BIGINT,
    viewed_at TIMESTAMP DEFAULT NOW()
);

COMMENT ON TABLE post_views IS '게시글 조회 추적 테이블 - IP/사용자 기반 중복 방지로 정확한 조회수 측정';

COMMENT ON COLUMN post_views.id IS '조회 기록 고유 식별자';
COMMENT ON COLUMN post_views.post_id IS '게시글 ID - posts 테이블 참조';
COMMENT ON COLUMN post_views.viewer_ip IS '조회자 IP 주소 - IPv6 지원 (최대 45자)';
COMMENT ON COLUMN post_views.viewer_id IS '조회자 사용자 ID - 로그인 사용자인 경우, NULL이면 익명';
COMMENT ON COLUMN post_views.viewed_at IS '조회 일시';

-- 함수 기반 UNIQUE 인덱스 생성
CREATE UNIQUE INDEX idx_post_views_unique_daily
    ON post_views (post_id, viewer_ip, DATE(viewed_at));
COMMENT ON INDEX idx_post_views_unique_daily IS '일별 중복 조회 방지 - 같은 IP/사용자가 하루에 한 번만 카운트되도록 함수 기반 UNIQUE 인덱스 사용';

CREATE INDEX idx_post_views_post_id ON post_views (post_id);
COMMENT ON INDEX idx_post_views_post_id IS '게시글별 조회 기록 조회 최적화';

CREATE INDEX idx_post_views_viewed_at ON post_views (viewed_at);
COMMENT ON INDEX idx_post_views_viewed_at IS '기간별 조회 통계 조회 최적화';

-- ============================================
-- 스키마 버전 정보
-- ============================================
COMMENT ON SCHEMA public IS 'Content Service Database - Version 1.0.0, Created: 2025-01-09';