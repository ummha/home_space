# Blog Platform - MSA Project

## 📋 프로젝트 개요

### 프로젝트 정보

- **프로젝트명**: Blog Platform (블로그 플랫폼)
- **아키텍처**: Microservices Architecture (MSA)
- **개발 목적**: 학습 및 포트폴리오
- **주요 목표**:
  - 헥사고날 아키텍처 실전 적용
  - jOOQ 기반 영속성 계층 구현 (JPA 미사용)
  - MSA 패턴 학습 (이벤트 기반, CQRS 등)
  - 클린 아키텍처 원칙 준수

---

## 🛠 기술 스택

### Backend

- **Language**: Java 25
- **Framework**: Spring Boot 4.0.1
- **Build Tool**: Gradle 9.2.1
- **Database Access**: jOOQ 3.19.x (JPA 미사용)
- **Database**: PostgreSQL 16
- **Message Queue**: Apache Kafka (예정)
- **Cache**: Redis (예정)

### Infrastructure

- **Containerization**: Docker
- **Orchestration**: Kubernetes (K3s)
- **CI/CD**: GitHub Actions (예정)
- **Monitoring**: Prometheus + Grafana (예정)

### Development Tools

- **IDE**: IntelliJ IDEA
- **Version Control**: Git + GitHub
- **API Documentation**: Swagger/OpenAPI (예정)

---

## 🏗 아키텍처

### Overall Architecture

```
┌─────────────────────────────────────────────────────┐
│                   API Gateway                       │
│              (Spring Cloud Gateway)                 │
└───────────┬─────────────┬─────────────┬─────────────┘
            │             │             │
            ▼             ▼             ▼
    ┌───────────┐ ┌──────────┐ ┌──────────────┐
    │  Content  │ │   Auth   │ │ Notification │
    │  Service  │ │ Service  │ │   Service    │
    └─────┬─────┘ └────┬─────┘ └──────┬───────┘
          │            │               │
          ▼            ▼               ▼
    ┌─────────┐  ┌─────────┐    ┌─────────┐
    │content_db│ │ auth_db │    │notif_db │
    └──────────┘ └─────────┘    └─────────┘
          │            │               │
          └────────────┴───────────────┘
                       ▼
                  ┌─────────┐
                  │  Kafka  │
                  └─────────┘
```

### Hexagonal Architecture (각 서비스)

```
┌─────────────────────────────────────────────────────┐
│              Inbound Adapters                       │
│  ┌──────────────┐  ┌──────────────┐               │
│  │ REST API     │  │ Kafka        │               │
│  │ (Controller) │  │ (Consumer)   │               │
│  └──────┬───────┘  └──────┬───────┘               │
└─────────┼──────────────────┼─────────────────────────┘
          │                  │
          ▼                  ▼
┌─────────────────────────────────────────────────────┐
│          Application Layer (Use Cases)              │
│  - CreatePostUseCase                                │
│  - PublishPostUseCase                               │
│  - UpdatePostUseCase                                │
└─────────────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────┐
│              Domain Layer (핵심!)                   │
│  ┌────────────────────────────────────┐            │
│  │ Domain Models (순수 Java)          │            │
│  │  - Post (Aggregate Root)           │            │
│  │  - Slug (Value Object)             │            │
│  │  - Content (Value Object)          │            │
│  └────────────────────────────────────┘            │
│  ┌────────────────────────────────────┐            │
│  │ Outbound Ports (인터페이스)         │            │
│  │  - LoadPostPort                    │            │
│  │  - SavePostPort                    │            │
│  └────────────────────────────────────┘            │
└─────────────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────┐
│              Outbound Adapters                      │
│  ┌──────────────┐  ┌──────────────┐               │
│  │ jOOQ         │  │ Kafka        │               │
│  │ (Persistence)│  │ (Producer)   │               │
│  └──────────────┘  └──────────────┘               │
└─────────────────────────────────────────────────────┘
```

### Design Decisions

#### 1. JPA 엔티티 미사용 결정

**이유:**

- JPQL의 한계 (복잡한 쿼리, 동적 쿼리 어려움)
- 영속성 컨텍스트 복잡도 (LazyInitializationException, N+1 문제)
- 영속성 엔티티와 도메인 엔티티 간 의미 중복
- SQL 제어권 및 타입 안정성 확보

**대안: jOOQ**

- 타입 세이프한 SQL DSL
- 컴파일 타임 검증
- 명시적 쿼리 작성
- 순수 도메인 모델 분리

#### 2. 헥사고날 아키텍처 선택

**이유:**

- 도메인 로직과 인프라 완전 분리
- 테스트 용이성 (Ports & Adapters)
- 기술 스택 교체 유연성
- 비즈니스 로직 집중

---

