# URL Shortener — Infrastructure & Deployment Manifests (`urlshortener-manifests`)

Repository này chứa cấu hình hạ tầng (`docker-compose`, `Kubernetes`, `Helm Chart`) và file ngữ cảnh đồng hành **`AGENTS.md`** cho dự án học **Infrastructure / DevOps / SRE**.

---

## 🖥️ Hướng dẫn Setup nhanh khi chuyển sang máy ở nhà (Home PC)

Khi về máy ở nhà, bạn chỉ cần mở **PowerShell** tại ổ đĩa muốn lưu project (ví dụ `C:\` hoặc `D:\`) và copy-paste đúng cụm lệnh dưới đây để tái tạo lại toàn bộ cấu trúc thư mục `url-shortener-infra` giống hệt máy công ty:

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

---

## 💬 Cách bắt đầu cuộc trò chuyện mới trên Antigravity ở máy nhà

1. Mở **Antigravity IDE** -> Chọn **File > Open Folder** -> Mở thư mục `url-shortener-infra` vừa tạo.
2. Tạo một khung Chat mới (**New Conversation**).
3. Vì đã có sẵn file `AGENTS.md` ở gốc thư mục, AI sẽ **tự động nạp toàn bộ lịch sử Bước 1 -> Bước 4 và nguyên tắc giảng dạy** vào bộ nhớ ngay từ giây đầu tiên.
4. Bạn chỉ cần nhắn câu đầu tiên:
   > **"Đọc file AGENTS.md để nắm tiến độ hiện tại và bắt đầu hướng dẫn tôi Bước 5: Kubernetes & Helm nhé!"**
