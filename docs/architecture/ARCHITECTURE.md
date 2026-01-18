# Ummha Studio - Architecture Document

> **Version**: 1.0.0
> **Last Updated**: 2025-01-18
> **Related**: [PRD.md](../../PRD.md)

---

## 1. 시스템 아키텍처 개요

### 1.1 Overall Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     API Gateway                          │
│                (Spring Cloud Gateway)                    │
│              Port: 8080                                  │
└───────────┬─────────────┬─────────────┬─────────────────┘
            │             │             │
            ▼             ▼             ▼
    ┌───────────┐ ┌──────────┐ ┌──────────────┐
    │  Content  │ │   Auth   │ │ Notification │
    │  Service  │ │ Service  │ │   Service    │
    │  :8081    │ │  :8082   │ │    :8083     │
    └─────┬─────┘ └────┬─────┘ └──────┬───────┘
          │            │              │
          ▼            ▼              ▼
    ┌──────────┐ ┌─────────┐   ┌──────────┐
    │content_db│ │ auth_db │   │notif_db  │
    │PostgreSQL│ │PostgreSQL│  │PostgreSQL│
    └──────────┘ └─────────┘   └──────────┘
          │            │              │
          └────────────┴──────────────┘
                       │
                       ▼
                 ┌─────────┐
                 │  Kafka  │
                 │ Cluster │
                 └─────────┘
```

### 1.2 기술 스택

| 계층 | 기술 | 버전 |
|------|------|------|
| Language | Java | 25 |
| Framework | Spring Boot | 4.0.1 |
| Build Tool | Gradle | 9.2.1 |
| Database | PostgreSQL | 16 |
| Database Access | jOOQ | 3.19.x |
| Message Queue | Apache Kafka | - |
| Cache | Redis | - |
| Container | Docker | - |
| Orchestration | Kubernetes (K3s) | - |

---

## 2. 헥사고날 아키텍처

### 2.1 아키텍처 다이어그램

```
┌─────────────────────────────────────────────────────────┐
│              Inbound Adapters (Driving)                 │
│  ┌──────────────┐  ┌──────────────┐                    │
│  │ REST API     │  │ Kafka        │                    │
│  │ (Controller) │  │ (Consumer)   │                    │
│  └──────┬───────┘  └──────┬───────┘                    │
└─────────┼──────────────────┼────────────────────────────┘
          │                  │
          ▼                  ▼
