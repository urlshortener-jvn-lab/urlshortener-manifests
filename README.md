# 📘 Sổ tay Toàn tập: Dự án Học Infrastructure / DevOps / SRE (`url-shortener-infra`)

> File này là **Sổ tay Tra cứu Nhanh (Master Cheat Sheet)** lưu lại toàn bộ câu lệnh, phím tắt, kiến thức cốt lõi từ **Bước 1 -> Bước 7** và hướng dẫn đồng bộ giữa máy công ty & máy ở nhà. Bạn không cần phải học thuộc lòng câu lệnh — khi quên chỉ cần mở file này (hoặc xem file chi tiết [K8S_HELM_CHEATSHEET.md](./K8S_HELM_CHEATSHEET.md))!

---

## 🖥️ 1. Cách kéo toàn bộ dự án về Máy ở nhà (Home PC)

Khi ngồi ở máy nhà, mở **PowerShell** và chạy đúng cụm lệnh dưới đây:

```powershell
# 1. Tạo thư mục gốc của dự án
mkdir url-shortener-infra
cd url-shortener-infra

# 2. Clone 3 repositories vào đúng tên thư mục chuẩn (backend, frontend, deployments)
git clone https://github.com/urlshortener-jvn-lab/urlshortener-backend.git backend
git clone https://github.com/urlshortener-jvn-lab/urlshortener-frontend-.git frontend
git clone https://github.com/urlshortener-jvn-lab/urlshortener-manifests.git deployments

# 3. Copy file ngữ cảnh AGENTS.md ra thư mục gốc để AI tự động nhận diện toàn bộ lộ trình
Copy-Item .\deployments\AGENTS.md .\AGENTS.md -Force
```

Khi mở **Antigravity IDE** ở máy nhà -> **Open Folder** `url-shortener-infra` -> Tạo Chat mới và nhắn:
> **"Đọc file AGENTS.md để nắm tiến độ hiện tại và tiếp tục hướng dẫn tôi bước tiếp theo nhé!"**

---

## 🐳 2. Tổng hợp Lệnh Bước 1, 2, 3 (Local, Docker Compose & Nginx Load Balancing)

```powershell
# --- BƯỚC 1: Chạy bằng .NET Aspire Local (Dành cho lúc lập trình code C#) ---
cd backend
dotnet run --project src/UrlShortener.AppHost

# --- BƯỚC 2 & 3: Chạy toàn bộ Stack bằng Docker Compose (3 Backend Replicas + Nginx) ---
cd deployments/docker-compose
docker compose up -d --build

# Xem danh sách các container đang chạy
docker compose ps

# Xem log của Nginx hoặc Backend trong Docker Compose
docker compose logs -f frontend
docker compose logs -f backend

# Tắt toàn bộ bộ Docker Compose (để giải phóng RAM / nhường cổng 3000 cho Kubernetes)
docker compose down
```

---

## 🔄 3. Tổng hợp Lệnh Bước 4 (Git & CI/CD GitHub Actions)

Mỗi khi sửa file ở repo nào (`backend`, `frontend`, hoặc `deployments`), đứng tại thư mục đó và chạy 3 lệnh:

```powershell
git add .
git commit -m "mô tả ngắn gọn thay đổi"
git push
```
- Khi `git push` ở `backend` hoặc `frontend`, GitHub Actions (`.github/workflows/ci-cd.yml`) sẽ tự động chạy 2 Job:
  1. **CI**: Kiểm tra code (`dotnet build` / `npm run build`).
  2. **CD**: Đóng gói Docker Image và đẩy lên kho `ghcr.io/urlshortener-jvn-lab/...`.

---

## ☸️ 4. Tổng hợp Lệnh Bước 5 (Kubernetes, `k9s` & Helm Chart)

### A. Bảng điều khiển trực quan `k9s` (Khuyên dùng nhất!)
```powershell
# Cài đặt k9s (nếu máy mới chưa có)
winget install Derailed.k9s

# Mở bảng điều khiển vào thẳng phòng urlshortener
k9s -n urlshortener
```
- **Chuyển màn hình trong `k9s`** (Bấm dấu `:` rồi gõ lệnh + `Enter`):
  - `:pod` (Xem Pods) | `:deploy` (Xem Deployments) | `:svc` (Xem Services & Cổng) | `:cm` (ConfigMap) | `:sec` (Secret) | `:pvc` (Ổ đĩa) | `:hpa` (Auto-scaler) | `:node` (Xem Server) | `:ns` (Đổi Namespace) | `:q` (Thoát `k9s`).
- **Phím tắt khi chọn 1 Pod**:
  - `l` (Xem Logs) | `d` (Describe chi tiết) | `s` (Chui vào Shell Linux của container) | `y` (Xem YAML) | `Ctrl + D` (Xóa/Giết Pod để test K8s tự hồi sinh) | `Esc` (Quay lại).

### B. Các câu lệnh `helm` (Đóng gói & Triển khai chuẩn Doanh nghiệp)
Thư mục Helm Chart nằm tại: `deployments/helm/urlshortener/` (chỉnh sửa cấu hình tại file trung tâm `values.yaml`).

```powershell
cd C:\Users\anh.nguyen95\url-shortener-infra\deployments

# 1. Kiểm tra cú pháp gói Helm Chart
helm lint ./helm/urlshortener

# 2. Cài đặt (hoặc nâng cấp) toàn bộ hệ thống lên Kubernetes chỉ bằng 1 lệnh!
helm upgrade --install urlshortener ./helm/urlshortener -n urlshortener --create-namespace

# 3. Thay đổi nhanh số lượng Pod Backend ngay trên dòng lệnh (tạo Revision mới)
helm upgrade urlshortener ./helm/urlshortener -n urlshortener --set backend.replicaCount=4

# 4. Xem lịch sử các phiên bản (Revisions) đã triển khai
helm history urlshortener -n urlshortener

# 5. Quay ngược thời gian (Rollback) về phiên bản số 1 trong 1 giây!
helm rollback urlshortener 1 -n urlshortener

# 6. Gỡ toàn bộ hệ thống khỏi Kubernetes khi không dùng nữa
helm uninstall urlshortener -n urlshortener
```

### C. Các câu lệnh `kubectl` cơ bản
```powershell
# Xem toàn bộ Pods, Services, Deployments, HPA trong phòng urlshortener
kubectl get all -n urlshortener

# Xem chi tiết IP của từng Pod
kubectl get pods -n urlshortener -o wide

# Xem log của các Pod Backend
kubectl logs -n urlshortener -l app=backend --tail=50 -f

# Khởi động lại (Rolling Restart) toàn bộ Pod Backend không gây gián đoạn
kubectl rollout restart deployment/backend -n urlshortener

# Nếu muốn chạy bằng 8 file YAML thuần (trong deployments/k8s/) thay vì Helm:
kubectl apply -f ./k8s/01-namespace.yaml
kubectl apply -f ./k8s/
```

### D. Các đường link truy cập khi chạy Kubernetes / Helm:
- 🌐 **Web UI (React + Nginx)**: [http://localhost:3000](http://localhost:3000) *(hoặc `http://localhost:30300`)*
- 📘 **Scalar API Docs**: [http://localhost:3000/scalar/v1](http://localhost:3000/scalar/v1)
- 💓 **Health Check JSON**: [http://localhost:3000/health](http://localhost:3000/health)
- 📊 **Aspire OpenTelemetry (Logs/Traces/Metrics)**: [http://localhost:18888](http://localhost:18888) *(hoặc `http://localhost:31888`)*
