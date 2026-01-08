-- ============================================
-- Auth Service Database Schema
-- 인증 서비스 데이터베이스 스키마
--
-- 목적: 사용자 인증, 인가, 회원 정보 관리
-- 버전: 1.0.0
-- 작성일: 2025-01-09
-- ============================================

-- ============================================
-- 사용자 테이블 (Aggregate Root)
-- ============================================
CREATE TABLE users
(
    id             BIGSERIAL PRIMARY KEY,

    email          VARCHAR(200) UNIQUE NOT NULL,
    username       VARCHAR(50) UNIQUE  NOT NULL,
    password_hash  VARCHAR(255)        NOT NULL,

    display_name   VARCHAR(100)        NOT NULL,
    avatar_url     VARCHAR(500),
    bio            TEXT,

    role           VARCHAR(20)         NOT NULL DEFAULT 'GUEST',
    status         VARCHAR(20)         NOT NULL DEFAULT 'ACTIVE',
    email_verified BOOLEAN                      DEFAULT false,

    last_login_at  TIMESTAMP,
    last_login_ip  VARCHAR(45),

    created_at     TIMESTAMP                    DEFAULT NOW(),
    updated_at     TIMESTAMP                    DEFAULT NOW(),
    deleted_at     TIMESTAMP,

    CONSTRAINT chk_role CHECK (role IN ('ADMIN', 'GUEST', 'SUBSCRIBER')),
    CONSTRAINT chk_status CHECK (status IN ('ACTIVE', 'INACTIVE', 'BANNED'))
);

-- 테이블 코멘트
COMMENT ON TABLE users IS '사용자 테이블 - 인증 및 회원 정보를 관리합니다. Auth Service의 Aggregate Root입니다.';

-- 컬럼 코멘트
COMMENT ON COLUMN users.id IS '사용자 고유 식별자 (Primary Key)';
COMMENT ON COLUMN users.email IS '이메일 주소 - 로그인 ID로 사용, UNIQUE 제약조건';
COMMENT ON COLUMN users.username IS '사용자명 - 닉네임으로 사용, UNIQUE 제약조건, URL에 사용 가능';
COMMENT ON COLUMN users.password_hash IS '비밀번호 해시값 - BCrypt 또는 Argon2로 암호화된 값, 평문 저장 금지';
COMMENT ON COLUMN users.display_name IS '표시 이름 - 실명 또는 별명, 화면에 표시되는 이름';
COMMENT ON COLUMN users.avatar_url IS '프로필 이미지 URL - CDN 또는 스토리지 경로';
COMMENT ON COLUMN users.bio IS '자기소개 - 사용자 프로필에 표시되는 소개글';
COMMENT ON COLUMN users.role IS '사용자 역할 - ADMIN(관리자), GUEST(일반 사용자), SUBSCRIBER(구독자)';
COMMENT ON COLUMN users.status IS '계정 상태 - ACTIVE(활성), INACTIVE(비활성), BANNED(정지)';
COMMENT ON COLUMN users.email_verified IS '이메일 인증 여부 - true면 인증 완료, false면 미인증';
COMMENT ON COLUMN users.last_login_at IS '마지막 로그인 일시 - 보안 모니터링 및 휴면 계정 판단용';
COMMENT ON COLUMN users.last_login_ip IS '마지막 로그인 IP 주소 - 보안 이상 탐지용, IPv6 지원 (최대 45자)';
COMMENT ON COLUMN users.created_at IS '계정 생성 일시';
COMMENT ON COLUMN users.updated_at IS '최종 수정 일시';
COMMENT ON COLUMN users.deleted_at IS 'Soft Delete 일시 - NULL이면 활성 계정, 값이 있으면 삭제된 계정';

-- 제약조건 코멘트
COMMENT ON CONSTRAINT chk_role ON users IS '역할 제약조건 - ADMIN, GUEST, SUBSCRIBER만 허용';
COMMENT ON CONSTRAINT chk_status ON users IS '상태 제약조건 - ACTIVE, INACTIVE, BANNED만 허용';

-- 인덱스
CREATE INDEX idx_users_email ON users (email);
COMMENT ON INDEX idx_users_email IS '이메일로 사용자 조회 최적화 - 로그인 시 사용';

CREATE INDEX idx_users_username ON users (username);
COMMENT ON INDEX idx_users_username IS '사용자명으로 조회 최적화 - 프로필 페이지 조회 시 사용';

CREATE INDEX idx_users_role ON users (role);
COMMENT ON INDEX idx_users_role IS '역할별 사용자 조회 최적화 - 관리자 페이지에서 사용';

