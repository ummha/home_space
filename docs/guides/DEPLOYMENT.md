# Ummha Studio - Deployment Guide

> **Version**: 1.0.0
> **Last Updated**: 2025-01-18
> **Related**: [PRD.md](../../PRD.md) | [ARCHITECTURE.md](../architecture/ARCHITECTURE.md)

---

## 1. 개발 환경 요구사항

### 1.1 Prerequisites

| 도구 | 버전 | 용도 |
|------|------|------|
| Java | 25 (Eclipse Temurin) | 런타임 |
| Gradle | 9.2.1+ | 빌드 도구 |
| Docker | Latest | 컨테이너 |
| Docker Compose | Latest | 로컬 개발 환경 |
| PostgreSQL | 16 | 데이터베이스 |
| Git | Latest | 버전 관리 |

### 1.2 권장 개발 도구

| 도구 | 용도 |
|------|------|
| IntelliJ IDEA | IDE |
| DBeaver | 데이터베이스 클라이언트 |
| Postman / Insomnia | API 테스트 |

---

## 2. 프로젝트 구조

```
ummha_space/
├── gradle/
│   └── jooq.gradle              # jOOQ 공유 설정
├── services/
│   ├── content-service/
│   │   ├── build.gradle
│   │   ├── gradle.properties
│   │   └── src/
│   │       ├── main/
│   │       │   ├── java/
│   │       │   ├── generated/   # jOOQ 생성 코드
│   │       │   └── resources/
│   │       └── test/
│   ├── auth-service/
│   └── notification-service/
├── infrastructure/
│   ├── docker-compose.yml
│   └── k8s/
├── docs/
│   ├── architecture/
│   ├── api/
│   └── guides/
├── PRD.md
└── settings.gradle
```

---

## 3. 로컬 개발 환경 설정

### 3.1 Docker Compose로 인프라 실행

```bash
# 프로젝트 루트에서 실행
cd infrastructure

# PostgreSQL 실행
docker-compose up -d postgres

# 전체 인프라 실행 (Kafka, Redis 포함)
docker-compose up -d
```

**docker-compose.yml 예시:**

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:16
    container_name: ummha-postgres
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    ports:
      - "5433:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init-db:/docker-entrypoint-initdb.d
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: ummha-redis
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

  kafka:
    image: confluentinc/cp-kafka:7.5.0
    container_name: ummha-kafka
    ports:
      - "9092:9092"
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://localhost:9092
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
    depends_on:
      - zookeeper

  zookeeper:
    image: confluentinc/cp-zookeeper:7.5.0
    container_name: ummha-zookeeper
    ports:
      - "2181:2181"
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181

volumes:
  postgres_data:
  redis_data:
```

### 3.2 데이터베이스 초기화

```bash
# 각 서비스별 데이터베이스 생성
psql -h localhost -p 5433 -U postgres << EOF
CREATE DATABASE content_db;
CREATE DATABASE auth_db;
CREATE DATABASE notification_db;
EOF

# 스키마 적용 (예: Content Service)
psql -h localhost -p 5433 -U postgres -d content_db \
  -f docs/schema/content-service.sql
```

---

## 4. jOOQ 코드 생성

### 4.1 기본 사용법

```bash
# 서비스 디렉토리로 이동
cd services/content-service

# jOOQ 코드 생성
./gradlew generateJooq

# 정리 후 재생성
./gradlew cleanJooq generateJooq
```

### 4.2 환경별 실행

```bash
# 환경 변수로 지정
export JOOQ_DB_URL=jdbc:postgresql://localhost:5433/content_db
export JOOQ_DB_USER=postgres
export JOOQ_DB_PASSWORD=postgres
./gradlew generateJooq

# 또는 Gradle 프로퍼티로 지정
./gradlew generateJooq \
  -Pjooq.db.url=jdbc:postgresql://localhost:5433/content_db \
  -Pjooq.db.user=postgres \
  -Pjooq.db.password=postgres

# 환경 프로파일 사용
./gradlew generateJooq -Penv=dev
./gradlew generateJooq -Penv=prod
```

### 4.3 Gradle 설정

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

### 4.4 build.gradle 설정 예시

```groovy
plugins {
    id 'java'
    id 'org.springframework.boot' version '4.0.1'
    id 'nu.studer.jooq' version '9.0'
}

