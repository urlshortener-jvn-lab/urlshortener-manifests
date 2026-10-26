# Handoff & Context — Dự án học Infrastructure (`url-shortener-infra`)

> File này lưu lại toàn bộ ngữ cảnh, lộ trình, tiến độ và nguyên tắc giảng dạy để mọi cuộc hội thoại trong project `url-shortener-infra` (dù ở máy công ty hay máy ở nhà) luôn nhất quán 100%.
> Toàn bộ sổ tay tra cứu câu lệnh được lưu tại `deployments/README.md` và `deployments/K8S_HELM_CHEATSHEET.md`.

## 1. Mục tiêu & Nguyên tắc đồng hành (QUAN TRỌNG)
- **Mục tiêu**: Người dùng muốn tự học và thực hành **Infrastructure / DevOps / SRE** từ cơ bản đến nâng cao thông qua việc xây dựng và vận hành dự án **URL Shortener**.
- **Nguyên tắc giảng dạy bắt buộc**:
  - Đây là dự án học sâu về hạ tầng, **KHÔNG chỉ chạy lệnh cho xong**.
  - Ở mỗi bước, mỗi file cấu hình, mỗi câu lệnh hoặc tham số kỹ thuật (ví dụ: Multi-stage build, non-root user, Docker network DNS, healthcheck, reverse proxy headers, timeout, circuit breaker, load balancing, CI/CD runners, K8s pods, Deployment, Service, Ingress, ConfigMap, Secret, HPA, Helm, Prometheus, Grafana, Loki, k6, Terraform...), luôn phải **giải nghĩa "Nó là gì?", "Tại sao phải làm thế?", "Nếu không có nó thì chuyện gì xảy ra trên Production?"** bằng ngôn ngữ trực quan, dễ hiểu kèm ví dụ thực tế.
  - Hướng dẫn từng bước để người dùng tự chạy lệnh và hiểu bản chất, đồng thời luôn lưu chú thích/sổ tay lệnh vào `deployments/README.md` để người dùng dễ tra cứu lại khi quên.

## 2. Cấu trúc Polyrepo (3 Repositories trên GitHub Organization)
Thư mục gốc `url-shortener-infra/` chứa 3 Git repositories độc lập:
1. **`backend/`** (`https://github.com/urlshortener-jvn-lab/urlshortener-backend`):
   - `.NET 10`, Central Package Management (`Directory.Build.props`, `Directory.Packages.props`), Solution `UrlShortener.slnx`.
   - 6 projects: `UrlShortener.Domain`, `UrlShortener.Application`, `UrlShortener.Infrastructure`, `UrlShortener.ServiceDefaults` (OpenTelemetry + HealthChecks), `UrlShortener.API` (Minimal API + Scalar UI `/scalar/v1`), `UrlShortener.AppHost` (.NET Aspire 13.1 + `Scalar.Aspire`).
   - EF Core + PostgreSQL (`short_urls` table, snake_case naming) + `StackExchange.Redis` (Cache-Aside pattern với fail-fast timeout `300ms` và graceful fallback khi mất kết nối Redis).
   - Có sẵn `/health` (JSON chi tiết từng dependency), `/alive` (liveness probe), Fixed Window Rate Limiter (`30 req/phút/IP`), `ForwardedHeaders` (cho Reverse Proxy), và trả về `ServedByInstance` (`Environment.MachineName` = Container ID / Pod Name khi chạy trên Docker/K8s).
2. **`frontend/`** (`https://github.com/urlshortener-jvn-lab/urlshortener-frontend-`):
   - `React 19` + `TypeScript` + `Vite 7` + `Ant Design 5` + `Tailwind CSS v4` + `TanStack Query` + `Axios`.
   - Dashboard hiển thị trực tiếp trạng thái kết nối PostgreSQL, Redis, Instance Name xử lý, thống kê click, form tạo link rút gọn và test redirect `/r/{code}`.
   - Kèm `nginx.conf` đóng vai trò Reverse Proxy + Load Balancer + Gateway Rate Limiter.
3. **`deployments/`** (`https://github.com/urlshortener-jvn-lab/urlshortener-manifests`):
   - `docker-compose/docker-compose.yml`: Stack Docker Compose.
   - `k8s/01..08-*.yaml`: Bộ 8 file Kubernetes Manifests thuần (có giải thích chi tiết từng tham số).
   - `helm/urlshortener/`: Gói Helm Chart chuẩn hóa toàn bộ hệ thống (`Chart.yaml`, `values.yaml`, `templates/`).
   - `README.md` & `K8S_HELM_CHEATSHEET.md`: Sổ tay tra cứu toàn bộ câu lệnh Docker, Git, `kubectl`, `k9s`, `helm`.