┌─────────────────────────────────────────────────────────┐
│                   Inbound Ports                         │
│  ┌────────────────────────────────────────────┐        │
│  │ Use Cases (인터페이스)                      │        │
│  │  - CreatePostUseCase                       │        │
│  │  - PublishPostUseCase                      │        │
│  │  - UpdatePostUseCase                       │        │
│  │  - DeletePostUseCase                       │        │
│  └────────────────────────────────────────────┘        │
└─────────────────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────┐
│          Application Layer (Use Case 구현체)            │
│  ┌────────────────────────────────────────────┐        │
│  │ Application Services                        │        │
│  │  - PostService (implements Use Cases)      │        │
│  │  - CategoryService                         │        │
│  │  - TagService                              │        │
│  └────────────────────────────────────────────┘        │
└─────────────────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────┐
│              Domain Layer (핵심 비즈니스)               │
│  ┌────────────────────────────────────────────┐        │
│  │ Domain Models (순수 Java)                   │        │
│  │  - Post (Aggregate Root)                   │        │
│  │  - Category (Entity)                       │        │
│  │  - Tag (Entity)                            │        │
│  │  - Comment (Entity)                        │        │
│  │  - Slug (Value Object)                     │        │
│  │  - Content (Value Object)                  │        │
│  │  - Statistics (Value Object)               │        │
│  └────────────────────────────────────────────┘        │
│  ┌────────────────────────────────────────────┐        │
│  │ Domain Events                               │        │
│  │  - PostCreatedEvent                        │        │
│  │  - PostPublishedEvent                      │        │
│  │  - PostUpdatedEvent                        │        │
│  │  - PostDeletedEvent                        │        │
│  └────────────────────────────────────────────┘        │
└─────────────────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────┐
│                   Outbound Ports                        │
│  ┌────────────────────────────────────────────┐        │
│  │ Repository Ports (인터페이스)               │        │
│  │  - LoadPostPort                            │        │
│  │  - SavePostPort                            │        │
│  │  - PublishEventPort                        │        │
│  └────────────────────────────────────────────┘        │
└─────────────────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────┐
│              Outbound Adapters (Driven)                 │
│  ┌──────────────┐  ┌──────────────┐                    │
│  │ jOOQ         │  │ Kafka        │                    │
│  │ (Persistence)│  │ (Producer)   │                    │
│  └──────────────┘  └──────────────┘                    │
└─────────────────────────────────────────────────────────┘
```

### 2.2 계층별 책임

| 계층 | 책임 | 의존성 |
|------|------|--------|
| **Inbound Adapters** | 외부 요청 수신 (REST, Kafka) | Application Layer |
| **Inbound Ports** | Use Case 인터페이스 정의 | - |
| **Application Layer** | 비즈니스 흐름 조율 | Domain, Outbound Ports |
| **Domain Layer** | 핵심 비즈니스 로직 | 없음 (순수 Java) |
| **Outbound Ports** | 외부 시스템 인터페이스 정의 | - |
| **Outbound Adapters** | 외부 시스템 연동 (DB, Kafka) | Outbound Ports |

---

## 3. 설계 결정 사항

### 3.1 JPA 미사용 결정

#### 문제점

| 문제 | 설명 |
|------|------|
| JPQL 한계 | 복잡한 쿼리, 동적 쿼리 작성 어려움 |
| 영속성 컨텍스트 복잡도 | LazyInitializationException, N+1 문제 |
| 의미 중복 | 영속성 엔티티와 도메인 엔티티 역할 혼재 |
| SQL 제어권 부족 | 생성되는 SQL 예측 어려움 |

#### 대안: jOOQ

| 장점 | 설명 |
|------|------|
| 타입 세이프 | 컴파일 타임 SQL 검증 |
| 명시적 쿼리 | 생성되는 SQL 완전 제어 |
| 도메인 분리 | 영속성과 도메인 모델 완전 분리 |
| 학습 가치 | SQL 이해도 향상 |

### 3.2 헥사고날 아키텍처 선택

| 이유 | 효과 |
|------|------|
| 도메인 로직 분리 | 인프라 변경에 영향받지 않음 |
| 테스트 용이성 | Port 기반 Mocking 가능 |
| 기술 교체 유연성 | Adapter만 교체하면 됨 |
| 비즈니스 집중 | 도메인 모델에 비즈니스 로직 집중 |

### 3.3 서비스 분리 기준

```
┌─────────────────────────────────────────────────┐
│     경계 컨텍스트 (Bounded Context)             │
├─────────────────────────────────────────────────┤
│  Content Context     │  Auth Context            │
│  - Post              │  - User                  │
│  - Category          │  - Permission            │
│  - Tag               │  - Role                  │
│  - Comment           │  - Token                 │
├──────────────────────┼──────────────────────────┤
│  Notification Context                           │
│  - EmailTemplate                                │
│  - NotificationLog                              │
└─────────────────────────────────────────────────┘
```

---

## 4. 서비스별 설계

### 4.1 Content Service

#### 책임
- 게시글 CRUD
- 카테고리/태그 관리
- 댓글 관리
- 전문 검색 (PostgreSQL FTS)
- 조회수 추적

#### 핵심 Aggregate: Post

```java
public class Post {
    private Long id;
    private Slug slug;              // Value Object
    private String title;
    private Content content;        // Value Object
    private PostStatus status;      // DRAFT, PUBLISHED, ARCHIVED
    private Statistics statistics;  // Value Object (viewCount, likeCount, commentCount)
    private List<Category> categories;
    private List<Tag> tags;
    private Long authorId;
    private String authorName;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private LocalDateTime publishedAt;

    // 비즈니스 메서드
    public void publish() {
        validateForPublish();
        this.status = PostStatus.PUBLISHED;
        this.publishedAt = LocalDateTime.now();
    }

    public void updateTitle(String title) {
        this.title = title;
        this.slug = Slug.from(title);
    }

    public void incrementViewCount() {
        this.statistics = statistics.withIncrementedViewCount();
    }

    public boolean canDelete(Long userId, String role) {
        return this.authorId.equals(userId) || "ADMIN".equals(role);
    }