CREATE INDEX idx_users_status ON users (status);
COMMENT ON INDEX idx_users_status IS '상태별 사용자 조회 최적화 - 활성/정지 계정 필터링';

-- ============================================
-- 권한 테이블 (RBAC)
-- ============================================
CREATE TABLE permissions
(
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    resource    VARCHAR(50),
    action      VARCHAR(50),
    created_at  TIMESTAMP DEFAULT NOW()
);

COMMENT ON TABLE permissions IS '권한 테이블 - RBAC(Role-Based Access Control) 구현을 위한 권한 정의';

COMMENT ON COLUMN permissions.id IS '권한 고유 식별자';
COMMENT ON COLUMN permissions.name IS '권한 이름 - 예: POST_CREATE, POST_DELETE, USER_MANAGE, UNIQUE 제약조건';
COMMENT ON COLUMN permissions.description IS '권한 설명 - 관리자가 이해하기 쉬운 설명';
COMMENT ON COLUMN permissions.resource IS '리소스 타입 - POST, COMMENT, USER 등 권한이 적용되는 대상';
COMMENT ON COLUMN permissions.action IS '액션 타입 - CREATE, READ, UPDATE, DELETE, PUBLISH 등 허용된 작업';
COMMENT ON COLUMN permissions.created_at IS '권한 생성 일시';

-- ============================================
-- 역할-권한 매핑 테이블
-- ============================================
CREATE TABLE role_permissions
(
    role          VARCHAR(20) NOT NULL,
    permission_id INT REFERENCES permissions (id) ON DELETE CASCADE,
    created_at    TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (role, permission_id)
);

COMMENT ON TABLE role_permissions IS '역할-권한 매핑 테이블 - 각 역할(ADMIN, GUEST, SUBSCRIBER)에 부여된 권한을 정의';

COMMENT ON COLUMN role_permissions.role IS '역할명 - ADMIN, GUEST, SUBSCRIBER (users.role과 동일한 값)';
COMMENT ON COLUMN role_permissions.permission_id IS '권한 ID - permissions 테이블 참조, CASCADE DELETE';
COMMENT ON COLUMN role_permissions.created_at IS '권한 부여 일시';

-- ============================================
-- 이메일 인증 테이블
-- ============================================
CREATE TABLE email_verifications
(
    id          BIGSERIAL PRIMARY KEY,
    user_id     BIGINT              NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    token       VARCHAR(255) UNIQUE NOT NULL,
    expires_at  TIMESTAMP           NOT NULL,
    verified_at TIMESTAMP,
    created_at  TIMESTAMP DEFAULT NOW()
);

COMMENT ON TABLE email_verifications IS '이메일 인증 테이블 - 회원가입 시 이메일 소유권 확인을 위한 토큰 관리';

COMMENT ON COLUMN email_verifications.id IS '인증 요청 고유 식별자';
COMMENT ON COLUMN email_verifications.user_id IS '사용자 ID - users 테이블 참조, CASCADE DELETE';
COMMENT ON COLUMN email_verifications.token IS '인증 토큰 - UUID 또는 랜덤 문자열, 이메일로 발송됨, UNIQUE 제약조건';
COMMENT ON COLUMN email_verifications.expires_at IS '토큰 만료 일시 - 일반적으로 24시간 후, 만료 후 재발급 필요';
COMMENT ON COLUMN email_verifications.verified_at IS '인증 완료 일시 - NULL이면 미인증, 값이 있으면 인증 완료';
COMMENT ON COLUMN email_verifications.created_at IS '인증 토큰 생성 일시';

CREATE INDEX idx_email_verifications_token ON email_verifications (token);
COMMENT ON INDEX idx_email_verifications_token IS '토큰으로 인증 요청 조회 최적화 - 사용자가 인증 링크 클릭 시 사용';

CREATE INDEX idx_email_verifications_user_id ON email_verifications (user_id);
COMMENT ON INDEX idx_email_verifications_user_id IS '사용자별 인증 요청 조회 최적화 - 재발급 여부 확인';

-- ============================================
-- 비밀번호 재설정 테이블
-- ============================================
CREATE TABLE password_resets
(
    id         BIGSERIAL PRIMARY KEY,
    user_id    BIGINT              NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    token      VARCHAR(255) UNIQUE NOT NULL,
    expires_at TIMESTAMP           NOT NULL,
    used_at    TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);

COMMENT ON TABLE password_resets IS '비밀번호 재설정 테이블 - 비밀번호 찾기 기능을 위한 토큰 관리';

