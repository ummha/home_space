# Ummha Studio - API Specification

> **Version**: 1.0.0
> **Last Updated**: 2025-01-18
> **Status**: Draft (설계 중)
> **Related**: [PRD.md](../../PRD.md) | [ARCHITECTURE.md](../architecture/ARCHITECTURE.md)

---

## 1. API 설계 원칙

### 1.1 RESTful 설계 원칙

| 원칙 | 설명 |
|------|------|
| **Resource-Oriented** | URI는 리소스를 표현, 동사 미사용 |
| **HTTP Methods** | GET(조회), POST(생성), PUT(전체수정), PATCH(부분수정), DELETE(삭제) |
| **Stateless** | 서버는 클라이언트 상태를 저장하지 않음 |
| **HATEOAS** | 응답에 관련 리소스 링크 포함 (선택적) |

### 1.2 URI 명명 규칙

```
# 기본 형식
/{service}/api/v{version}/{resource}

# 예시
/content/api/v1/posts
/content/api/v1/posts/{id}
/content/api/v1/posts/{id}/comments
/auth/api/v1/users
/auth/api/v1/auth/login
```

### 1.3 버전 관리

- URI Path 기반 버전 관리: `/api/v1/`, `/api/v2/`
- 하위 호환성 유지 원칙
- 메이저 변경 시 새 버전 생성

### 1.4 인증 방식

| 방식 | 헤더 | 용도 |
|------|------|------|
| **Bearer Token** | `Authorization: Bearer {token}` | API 인증 |
| **Refresh Token** | Request Body | 토큰 갱신 |

---

## 2. 공통 응답 형식

### 2.1 성공 응답

```json
{
  "success": true,
  "data": { ... },
  "meta": {
    "timestamp": "2025-01-18T12:00:00Z",
    "requestId": "abc-123"
  }
}
```

### 2.2 목록 응답 (페이지네이션)

```json
{
  "success": true,
  "data": [ ... ],
  "pagination": {
    "page": 1,
    "size": 20,
    "totalElements": 100,
    "totalPages": 5,
    "hasNext": true,
    "hasPrevious": false
  },
  "meta": {
    "timestamp": "2025-01-18T12:00:00Z"
  }
}
```

### 2.3 에러 응답

```json
{
  "success": false,
  "error": {
    "code": "POST_NOT_FOUND",
    "message": "게시글을 찾을 수 없습니다",
    "details": [
      {
        "field": "id",
        "message": "존재하지 않는 게시글 ID입니다"
      }
    ]
  },
  "meta": {
    "timestamp": "2025-01-18T12:00:00Z",
    "requestId": "abc-123"
  }
}
```

---

## 3. 에러 코드 정의

### 3.1 공통 에러 코드

| HTTP Status | Code | Message |
|-------------|------|---------|
| 400 | `INVALID_REQUEST` | 잘못된 요청입니다 |
| 400 | `VALIDATION_ERROR` | 입력값 검증에 실패했습니다 |
| 401 | `UNAUTHORIZED` | 인증이 필요합니다 |
| 401 | `INVALID_TOKEN` | 유효하지 않은 토큰입니다 |
| 401 | `EXPIRED_TOKEN` | 토큰이 만료되었습니다 |
| 403 | `FORBIDDEN` | 접근 권한이 없습니다 |
| 404 | `NOT_FOUND` | 리소스를 찾을 수 없습니다 |
| 409 | `CONFLICT` | 리소스 충돌이 발생했습니다 |
| 500 | `INTERNAL_ERROR` | 서버 내부 오류가 발생했습니다 |

### 3.2 Content Service 에러 코드

| HTTP Status | Code | Message |
|-------------|------|---------|
| 404 | `POST_NOT_FOUND` | 게시글을 찾을 수 없습니다 |
| 400 | `INVALID_POST_STATUS` | 유효하지 않은 게시글 상태입니다 |
| 409 | `SLUG_ALREADY_EXISTS` | 이미 사용 중인 슬러그입니다 |
| 404 | `CATEGORY_NOT_FOUND` | 카테고리를 찾을 수 없습니다 |
| 404 | `TAG_NOT_FOUND` | 태그를 찾을 수 없습니다 |
| 404 | `COMMENT_NOT_FOUND` | 댓글을 찾을 수 없습니다 |