## 📦 서비스 설계

### 1. Content Service (콘텐츠 서비스)

#### 책임

- 게시글 CRUD
- 카테고리/태그 관리
- 댓글 관리
- 전문 검색 (PostgreSQL FTS)
- 조회수 추적

#### Port: 8081

#### Database: content_db

#### 핵심 Aggregate

**Post (Aggregate Root)**

```java
public class Post {
    private Long id;
    private Slug slug;              // Value Object
    private String title;
    private Content content;        // Value Object
    private PostStatus status;
    private Statistics statistics;  // Value Object
    private List<Category> categories;
    private List<Tag> tags;
    
    // 비즈니스 메서드
    public void publish() { }
    public void updateTitle(String title) { }
    public void incrementViewCount() { }
    public boolean canDelete(Long userId, String role) { }
}
```

#### Domain Events

- `PostPublishedEvent`: 게시글 발행 시
- `PostUpdatedEvent`: 게시글 수정 시
- `PostDeletedEvent`: 게시글 삭제 시
- `CommentCreatedEvent`: 댓글 작성 시

---

### 2. Auth Service (인증 서비스)

#### 책임

- 사용자 인증 (로그인/로그아웃)
- JWT 토큰 발급/검증
- 회원 정보 관리
- 이메일 인증
- 비밀번호 재설정

#### Port: 8082

#### Database: auth_db

#### 핵심 Aggregate

**User (Aggregate Root)**

```java
public class User {
    private Long id;
    private Email email;           // Value Object
    private String username;
    private PasswordHash password; // Value Object
    private UserRole role;
    private UserStatus status;
    
    // 비즈니스 메서드
    public void activate() { }
    public void ban(String reason) { }
    public boolean verifyPassword(String rawPassword) { }
}
```

#### Domain Events

- `UserCreatedEvent`: 회원가입 시
- `UserLoginEvent`: 로그인 시
- `UserRoleChangedEvent`: 권한 변경 시

---

### 3. Notification Service (알림 서비스)

#### 책임

- 이메일 발송
- 알림 구독 관리
- 알림 템플릿 관리
- 이벤트 기반 알림 발송

#### Port: 8083

#### Database: notification_db

#### 핵심 기능

- 회원가입 환영 메일
- 이메일 인증 메일
- 댓글 알림
- 비밀번호 재설정 메일

---

## 🗄 데이터베이스 설계

### Content Service DB (content_db)

#### 핵심 테이블

**posts** (게시글)

```sql
- id: BIGSERIAL PRIMARY KEY
- title: VARCHAR(200)
- slug: VARCHAR(250) UNIQUE
- content: TEXT
- status: VARCHAR(20) (DRAFT, PUBLISHED, ARCHIVED)
- published_at: TIMESTAMP
- view_count, like_count, comment_count: INT
- created_at, updated_at, deleted_at: TIMESTAMP
```

**categories** (카테고리)

```sql
- id: BIGSERIAL PRIMARY KEY
- name: VARCHAR(100)
- slug: VARCHAR(100) UNIQUE
- parent_id: BIGINT (Self-reference FK)
- display_order: INT
```

**tags** (태그)

```sql
- id: BIGSERIAL PRIMARY KEY
- name: VARCHAR(50) UNIQUE
- slug: VARCHAR(50) UNIQUE
- usage_count: INT
```

**post_categories, post_tags** (다대다 관계)
**comments** (댓글 - Self-reference FK)
**post_views** (조회수 추적 - 일별 중복 방지)
**outbox_events** (이벤트 발행용)

#### 인덱스 전략

```sql
-- 성능 최적화
CREATE INDEX idx_posts_status ON posts(status);
CREATE INDEX idx_posts_published_at ON posts(published_at DESC) 
  WHERE status = 'PUBLISHED';

-- 전문 검색 (Full Text Search)
CREATE INDEX idx_posts_search_en ON posts 
  USING gin(to_tsvector('english', title || ' ' || content));
  
CREATE INDEX idx_posts_search_ko ON posts 
  USING gin(to_tsvector('simple', title || ' ' || content));
```

---

### Auth Service DB (auth_db)

#### 핵심 테이블

**users** (사용자)

```sql
- id: BIGSERIAL PRIMARY KEY
- email: VARCHAR(200) UNIQUE
- username: VARCHAR(50) UNIQUE
- password_hash: VARCHAR(255)
- role: VARCHAR(20) (ADMIN, GUEST, SUBSCRIBER)
- status: VARCHAR(20) (ACTIVE, INACTIVE, BANNED)
- email_verified: BOOLEAN
- last_login_at, last_login_ip: 보안 추적
```