    private void validateForPublish() {
        if (title == null || content == null) {
            throw new IllegalStateException("제목과 내용은 필수입니다");
        }
    }
}
```

#### Domain Events

| 이벤트 | 트리거 | 구독자 |
|--------|--------|--------|
| `PostCreatedEvent` | 게시글 생성 | - |
| `PostPublishedEvent` | 게시글 발행 | Notification Service |
| `PostUpdatedEvent` | 게시글 수정 | - |
| `PostDeletedEvent` | 게시글 삭제 | - |
| `CommentCreatedEvent` | 댓글 작성 | Notification Service |

### 4.2 Auth Service

#### 책임
- 사용자 인증 (로그인/로그아웃)
- JWT 토큰 발급/검증
- 회원 정보 관리
- 이메일 인증
- 비밀번호 재설정

#### 핵심 Aggregate: User

```java
public class User {
    private Long id;
    private Email email;           // Value Object
    private String username;
    private PasswordHash password; // Value Object
    private UserRole role;         // ADMIN, GUEST, SUBSCRIBER
    private UserStatus status;     // ACTIVE, INACTIVE, BANNED
    private boolean emailVerified;
    private LocalDateTime lastLoginAt;
    private String lastLoginIp;

    // 비즈니스 메서드
    public void activate() {
        this.status = UserStatus.ACTIVE;
        this.emailVerified = true;
    }

    public void ban(String reason) {
        this.status = UserStatus.BANNED;
    }

    public boolean verifyPassword(String rawPassword) {
        return password.matches(rawPassword);
    }

    public void recordLogin(String ip) {
        this.lastLoginAt = LocalDateTime.now();
        this.lastLoginIp = ip;
    }
}
```

#### Domain Events

| 이벤트 | 트리거 | 구독자 |
|--------|--------|--------|
| `UserCreatedEvent` | 회원가입 | Notification Service |
| `UserLoginEvent` | 로그인 | - |
| `UserRoleChangedEvent` | 권한 변경 | - |
| `PasswordResetRequestedEvent` | 비밀번호 재설정 요청 | Notification Service |

### 4.3 Notification Service

#### 책임
- 이메일 발송
- 알림 구독 관리
- 알림 템플릿 관리
- 이벤트 기반 알림 처리

#### 핵심 기능

| 기능 | 트리거 이벤트 |
|------|--------------|
| 환영 이메일 | `UserCreatedEvent` |
| 이메일 인증 | `UserCreatedEvent` |
| 댓글 알림 | `CommentCreatedEvent` |
| 비밀번호 재설정 | `PasswordResetRequestedEvent` |

---

## 5. 인증/인가 아키텍처

### 5.1 하이브리드 방식

```
┌─────────────────────────────────────┐
│     API Gateway                     │
│  ✅ JWT 토큰 검증 (Auth Service)    │
│  ✅ 기본 RBAC (role 기반)           │
│  ✅ X-User-Id, X-User-Role 헤더     │
└──────────┬──────────────────────────┘
           │
           ▼
┌─────────────────────────────────────┐
│     Content Service                 │
│  ✅ 세부 인가 (리소스 레벨)         │
│  ✅ "작성자인가?" 체크              │
│  ✅ "상태가 적절한가?" 체크         │
└─────────────────────────────────────┘
```

### 5.2 인증 플로우

```
1. 사용자 로그인
   Client ──POST /auth/login──▶ Auth Service
                                    │
                                    ▼
                              JWT 발급 (Access + Refresh)
                                    │
                              ◀─────┘

2. API 호출
   Client ──GET /posts/{id}──▶ API Gateway
                                    │
                                    ▼
                              JWT 검증 (Auth Service 호출)
                              기본 권한 체크 (RBAC)
                              X-User-Id, X-User-Role 헤더 추가
                                    │
                                    ▼
                              Content Service
                              세부 권한 체크 (리소스 레벨)
                              비즈니스 로직 실행
                                    │
                              ◀─────┘

3. 토큰 갱신
   Client ──POST /auth/refresh──▶ Auth Service
                                       │
                                       ▼
                                 Refresh Token 검증
                                 새 Access Token 발급
                                       │
                                 ◀─────┘