dependencies {
    implementation 'org.jooq:jooq:3.19.6'
    jooqGenerator 'org.postgresql:postgresql:42.7.1'
}

jooq {
    version = '3.19.6'
    configurations {
        main {
            generationTool {
                jdbc {
                    driver = 'org.postgresql.Driver'
                    url = project.findProperty('jooq.db.url') ?:
                          System.getenv('JOOQ_DB_URL') ?:
                          'jdbc:postgresql://localhost:5433/content_db'
                    user = project.findProperty('jooq.db.user') ?:
                           System.getenv('JOOQ_DB_USER') ?:
                           'postgres'
                    password = project.findProperty('jooq.db.password') ?:
                               System.getenv('JOOQ_DB_PASSWORD') ?:
                               'postgres'
                }
                generator {
                    name = 'org.jooq.codegen.DefaultGenerator'
                    database {
                        name = 'org.jooq.meta.postgres.PostgresDatabase'
                        inputSchema = 'public'
                    }
                    generate {
                        records = true
                        immutablePojos = true
                        fluentSetters = true
                    }
                    target {
                        packageName = project.findProperty('jooq.package') ?:
                                      'com.ummha.content.adapter.out.persistence.jooq'
                        directory = 'src/main/generated'
                    }
                }
            }
        }
    }
}
```

---

## 5. 빌드 및 실행

### 5.1 빌드

```bash
# 전체 빌드
./gradlew build

# 특정 서비스 빌드
./gradlew :services:content-service:build

# 테스트 제외 빌드
./gradlew build -x test

# Clean 빌드
./gradlew clean build
```

### 5.2 실행

```bash
# 개발 모드 실행
cd services/content-service
./gradlew bootRun

# 프로파일 지정 실행
./gradlew bootRun --args='--spring.profiles.active=dev'

# JAR 직접 실행
java -jar build/libs/content-service-0.0.1-SNAPSHOT.jar \
  --spring.profiles.active=dev
```

### 5.3 테스트

```bash
# 전체 테스트
./gradlew test

# 특정 서비스 테스트
./gradlew :services:content-service:test

# 통합 테스트
./gradlew integrationTest

# 테스트 리포트 확인
open build/reports/tests/test/index.html
```

---

## 6. Docker 배포

### 6.1 Docker 이미지 빌드

**Dockerfile 예시:**

```dockerfile
# Build stage
FROM eclipse-temurin:25-jdk-alpine AS builder
WORKDIR /app
COPY gradle gradle
COPY gradlew build.gradle settings.gradle ./
COPY services/content-service services/content-service
RUN ./gradlew :services:content-service:build -x test

