# 🧭 Sổ tay Tra cứu Nhanh: Kubernetes, `k9s` & Helm (`url-shortener-infra`)

> File này lưu lại toàn bộ các câu lệnh và phím tắt quan trọng nhất của **Bước 5 (Kubernetes & Helm)** để bạn tra cứu bất cứ lúc nào khi quên.

---

## 1. Bảng điều khiển trực quan `k9s` (Công cụ quản lý K8s trên Terminal)

### Cách cài đặt (nếu máy ở nhà chưa có):
```powershell
winget install Derailed.k9s
```

### Cách mở bảng điều khiển vào thẳng dự án `urlshortener`:
```powershell
k9s -n urlshortener
```
*(Lưu ý: Khi làm dự án cá nhân trên Docker Desktop K8s thì **không** truyền `--kubeconfig`. Chỉ khi làm dự án công ty cần nối vào server từ xa mới dùng `k9s --kubeconfig <đường-dẫn-file-config>`).*

### Các lệnh chuyển màn hình trong `k9s` (Bấm phím `:` rồi gõ lệnh + `Enter`):
| Lệnh gõ | Màn hình hiển thị | Giải thích |
| :--- | :--- | :--- |
| **`:pod`** *(hoặc `:po`)* | Danh sách **Pods** | Xem các container đang chạy, số lần restart, IP, trạng thái Ready (`1/1`) |
| **`:deploy`** *(hoặc `:dp`)* | Danh sách **Deployments** | Xem các bộ quản lý bản sao (`3/3` backend, `2/2` frontend) |
| **`:svc`** | Danh sách **Services** | Xem các địa chỉ mạng nội bộ (`ClusterIP`) và cổng mở ra ngoài (`LoadBalancer` / `NodePort`) |
| **`:cm`** | Danh sách **ConfigMaps** | Xem cấu hình biến môi trường và file `nginx.conf` |
| **`:sec`** | Danh sách **Secrets** | Xem các mật khẩu được mã hóa Base64 |
| **`:pvc`** | Danh sách **PersistentVolumeClaims** | Xem ổ cứng bền vững (`postgres-pvc` 256Mi) |
| **`:hpa`** | Danh sách **HorizontalPodAutoscalers** | Xem bộ tự động co giãn số lượng Pod theo % CPU |
| **`:node`** | Danh sách **Nodes** | Xem máy chủ K8s (`docker-desktop`) và % CPU/RAM toàn máy |
| **`:ns`** | Danh sách **Namespaces** | Xem các phòng ban trên cụm K8s (Bấm `Enter` vào 1 dòng để chuyển phòng) |
| **`:q`** | **Thoát `k9s`** | Đóng bảng điều khiển quay về PowerShell |

### Phím tắt thao tác khi đang chọn 1 dòng trong `k9s`:
| Phím | Chức năng |
| :--- | :--- |
| **`l`** *(Logs)* | Xem trực tiếp dòng chảy Log của Pod đang chọn (`Esc` để quay ra) |
| **`d`** *(Describe)* | Xem chi tiết thông số, lịch sử sự kiện (`Events`), lỗi khởi động của Pod/Service |
| **`s`** *(Shell)* | Mở cửa sổ dòng lệnh Linux chui thẳng vào bên trong Container đang chọn |
| **`y`** *(YAML)* | Xem cấu hình YAML đầy đủ của đối tượng đang chọn |
| **`e`** *(Edit)* | Sửa trực tiếp cấu hình YAML đang chạy trên K8s |
| **`Ctrl + D`** | **Xóa (Giết) đối tượng đang chọn** (Dùng để test K8s tự hồi sinh Pod mới) |
| **`/`** | Tìm kiếm / Lọc danh sách theo từ khóa (gõ từ khóa rồi `Enter`, bấm `Esc` để xóa bộ lọc) |
| **`Esc`** | Quay lại màn hình trước đó |

---

## 2. Các câu lệnh `kubectl` thông dụng nhất