**permissions** (권한)
**role_permissions** (역할-권한 매핑)
**email_verifications** (이메일 인증)
**password_resets** (비밀번호 재설정)
**login_history** (로그인 이력 - 보안 감사)
**refresh_tokens** (리프레시 토큰)

#### RBAC (Role-Based Access Control)

```
Roles:
- ADMIN: 모든 권한
- GUEST: 기본 읽기/쓰기
- SUBSCRIBER: 읽기 + 댓글

Permissions:
- POST_CREATE, POST_UPDATE, POST_DELETE, POST_PUBLISH
- COMMENT_CREATE, COMMENT_UPDATE, COMMENT_APPROVE
- USER_MANAGE
```

---

## 🔐 인증/인가 아키텍처

### 하이브리드 방식 (추천!)

```
┌─────────────────────────────────────┐
│     API Gateway                     │
│  ✅ 토큰 검증 (Auth Service)        │
│  ✅ 기본 RBAC (role 기반)           │
│  ✅ X-User-Id, X-User-Role 헤더     │
└──────────┬──────────────────────────┘
           ↓
┌─────────────────────────────────────┐
│     Content Service                 │
│  ✅ 세부 인가 (리소스 레벨)         │
│  ✅ "작성자인가?" 체크              │
│  ✅ "상태가 적절한가?" 체크         │
└─────────────────────────────────────┘
```

### 인증 플로우

```
1. 사용자 로그인
   → Auth Service: 인증 + JWT 발급

2. API 호출
   → Gateway: JWT 검증 + 기본 권한 체크
   → Service: 세부 권한 체크 + 비즈니스 로직

3. 토큰 갱신
   → Auth Service: Refresh Token → 새 Access Token
```

---

## 🔧 개발 환경 설정

### Prerequisites

```bash
- Java 25 (Eclipse Temurin)
- Docker & Docker Compose
- PostgreSQL 16
- Gradle 9.2.1+
```

### 프로젝트 구조

```
blog-msa/
├── gradle/
│   └── jooq.gradle              # jOOQ 공유 설정
├── services/
│   ├── content-service/
│   │   ├── build.gradle
│   │   ├── gradle.properties
│   │   └── src/
│   │       ├── main/
│   │       │   ├── java/
│   │       │   │   └── com/ummha/content/
│   │       │   │       ├── domain/
│   │       │   │       │   ├── model/          # 순수 도메인 모델
│   │       │   │       │   ├── port/
│   │       │   │       │   │   ├── in/         # Use Cases
│   │       │   │       │   │   └── out/        # Repository Ports
│   │       │   │       │   ├── service/        # Domain Service
│   │       │   │       │   └── event/          # Domain Events
│   │       │   │       ├── application/        # Application Service
│   │       │   │       │   └── service/
│   │       │   │       ├── adapter/
│   │       │   │       │   ├── in/
│   │       │   │       │   │   └── web/        # REST Controllers
│   │       │   │       │   └── out/
│   │       │   │       │       ├── persistence/ # jOOQ Adapter
│   │       │   │       │       └── event/       # Kafka Producer
│   │       │   │       └── infrastructure/     # Config
│   │       │   ├── generated/                  # jOOQ 생성 코드
│   │       │   └── resources/
│   │       └── test/
│   ├── auth-service/
│   └── notification-service/
├── infrastructure/
│   ├── docker-compose.yml
│   └── k8s/
├── docs/
│   ├── PRD.md                   # 이 문서
│   ├── API.md                   # API 명세
│   └── ARCHITECTURE.md          # 상세 아키텍처
└── settings.gradle
```

### 패키지 명명 규칙

```
com.ummha.{service}.domain.model        - 도메인 모델
com.ummha.{service}.domain.port.in      - Inbound Port
com.ummha.{service}.domain.port.out     - Outbound Port
com.ummha.{service}.application.service - Application Service
com.ummha.{service}.adapter.in.web      - REST Controller
com.ummha.{service}.adapter.out.persistence - jOOQ Adapter
```

---

## 🚀 빌드 및 실행

### 로컬 개발 환경

```bash
# 1. PostgreSQL 실행
docker-compose up -d postgres

# 2. DB 스키마 생성
psql -h localhost -p 5433 -U postgres -f docs/schema/content-service.sql

# 3. jOOQ 코드 생성
cd services/content-service
./gradlew generateJooq

# 4. 빌드
./gradlew build

# 5. 실행
./gradlew bootRun
```

### jOOQ 코드 생성

```bash
# 기본 (로컬 DB)
./gradlew generateJooq

# 환경별
./gradlew generateJooq -Penv=dev
./gradlew generateJooq -Penv=prod

# 환경 변수
export JOOQ_DB_URL=jdbc:postgresql://localhost:5433/content_db
export JOOQ_DB_USER=postgres
export JOOQ_DB_PASSWORD=postgres
./gradlew generateJooq

# 정리 후 재생성
./gradlew cleanJooq generateJooq
```