COMMENT ON COLUMN password_resets.id IS '재설정 요청 고유 식별자';
COMMENT ON COLUMN password_resets.user_id IS '사용자 ID - users 테이블 참조, CASCADE DELETE';
COMMENT ON COLUMN password_resets.token IS '재설정 토큰 - UUID 또는 랜덤 문자열, 이메일로 발송됨, UNIQUE 제약조건';
COMMENT ON COLUMN password_resets.expires_at IS '토큰 만료 일시 - 일반적으로 1시간 후, 보안을 위해 짧게 설정';
COMMENT ON COLUMN password_resets.used_at IS '토큰 사용 일시 - NULL이면 미사용, 값이 있으면 이미 사용됨 (재사용 방지)';
COMMENT ON COLUMN password_resets.created_at IS '재설정 토큰 생성 일시';

CREATE INDEX idx_password_resets_token ON password_resets (token);
COMMENT ON INDEX idx_password_resets_token IS '토큰으로 재설정 요청 조회 최적화 - 사용자가 재설정 링크 클릭 시 사용';

CREATE INDEX idx_password_resets_user_id ON password_resets (user_id);
COMMENT ON INDEX idx_password_resets_user_id IS '사용자별 재설정 요청 조회 최적화 - 이상 패턴 탐지 (과도한 요청)';

-- ============================================
-- 로그인 히스토리 테이블
-- ============================================
CREATE TABLE login_history
(
    id             BIGSERIAL PRIMARY KEY,
    user_id        BIGINT  NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    login_at       TIMESTAMP DEFAULT NOW(),
    ip_address     VARCHAR(45),
    user_agent     TEXT,
    success        BOOLEAN NOT NULL,
    failure_reason VARCHAR(200)
);

COMMENT ON TABLE login_history IS '로그인 히스토리 테이블 - 보안 감사 및 이상 로그인 탐지를 위한 로그';

COMMENT ON COLUMN login_history.id IS '로그인 기록 고유 식별자';
COMMENT ON COLUMN login_history.user_id IS '사용자 ID - users 테이블 참조, CASCADE DELETE';
COMMENT ON COLUMN login_history.login_at IS '로그인 시도 일시';
COMMENT ON COLUMN login_history.ip_address IS '로그인 시도 IP 주소 - 이상 접근 탐지용, IPv6 지원 (최대 45자)';
COMMENT ON COLUMN login_history.user_agent IS '브라우저/디바이스 정보 - User-Agent 헤더값, 디바이스 추적용';
COMMENT ON COLUMN login_history.success IS '로그인 성공 여부 - true면 성공, false면 실패';
COMMENT ON COLUMN login_history.failure_reason IS '실패 사유 - 예: INVALID_PASSWORD, ACCOUNT_LOCKED, EMAIL_NOT_VERIFIED';

CREATE INDEX idx_login_history_user_id ON login_history (user_id);
COMMENT ON INDEX idx_login_history_user_id IS '사용자별 로그인 기록 조회 최적화 - 보안 이력 확인';

CREATE INDEX idx_login_history_login_at ON login_history (login_at DESC);
COMMENT ON INDEX idx_login_history_login_at IS '최근 로그인 기록 조회 최적화 - 실시간 모니터링 및 이상 패턴 탐지';

-- ============================================
-- 리프레시 토큰 테이블
-- ============================================
CREATE TABLE refresh_tokens
(
    id         BIGSERIAL PRIMARY KEY,
    user_id    BIGINT              NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    token      VARCHAR(500) UNIQUE NOT NULL,
    expires_at TIMESTAMP           NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    revoked_at TIMESTAMP
);

COMMENT ON TABLE refresh_tokens IS '리프레시 토큰 테이블 - JWT Refresh Token을 DB에 저장할 경우 사용 (Redis 대안)';

COMMENT ON COLUMN refresh_tokens.id IS '토큰 고유 식별자';
COMMENT ON COLUMN refresh_tokens.user_id IS '사용자 ID - users 테이블 참조, CASCADE DELETE';
COMMENT ON COLUMN refresh_tokens.token IS 'JWT Refresh Token - 긴 유효기간을 가진 토큰, UNIQUE 제약조건';
COMMENT ON COLUMN refresh_tokens.expires_at IS '토큰 만료 일시 - 일반적으로 7-30일, Access Token보다 긴 유효기간';
COMMENT ON COLUMN refresh_tokens.created_at IS '토큰 생성 일시';
COMMENT ON COLUMN refresh_tokens.revoked_at IS '토큰 폐기 일시 - NULL이면 유효, 값이 있으면 강제 로그아웃됨';