## 3. Lộ trình thực hành 7 bước & Tiến độ chi tiết

- [x] **Bước 1: Chạy Local** *(Đã hoàn thành)*
  - Dựng `.NET 10 API` + `React (Vite)` + `PostgreSQL` + `Redis` (+ `.NET Aspire 13.1` & `Scalar API UI`).
  - Thực hành test tắt Redis (`docker stop`) để quan sát cơ chế **Graceful Degradation** (Fallback xuống Postgres) và tối ưu `connectTimeout=300,syncTimeout=300` để tránh treo request 5 giây.
- [x] **Bước 2: Containerization (Docker)** *(Đã hoàn thành)*
  - Viết Multi-stage `Dockerfile` tối ưu layer caching cho BE (`aspnet:10.0` non-root `$APP_UID`, 364MB) & FE (`nginx:1.27.4-alpine`, 74.6MB), `.dockerignore`, và ghép toàn bộ stack vào `deployments/docker-compose/docker-compose.yml` kèm `aspire-dashboard`.
- [x] **Bước 3: Reverse Proxy & Load Balancing (Nginx)** *(Đã hoàn thành)*
  - Scale `backend` lên `replicas: 3` (ẩn port `8080` khỏi máy host, chỉ mở nội bộ trong mạng `urlshortener-net`).
  - Cấu hình `frontend/nginx.conf` dùng Docker DNS (`resolver 127.0.0.11 valid=5s`), biến động `$backend_upstream`, tự động Failover (`proxy_next_upstream error timeout http_502 http_503 http_504`) và chặn Rate Limit (`limit_req_zone` 30r/m + `burst=29 nodelay`) ngay tại cửa ngõ Nginx.
- [x] **Bước 4: CI/CD Pipeline (GitHub Actions & Container Registry)** *(Đã hoàn thành)*
  - Tách cấu trúc Polyrepo gồm 3 repo trên GitHub Organization `urlshortener-jvn-lab`, làm sạch credentials khỏi git history.
  - Viết `.github/workflows/ci-cd.yml` cho cả Backend và Frontend gồm 2 jobs (`CI - Build & Validate` và `CD - Build & Push Container Image` với BuildKit GHA cache), tự động build và đẩy image lên `ghcr.io/urlshortener-jvn-lab/urlshortener-api` và `ghcr.io/urlshortener-jvn-lab/urlshortener-fe`.
- [x] **Bước 5: Kubernetes & Helm (Docker Desktop K8s + `k9s` + Helm)** *(Đã hoàn thành)*
  - Bật cụm Kubernetes local (`docker-desktop` v1.34.1).
  - Viết và thực hành 8 file K8s Manifests thuần trong `deployments/k8s/`: `Namespace`, `ConfigMap` (override `nginx.conf` sang CoreDNS `kube-dns.kube-system.svc.cluster.local` và FQDN `backend-service.urlshortener.svc.cluster.local`), `Secret`, `PVC` (`256Mi`), `Deployment` + `initContainers` (`wait-for-postgres` thay thế `depends_on`), `Service` (`ClusterIP`, `LoadBalancer` port `3000:30300`), `HPA` (`3 -> 6` pods), `aspire-dashboard` (`18888:31888`).
  - Sử dụng `k9s -n urlshortener` để quan sát trực quan và đóng gói toàn bộ thành **Helm Chart** (`deployments/helm/urlshortener`), thực hành `helm upgrade --install`, `--set`, `helm history` và `helm rollback` (đang chạy ở `Revision 3`).
- [ ] **Bước 6: Observability & Load Testing (`Prometheus` + `Grafana` + `Loki` + `k6`)** *(TIẾP THEO - Bắt đầu tại đây)*
  - Cấu hình xuất Prometheus Metrics từ `.NET 10 API` (`/metrics` với OpenTelemetry Prometheus Exporter) và thu thập Logs tập trung.
  - Triển khai `Prometheus` + `Grafana` lên Kubernetes (hoặc Docker) và dựng **Grafana Dashboard** tổng hợp (Request Rate RPS, Error Rate, P95/P99 Latency, CPU/RAM từng Pod, Active Replicas).
  - Viết kịch bản **Load Testing với `k6`** bắn tải cao vào hệ thống để quan sát trực tiếp biểu đồ nhảy múa trên Grafana và xem Kubernetes `HPA` tự động scale Pod!
- [ ] **Bước 7: Infrastructure as Code (`Terraform`)**: Viết Terraform để dựng hạ tầng tự động bằng code.