### 3.3 Auth Service 에러 코드

| HTTP Status | Code | Message |
|-------------|------|---------|
| 404 | `USER_NOT_FOUND` | 사용자를 찾을 수 없습니다 |
| 409 | `EMAIL_ALREADY_EXISTS` | 이미 사용 중인 이메일입니다 |
| 409 | `USERNAME_ALREADY_EXISTS` | 이미 사용 중인 사용자명입니다 |
| 401 | `INVALID_CREDENTIALS` | 이메일 또는 비밀번호가 올바르지 않습니다 |
| 403 | `USER_BANNED` | 정지된 계정입니다 |
| 403 | `EMAIL_NOT_VERIFIED` | 이메일 인증이 필요합니다 |

---

## 4. Content Service API

### 4.1 Posts (게시글)

#### 게시글 목록 조회

```http
GET /content/api/v1/posts
```

**Query Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| page | integer | No | 1 | 페이지 번호 |
| size | integer | No | 20 | 페이지 크기 (max: 100) |
| status | string | No | PUBLISHED | 게시글 상태 필터 |
| categoryId | long | No | - | 카테고리 필터 |
| tagId | long | No | - | 태그 필터 |
| sort | string | No | publishedAt,desc | 정렬 기준 |

**Response:**

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "title": "첫 번째 게시글",
      "slug": "first-post",
      "excerpt": "게시글 요약...",
      "status": "PUBLISHED",
      "author": {
        "id": 1,
        "name": "음하"
      },
      "statistics": {
        "viewCount": 100,
        "likeCount": 10,
        "commentCount": 5
      },
      "categories": [
        { "id": 1, "name": "개발", "slug": "dev" }
      ],
      "tags": [
        { "id": 1, "name": "Java", "slug": "java" }
      ],
      "publishedAt": "2025-01-18T12:00:00Z",
      "createdAt": "2025-01-17T10:00:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "size": 20,
    "totalElements": 50,
    "totalPages": 3
  }
}
```

#### 게시글 상세 조회

```http
GET /content/api/v1/posts/{id}
GET /content/api/v1/posts/slug/{slug}
```

#### 게시글 생성

```http
POST /content/api/v1/posts
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body:**

```json
{
  "title": "새 게시글",
  "content": "게시글 본문 내용...",
  "slug": "new-post",
  "status": "DRAFT",
  "categoryIds": [1, 2],
  "tagIds": [1, 3, 5]
}
```

#### 게시글 수정

```http
PUT /content/api/v1/posts/{id}
Authorization: Bearer {token}
```

#### 게시글 발행

```http
POST /content/api/v1/posts/{id}/publish
Authorization: Bearer {token}
```

#### 게시글 삭제

```http
DELETE /content/api/v1/posts/{id}
Authorization: Bearer {token}
```

### 4.2 Categories (카테고리)

```http
GET    /content/api/v1/categories           # 목록 조회
GET    /content/api/v1/categories/{id}      # 상세 조회
POST   /content/api/v1/categories           # 생성 (Admin)
PUT    /content/api/v1/categories/{id}      # 수정 (Admin)
DELETE /content/api/v1/categories/{id}      # 삭제 (Admin)
```

### 4.3 Tags (태그)

```http
GET    /content/api/v1/tags                 # 목록 조회
GET    /content/api/v1/tags/{id}            # 상세 조회
POST   /content/api/v1/tags                 # 생성 (Admin)
DELETE /content/api/v1/tags/{id}            # 삭제 (Admin)
```

### 4.4 Comments (댓글)

```http
GET    /content/api/v1/posts/{postId}/comments           # 댓글 목록
POST   /content/api/v1/posts/{postId}/comments           # 댓글 작성
PUT    /content/api/v1/posts/{postId}/comments/{id}      # 댓글 수정
DELETE /content/api/v1/posts/{postId}/comments/{id}      # 댓글 삭제
POST   /content/api/v1/posts/{postId}/comments/{id}/approve  # 댓글 승인 (Admin)
```

### 4.5 Search (검색)

```http
GET /content/api/v1/search?q={query}&page={page}&size={size}
```

---

## 5. Auth Service API

### 5.1 Authentication (인증)

#### 회원가입