# Runtime stage
FROM eclipse-temurin:25-jre-alpine
WORKDIR /app
COPY --from=builder /app/services/content-service/build/libs/*.jar app.jar

ENV JAVA_OPTS="-Xms256m -Xmx512m"
EXPOSE 8081

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
```

**빌드 및 실행:**

```bash
# 이미지 빌드
docker build -t ummha/content-service:latest \
  -f services/content-service/Dockerfile .

# 컨테이너 실행
docker run -d \
  --name content-service \
  -p 8081:8081 \
  -e SPRING_PROFILES_ACTIVE=prod \
  -e SPRING_DATASOURCE_URL=jdbc:postgresql://postgres:5432/content_db \
  --network ummha-network \
  ummha/content-service:latest
```

### 6.2 Docker Compose로 전체 서비스 실행

```yaml
# docker-compose.services.yml
version: '3.8'

services:
  content-service:
    build:
      context: .
      dockerfile: services/content-service/Dockerfile
    container_name: ummha-content-service
    ports:
      - "8081:8081"
    environment:
      SPRING_PROFILES_ACTIVE: docker
      SPRING_DATASOURCE_URL: jdbc:postgresql://postgres:5432/content_db
      SPRING_DATASOURCE_USERNAME: postgres
      SPRING_DATASOURCE_PASSWORD: postgres
    depends_on:
      postgres:
        condition: service_healthy
    networks:
      - ummha-network

  auth-service:
    build:
      context: .
      dockerfile: services/auth-service/Dockerfile
    container_name: ummha-auth-service
    ports:
      - "8082:8082"
    environment:
      SPRING_PROFILES_ACTIVE: docker
      SPRING_DATASOURCE_URL: jdbc:postgresql://postgres:5432/auth_db
    depends_on:
      postgres:
        condition: service_healthy
    networks:
      - ummha-network

networks:
  ummha-network:
    driver: bridge
```

---

## 7. Kubernetes 배포 (K3s)

### 7.1 Namespace 생성

```yaml
# k8s/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: ummha
```

### 7.2 ConfigMap / Secret

```yaml
# k8s/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: ummha-config
  namespace: ummha
data:
  SPRING_PROFILES_ACTIVE: "prod"

---
# k8s/secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: ummha-secrets
  namespace: ummha
type: Opaque
stringData:
  DB_PASSWORD: "your-secure-password"
  JWT_SECRET: "your-jwt-secret"
```

### 7.3 Deployment

```yaml
# k8s/content-service-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: content-service
  namespace: ummha
spec:
  replicas: 2
  selector:
    matchLabels:
      app: content-service
  template:
    metadata:
      labels:
        app: content-service
    spec:
      containers:
        - name: content-service
          image: ummha/content-service:latest
          ports:
            - containerPort: 8081
          env:
            - name: SPRING_PROFILES_ACTIVE
              valueFrom:
                configMapKeyRef:
                  name: ummha-config
                  key: SPRING_PROFILES_ACTIVE
            - name: SPRING_DATASOURCE_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: ummha-secrets
                  key: DB_PASSWORD
          resources:
            requests:
              memory: "256Mi"
              cpu: "250m"
            limits:
              memory: "512Mi"
              cpu: "500m"
          livenessProbe:
            httpGet:
              path: /actuator/health/liveness
              port: 8081
            initialDelaySeconds: 30
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /actuator/health/readiness
              port: 8081
            initialDelaySeconds: 10
            periodSeconds: 5
```

### 7.4 Service

```yaml
# k8s/content-service-svc.yaml
apiVersion: v1
kind: Service
metadata:
  name: content-service
  namespace: ummha
spec:
  selector:
    app: content-service
  ports:
    - port: 8081
      targetPort: 8081
  type: ClusterIP
```

### 7.5 배포 명령어

```bash
# 전체 배포
kubectl apply -f k8s/

# 개별 배포
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secret.yaml
kubectl apply -f k8s/content-service-deployment.yaml
kubectl apply -f k8s/content-service-svc.yaml

# 상태 확인
kubectl get pods -n ummha
kubectl get svc -n ummha
kubectl logs -f deployment/content-service -n ummha
```

---

## 8. CI/CD 파이프라인 (예정)

### 8.1 GitHub Actions 워크플로우 예시

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Set up JDK 25
        uses: actions/setup-java@v4
        with:
          java-version: '25'
          distribution: 'temurin'

      - name: Cache Gradle packages
        uses: actions/cache@v4
        with:
          path: ~/.gradle/caches
          key: ${{ runner.os }}-gradle-${{ hashFiles('**/*.gradle*') }}

      - name: Build with Gradle
        run: ./gradlew build

      - name: Run tests
        run: ./gradlew test

      - name: Upload test results
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: test-results
          path: '**/build/reports/tests/'
```

---

## 9. 트러블슈팅

### 9.1 일반적인 문제

| 문제 | 원인 | 해결 방법 |
|------|------|----------|
| PostgreSQL 연결 실패 | Docker 미실행 | `docker-compose up -d postgres` |
| jOOQ 코드 생성 실패 | DB 스키마 없음 | 스키마 먼저 적용 |
| 빌드 실패 | Java 버전 불일치 | Java 25 설치 확인 |
| 포트 충돌 | 포트 사용 중 | `lsof -i :8081` 로 확인 후 종료 |

### 9.2 로그 확인

```bash
# 애플리케이션 로그
./gradlew bootRun 2>&1 | tee app.log

# Docker 로그
docker logs -f ummha-content-service

# Kubernetes 로그
kubectl logs -f deployment/content-service -n ummha
```

---

## 10. 참고 링크

- [Spring Boot Documentation](https://docs.spring.io/spring-boot/index.html)
- [jOOQ Documentation](https://www.jooq.org/doc/latest/)
- [Docker Documentation](https://docs.docker.com/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [K3s Documentation](https://docs.k3s.io/)

---

**Last Updated**: 2025-01-18
**Version**: 1.0.0