```powershell
# 1. Xem toàn bộ tài nguyên (Pods, Services, Deployments, HPA) trong namespace urlshortener
kubectl get all -n urlshortener

# 2. Xem chi tiết IP của từng Pod
kubectl get pods -n urlshortener -o wide

# 3. Xem log của toàn bộ các Pod thuộc tầng Backend
kubectl logs -n urlshortener -l app=backend --tail=50 -f

# 4. Xem chi tiết sự kiện của 1 Pod (dùng khi Pod bị treo ở Pending / CrashLoopBackOff / Init)
kubectl describe pod <tên-pod> -n urlshortener

# 5. Khởi động lại (Rolling Restart) toàn bộ các Pod Backend mà không gây gián đoạn (Zero-Downtime)
kubectl rollout restart deployment/backend -n urlshortener

# 6. Tăng/giảm số lượng Pod thủ công (ví dụ tăng Backend lên 5 Pods)
kubectl scale deployment/backend --replicas=5 -n urlshortener

# 7. Triển khai bằng bộ file K8s Manifests thuần
kubectl apply -f deployments/k8s/01-namespace.yaml
kubectl apply -f deployments/k8s/

# 8. Xóa toàn bộ các đối tượng tạo từ thư mục k8s/
kubectl delete -f deployments/k8s/
```

---

## 3. Các câu lệnh `helm` (Quản lý gói Kubernetes chuyên nghiệp)

```powershell
# 1. Kiểm tra cú pháp Helm Chart có hợp lệ không (Lint)
helm lint ./deployments/helm/urlshortener

# 2. Xem trước (Dry-run) các file YAML mà Helm sẽ sinh ra từ values.yaml (chưa cài thật)
helm template urlshortener ./deployments/helm/urlshortener -n urlshortener

# 3. Cài đặt (hoặc nâng cấp nếu đã có) toàn bộ hệ thống bằng 1 lệnh duy nhất!
helm upgrade --install urlshortener ./deployments/helm/urlshortener -n urlshortener --create-namespace

# 4. Ghi đè nhanh 1 thông số lúc chạy (ví dụ tăng Backend lên 4 replicas ngay trên dòng lệnh)
helm upgrade urlshortener ./deployments/helm/urlshortener -n urlshortener --set backend.replicaCount=4

# 5. Xem danh sách các bản phát hành (Releases) đã cài bằng Helm
helm list -n urlshortener

# 6. Xem lịch sử các lần nâng cấp và Quay lui (Rollback) về phiên bản trước đó trong 1 giây!
helm history urlshortener -n urlshortener
helm rollback urlshortener 1 -n urlshortener

# 7. Gỡ cài đặt toàn bộ hệ thống khỏi Kubernetes
helm uninstall urlshortener -n urlshortener
```

---

## 4. Bước 6.2 — `metrics-server` (Đo CPU/RAM cho HPA, `kubectl top`, cột CPU/MEM trong `k9s`)

```powershell
# Thêm kho chart cộng đồng + cài vào kube-system
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm repo update
helm upgrade --install metrics-server metrics-server/metrics-server -n kube-system --set "args={--kubelet-insecure-tls}"
#   --kubelet-insecure-tls: CHỈ dùng cho lab (Docker Desktop dùng cert tự ký). KHÔNG dùng trên Production!

# Kiểm tra (đợi ~60s sau khi cài)
kubectl top nodes
kubectl top pods -n urlshortener
kubectl get hpa -n urlshortener          # TARGETS phải là số (vd cpu: 19%/70%), không phải <unknown>

# Xem QoS Class của từng Pod (BestEffort / Burstable / Guaranteed)
kubectl get pods -n urlshortener -o custom-columns="NAME:.metadata.name,QOS:.status.qosClass"
```

### Đọc các cột trong `k9s` (`:pod`)
| Cột | Ý nghĩa |
| :--- | :--- |
| `CPU` | CPU thực dùng, đơn vị millicore (`8` = 8m = 0.008 core) |
| `%CPU/R` | % so với `requests.cpu` → **HPA dùng con số này** để so với ngưỡng |
| `%CPU/L` | % so với `limits.cpu` → chạm 100% sẽ bị **throttle** (bóp CPU, chậm lại) |
| `MEM`, `%MEM/R`, `%MEM/L` | Tương tự cho RAM. Chạm 100% `limits.memory` → Pod bị **OOMKilled** |
| `n/a` | Pod chưa khai báo `resources` → không tính được % (QoS = `BestEffort`) |

### Công thức HPA
```
desiredReplicas = ceil( currentReplicas × currentUtilization / targetUtilization )
Ví dụ: ceil(3 × 140% / 70%) = 6 Pods
```