```http
POST /auth/api/v1/auth/register
Content-Type: application/json
```

**Request Body:**

```json
{
  "email": "user@example.com",
  "username": "username",
  "password": "securePassword123!"
}
```

**Response:**

```json
{
  "success": true,
  "data": {
    "id": 1,
    "email": "user@example.com",
    "username": "username",
    "role": "SUBSCRIBER",
    "status": "INACTIVE",
    "emailVerified": false,
    "createdAt": "2025-01-18T12:00:00Z"
  },
  "message": "회원가입이 완료되었습니다. 이메일 인증을 진행해주세요."
}
```

#### 로그인

```http
POST /auth/api/v1/auth/login
Content-Type: application/json
```

**Request Body:**

```json
{
  "email": "user@example.com",
  "password": "securePassword123!"
}
```

**Response:**

```json
{
  "success": true,
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIs...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIs...",
    "tokenType": "Bearer",
    "expiresIn": 3600,
    "user": {
      "id": 1,
      "email": "user@example.com",
      "username": "username",
      "role": "SUBSCRIBER"
    }
  }
}
```

#### 토큰 갱신

```http
POST /auth/api/v1/auth/refresh
Content-Type: application/json
```

**Request Body:**

```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIs..."
}
```

#### 로그아웃

```http
POST /auth/api/v1/auth/logout
Authorization: Bearer {token}
```

#### 이메일 인증

```http
POST /auth/api/v1/auth/verify-email?token={verificationToken}
```

#### 비밀번호 재설정 요청

```http
POST /auth/api/v1/auth/forgot-password
Content-Type: application/json
```

**Request Body:**

```json
{
  "email": "user@example.com"
}
```

#### 비밀번호 재설정

```http
POST /auth/api/v1/auth/reset-password
Content-Type: application/json
```

**Request Body:**

```json
{
  "token": "reset-token-here",
  "newPassword": "newSecurePassword123!"
}
```

### 5.2 Users (사용자)

```http
GET    /auth/api/v1/users/me               # 내 정보 조회
PUT    /auth/api/v1/users/me               # 내 정보 수정
PUT    /auth/api/v1/users/me/password      # 비밀번호 변경

# Admin Only
GET    /auth/api/v1/users                  # 사용자 목록
GET    /auth/api/v1/users/{id}             # 사용자 상세
PUT    /auth/api/v1/users/{id}/role        # 역할 변경
PUT    /auth/api/v1/users/{id}/status      # 상태 변경 (정지/활성화)
```

---

## 6. API Gateway 라우팅

### 6.1 라우팅 규칙

| Path Pattern | Target Service | 인증 필요 |
|--------------|----------------|----------|
| `/content/**` | content-service:8081 | 부분적 |
| `/auth/**` | auth-service:8082 | 부분적 |
| `/notification/**` | notification-service:8083 | Yes |

### 6.2 인증 제외 경로

```yaml
# 인증 없이 접근 가능한 경로
- GET /content/api/v1/posts
- GET /content/api/v1/posts/{id}
- GET /content/api/v1/posts/slug/{slug}
- GET /content/api/v1/categories
- GET /content/api/v1/tags
- GET /content/api/v1/search
- POST /auth/api/v1/auth/register
- POST /auth/api/v1/auth/login
- POST /auth/api/v1/auth/refresh
- POST /auth/api/v1/auth/verify-email
- POST /auth/api/v1/auth/forgot-password
- POST /auth/api/v1/auth/reset-password
```

---

## 7. API 문서화 (예정)

### 7.1 OpenAPI (Swagger)

- **Swagger UI**: `http://localhost:8080/swagger-ui.html`
- **OpenAPI Spec**: `http://localhost:8080/v3/api-docs`

### 7.2 문서화 도구

| 도구 | 용도 |
|------|------|
| springdoc-openapi | OpenAPI 3.0 문서 자동 생성 |
| Swagger UI | 인터랙티브 API 문서 |
| ReDoc | 정적 API 문서 |

---

## 8. 변경 이력

| 버전 | 날짜 | 변경 내용 |
|------|------|----------|
| 1.0.0 | 2025-01-18 | 초기 API 설계 문서 작성 |

---

**Last Updated**: 2025-01-18
**Version**: 1.0.0