### Gradle Properties

**gradle.properties** (로컬 - Git 커밋)

```properties
jooq.db.url=jdbc:postgresql://localhost:5433/content_db
jooq.db.user=postgres
jooq.db.password=postgres
jooq.package=com.ummha.content.adapter.out.persistence.jooq
```

**gradle-dev.properties** (개발 서버 - Git 무시)

```properties
jooq.db.url=jdbc:postgresql://dev-server:5432/content_db
jooq.db.user=dev_user
jooq.db.password=dev_password
```

---

## 📝 개발 가이드

### Domain Model 작성

```java
// ✅ 좋은 예: 순수 Java, 비즈니스 로직 집중
public class Post {
    private Long id;
    private Slug slug;
    private Content content;
    
    public void publish() {
        validateForPublish();
        this.status = PostStatus.PUBLISHED;
        this.publishedAt = LocalDateTime.now();
    }
    
    private void validateForPublish() {
        if (title == null || content == null) {
            throw new IllegalStateException("제목과 내용 필수");
        }
    }
}

// ❌ 나쁜 예: 인프라 의존성
@Entity  // ❌ JPA 의존성
public class Post {
    @Id @GeneratedValue  // ❌
    private Long id;
}
```

### Persistence Adapter 작성

```java
@Component
@RequiredArgsConstructor
public class PostPersistenceAdapter implements 
    LoadPostPort, SavePostPort {
    
    private final DSLContext dsl;
    private final PostPersistenceMapper mapper;
    
    @Override
    public Optional<Post> loadById(Long id) {
        return dsl
            .selectFrom(POSTS)
            .where(POSTS.ID.eq(id))
            .fetchOptional()
            .map(mapper::toDomain);  // Record → Domain
    }
    
    @Override
    public Long save(Post post) {
        var record = dsl.newRecord(POSTS);
        mapper.toRecord(post, record);  // Domain → Record
        record.store();
        return record.getId();
    }
}
```

### Use Case 작성

```java
@Service
@RequiredArgsConstructor
public class PostService implements CreatePostUseCase {
    
    private final LoadPostPort loadPostPort;
    private final SavePostPort savePostPort;
    private final PublishEventPort publishEventPort;
    
    @Override
    @Transactional
    public Long createPost(CreatePostCommand command) {
        // 1. 도메인 모델 생성
        Post post = Post.create(
            command.title(),
            command.content(),
            command.authorId(),
            command.authorName()
        );
        
        // 2. 영속화
        Long postId = savePostPort.save(post);
        
        // 3. 이벤트 발행
        publishEventPort.publish(
            new PostCreatedEvent(postId, post.getAuthorId())
        );
        
        return postId;
    }
}
```

---

## 🎯 다음 단계 (Roadmap)

### Phase 1: MVP (현재)

- [x] 프로젝트 구조 설계
- [x] DB 스키마 설계
- [x] jOOQ 설정
- [ ] Domain Model 구현
- [ ] Persistence Adapter 구현
- [ ] REST API 구현
- [ ] 기본 CRUD 완성

### Phase 2: 고급 기능

- [ ] Kafka 이벤트 기반 통신
- [ ] Redis 캐싱
- [ ] PostgreSQL FTS 구현
- [ ] API Gateway 구현
- [ ] JWT 인증 구현

### Phase 3: 운영

- [ ] Docker 컨테이너화
- [ ] K8s 배포
- [ ] CI/CD 파이프라인
- [ ] 모니터링 (Prometheus + Grafana)
- [ ] 로깅 (ELK Stack)

### Phase 4: 최적화

- [ ] 성능 테스트
- [ ] 부하 테스트
- [ ] 쿼리 최적화
- [ ] 캐시 전략 개선

---

## 📚 참고 자료

### 아키텍처

- Clean Architecture (Robert C. Martin)
- Hexagonal Architecture (Alistair Cockburn)
- Domain-Driven Design (Eric Evans)
- TDD (Test-Driven Development)

### 기술 문서

- [jOOQ Official Documentation](https://www.jooq.org/doc/latest/)
- [Spring Boot Reference](https://docs.spring.io/spring-boot/index.html)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Kafka Documentation](https://kafka.apache.org/)
- [Redis Documentation](https://redis.io/)

### 프로젝트 문서

- [API 명세](./API.md) (예정)
- [아키텍처 상세](./ARCHITECTURE.md) (예정)
- [배포 가이드](./DEPLOYMENT.md) (예정)

---

## 👥 Contributors

- 민서 ([@ummha](https://github.com/ummha))

---

**Last Updated**: 2025-01-17
**Version**: 1.0.0