```

### 5.3 RBAC (Role-Based Access Control)

#### 역할 정의

| 역할 | 설명 | 권한 |
|------|------|------|
| **ADMIN** | 관리자 | 모든 권한 |
| **GUEST** | 일반 작성자 | 읽기/쓰기 (본인 리소스) |
| **SUBSCRIBER** | 구독자 | 읽기 + 댓글 |

#### 권한 매트릭스

| 권한 | ADMIN | GUEST | SUBSCRIBER |
|------|-------|-------|------------|
| POST_CREATE | O | O | X |
| POST_UPDATE | O | 본인만 | X |
| POST_DELETE | O | 본인만 | X |
| POST_PUBLISH | O | O | X |
| COMMENT_CREATE | O | O | O |
| COMMENT_UPDATE | O | 본인만 | 본인만 |
| COMMENT_APPROVE | O | X | X |
| USER_MANAGE | O | X | X |

---

## 6. 데이터베이스 설계

### 6.1 Content Service DB (content_db)

#### ERD 개요

```
┌──────────────┐     ┌─────────────────┐     ┌──────────┐
│    posts     │────<│ post_categories │>────│categories│
└──────────────┘     └─────────────────┘     └──────────┘
       │                                            │
       │             ┌─────────────────┐            │
       └────────────<│   post_tags     │>───────────┘
       │             └─────────────────┘
       │                                     ┌──────────┐
       │                                     │   tags   │
       │                                     └──────────┘
       │
       └────────────<┌──────────────┐
                     │   comments   │──┐ (self-reference)
                     └──────────────┘◀─┘
```

#### posts (게시글)

```sql
CREATE TABLE posts (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    slug VARCHAR(250) NOT NULL UNIQUE,
    content TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',  -- DRAFT, PUBLISHED, ARCHIVED
    author_id BIGINT NOT NULL,
    author_name VARCHAR(100) NOT NULL,
    view_count INT NOT NULL DEFAULT 0,
    like_count INT NOT NULL DEFAULT 0,
    comment_count INT NOT NULL DEFAULT 0,
    published_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,  -- Soft delete

    CONSTRAINT chk_posts_status CHECK (status IN ('DRAFT', 'PUBLISHED', 'ARCHIVED'))
);

-- 인덱스
CREATE INDEX idx_posts_status ON posts(status);
CREATE INDEX idx_posts_author_id ON posts(author_id);
CREATE INDEX idx_posts_published_at ON posts(published_at DESC)
    WHERE status = 'PUBLISHED' AND deleted_at IS NULL;

-- 전문 검색 인덱스
CREATE INDEX idx_posts_search_en ON posts
    USING gin(to_tsvector('english', title || ' ' || content));
CREATE INDEX idx_posts_search_ko ON posts
    USING gin(to_tsvector('simple', title || ' ' || content));
```

#### categories (카테고리)

```sql
CREATE TABLE categories (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    parent_id BIGINT REFERENCES categories(id),  -- 계층형
    display_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

#### tags (태그)

```sql
CREATE TABLE tags (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    slug VARCHAR(50) NOT NULL UNIQUE,
    usage_count INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

#### comments (댓글)

```sql
CREATE TABLE comments (
    id BIGSERIAL PRIMARY KEY,
    post_id BIGINT NOT NULL REFERENCES posts(id),
    parent_id BIGINT REFERENCES comments(id),  -- 대댓글
    author_id BIGINT NOT NULL,
    author_name VARCHAR(100) NOT NULL,
    content TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',  -- PENDING, APPROVED, REJECTED
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);

CREATE INDEX idx_comments_post_id ON comments(post_id);
CREATE INDEX idx_comments_parent_id ON comments(parent_id);
```

#### outbox_events (이벤트 아웃박스)

```sql
CREATE TABLE outbox_events (
    id BIGSERIAL PRIMARY KEY,
    aggregate_type VARCHAR(100) NOT NULL,
    aggregate_id BIGINT NOT NULL,
    event_type VARCHAR(100) NOT NULL,
    payload JSONB NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    published_at TIMESTAMP,

    CONSTRAINT chk_outbox_published CHECK (
        published_at IS NULL OR published_at >= created_at
    )
);

CREATE INDEX idx_outbox_unpublished ON outbox_events(created_at)
    WHERE published_at IS NULL;
```

### 6.2 Auth Service DB (auth_db)

#### users (사용자)

```sql
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(200) NOT NULL UNIQUE,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'SUBSCRIBER',  -- ADMIN, GUEST, SUBSCRIBER
    status VARCHAR(20) NOT NULL DEFAULT 'INACTIVE',  -- ACTIVE, INACTIVE, BANNED
    email_verified BOOLEAN NOT NULL DEFAULT FALSE,
    last_login_at TIMESTAMP,
    last_login_ip VARCHAR(45),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_users_role CHECK (role IN ('ADMIN', 'GUEST', 'SUBSCRIBER')),
    CONSTRAINT chk_users_status CHECK (status IN ('ACTIVE', 'INACTIVE', 'BANNED'))
);
```

#### refresh_tokens (리프레시 토큰)

```sql
CREATE TABLE refresh_tokens (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id),
    token VARCHAR(500) NOT NULL UNIQUE,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    revoked_at TIMESTAMP
);

CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_expires_at ON refresh_tokens(expires_at);
```

#### email_verifications (이메일 인증)

```sql
CREATE TABLE email_verifications (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id),
    token VARCHAR(100) NOT NULL UNIQUE,
    expires_at TIMESTAMP NOT NULL,
    verified_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

#### login_history (로그인 이력)

```sql
CREATE TABLE login_history (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id),
    ip_address VARCHAR(45) NOT NULL,
    user_agent TEXT,
    success BOOLEAN NOT NULL,
    failure_reason VARCHAR(100),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_login_history_user_id ON login_history(user_id);
CREATE INDEX idx_login_history_created_at ON login_history(created_at DESC);
```

---

## 7. 패키지 구조

### 7.1 서비스별 패키지 구조

```
services/
├── content-service/
│   └── src/main/java/com/ummha/content/
│       ├── domain/
│       │   ├── model/              # 도메인 모델 (순수 Java)
│       │   │   ├── Post.java
│       │   │   ├── Category.java
│       │   │   ├── Tag.java
│       │   │   ├── Comment.java
│       │   │   ├── Slug.java       # Value Object
│       │   │   ├── Content.java    # Value Object
│       │   │   └── Statistics.java # Value Object
│       │   ├── port/
│       │   │   ├── in/             # Inbound Ports (Use Cases)
│       │   │   │   ├── CreatePostUseCase.java
│       │   │   │   ├── PublishPostUseCase.java
│       │   │   │   └── UpdatePostUseCase.java
│       │   │   └── out/            # Outbound Ports
│       │   │       ├── LoadPostPort.java
│       │   │       ├── SavePostPort.java
│       │   │       └── PublishEventPort.java
│       │   └── event/              # Domain Events
│       │       ├── PostCreatedEvent.java
│       │       └── PostPublishedEvent.java
│       ├── application/
│       │   └── service/            # Application Services
│       │       ├── PostService.java
│       │       └── CategoryService.java
│       ├── adapter/
│       │   ├── in/
│       │   │   └── web/            # REST Controllers
│       │   │       ├── PostController.java
│       │   │       └── dto/
│       │   └── out/
│       │       ├── persistence/    # jOOQ Adapters
│       │       │   ├── PostPersistenceAdapter.java
│       │       │   └── mapper/
│       │       └── event/          # Kafka Producer
│       │           └── KafkaEventPublisher.java
│       └── infrastructure/
│           └── config/             # Configuration
│               ├── JooqConfig.java
│               └── KafkaConfig.java
├── auth-service/
│   └── src/main/java/com/ummha/auth/
│       └── ... (동일 구조)
└── notification-service/
    └── src/main/java/com/ummha/notification/
        └── ... (동일 구조)
```

### 7.2 패키지 명명 규칙

| 패턴 | 설명 |
|------|------|
| `com.ummha.{service}.domain.model` | 도메인 모델 (Entity, Value Object) |
| `com.ummha.{service}.domain.port.in` | Inbound Port (Use Case 인터페이스) |
| `com.ummha.{service}.domain.port.out` | Outbound Port (Repository 인터페이스) |
| `com.ummha.{service}.domain.event` | Domain Events |
| `com.ummha.{service}.application.service` | Application Service (Use Case 구현체) |
| `com.ummha.{service}.adapter.in.web` | REST Controller |
| `com.ummha.{service}.adapter.out.persistence` | jOOQ Persistence Adapter |
| `com.ummha.{service}.adapter.out.event` | Kafka Event Publisher |
| `com.ummha.{service}.infrastructure.config` | Configuration Classes |

---

## 8. 참고 자료

### 아키텍처 참고
- Clean Architecture (Robert C. Martin)
- Hexagonal Architecture (Alistair Cockburn)
- Domain-Driven Design (Eric Evans)

### 기술 문서
- [jOOQ Official Documentation](https://www.jooq.org/doc/latest/)
- [Spring Boot Reference](https://docs.spring.io/spring-boot/index.html)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Apache Kafka Documentation](https://kafka.apache.org/documentation/)

---

**Last Updated**: 2025-01-18
**Version**: 1.0.0