CREATE INDEX idx_refresh_tokens_token ON refresh_tokens (token);
COMMENT ON INDEX idx_refresh_tokens_token IS '토큰으로 조회 최적화 - Access Token 갱신 시 사용';

CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens (user_id);
COMMENT ON INDEX idx_refresh_tokens_user_id IS '사용자별 토큰 조회 최적화 - 전체 로그아웃 (모든 디바이스) 구현용';

CREATE INDEX idx_refresh_tokens_expires ON refresh_tokens (expires_at);
COMMENT ON INDEX idx_refresh_tokens_expires IS '만료 토큰 정리 최적화 - 배치 작업으로 만료된 토큰 삭제';

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
    created_at     TIMESTAMP DEFAULT NOW()
);

COMMENT ON TABLE outbox_events IS 'Transactional Outbox 패턴 구현 테이블 - 도메인 이벤트를 Kafka로 발행하기 전 저장';

COMMENT ON COLUMN outbox_events.id IS '이벤트 고유 식별자';
COMMENT ON COLUMN outbox_events.aggregate_type IS 'Aggregate 타입 - USER (Auth Service는 User만 관리)';
COMMENT ON COLUMN outbox_events.aggregate_id IS 'Aggregate 인스턴스 ID - 예: user_id';
COMMENT ON COLUMN outbox_events.event_type IS '이벤트 타입 - UserCreated, UserUpdated, UserDeleted, UserRoleChanged, UserBanned 등';
COMMENT ON COLUMN outbox_events.payload IS '이벤트 페이로드 - JSON 형식으로 이벤트 데이터 저장 (user_id, email, role 등)';
COMMENT ON COLUMN outbox_events.published IS '발행 여부 - false면 미발행, true면 Kafka로 발행 완료';
COMMENT ON COLUMN outbox_events.published_at IS 'Kafka 발행 완료 일시';
COMMENT ON COLUMN outbox_events.created_at IS '이벤트 생성 일시';

CREATE INDEX idx_outbox_unpublished ON outbox_events (created_at) WHERE published = false;
COMMENT ON INDEX idx_outbox_unpublished IS '미발행 이벤트 조회 최적화 - Partial Index, 배치 처리용';

-- ============================================
-- 샘플 데이터 (개발/테스트용)
-- ============================================
-- 권한 정의
INSERT INTO permissions (name, description, resource, action)
VALUES ('POST_READ', '게시글 읽기', 'POST', 'READ'),
       ('POST_CREATE', '게시글 작성', 'POST', 'CREATE'),
       ('POST_UPDATE', '게시글 수정', 'POST', 'UPDATE'),
       ('POST_DELETE', '게시글 삭제', 'POST', 'DELETE'),
       ('POST_PUBLISH', '게시글 발행', 'POST', 'PUBLISH'),
       ('COMMENT_READ', '댓글 읽기', 'COMMENT', 'READ'),
       ('COMMENT_CREATE', '댓글 작성', 'COMMENT', 'CREATE'),
       ('COMMENT_UPDATE', '댓글 수정', 'COMMENT', 'UPDATE'),
       ('COMMENT_DELETE', '댓글 삭제', 'COMMENT', 'DELETE'),
       ('COMMENT_APPROVE', '댓글 승인', 'COMMENT', 'APPROVE'),
       ('USER_READ', '사용자 조회', 'USER', 'READ'),
       ('USER_CREATE', '사용자 생성', 'USER', 'CREATE'),
       ('USER_UPDATE', '사용자 수정', 'USER', 'UPDATE'),
       ('USER_DELETE', '사용자 삭제', 'USER', 'DELETE'),
       ('USER_MANAGE', '사용자 관리', 'USER', 'MANAGE');

-- 역할별 권한 할당
-- ADMIN: 모든 권한
INSERT INTO role_permissions (role, permission_id)
SELECT 'ADMIN', id
FROM permissions;

-- GUEST: 기본 읽기/쓰기 권한
INSERT INTO role_permissions (role, permission_id)
SELECT 'GUEST', id
FROM permissions
WHERE name IN ('POST_READ', 'POST_CREATE', 'POST_UPDATE', 'COMMENT_READ', 'COMMENT_CREATE', 'COMMENT_UPDATE');

-- SUBSCRIBER: 읽기 + 댓글 권한
INSERT INTO role_permissions (role, permission_id)
SELECT 'SUBSCRIBER', id
FROM permissions
WHERE name IN ('POST_READ', 'COMMENT_READ', 'COMMENT_CREATE');

-- ============================================
-- 스키마 버전 정보
-- ============================================
COMMENT ON SCHEMA public IS 'Auth Service Database - Version 1.0.0, Created: 2025-01-09';