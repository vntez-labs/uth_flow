# UTH Flow 🎓⚡

**UTH Flow** là ứng dụng trợ lý học tập và thông tin sinh viên hiện đại, tiện lợi được thiết kế riêng cho sinh viên **Trường Đại học Giao thông Vận tải TP.HCM (UTH)**.

Ứng dụng giúp sinh viên đồng bộ nhanh lịch học, thời khóa biểu, điểm số, học phí và truy cập một chạm trực tiếp vào hệ thống LMS Courses với Single Sign-On (SSO).

---

## 🚀 Các Tính Năng Nổi Bật

* **📅 Thời khóa biểu & Lịch học thông minh:**
  * Lưới lịch tháng trực quan với chỉ số ca học và trạng thái theo từng ngày.
  * Hiển thị danh sách môn học, phòng học, giảng viên, đề cương tóm tắt.
  * Tự động nhận diện môn học trực tuyến (E-learning), ca học đang diễn ra, sắp tới hoặc đã kết thúc.
* **🌐 Truy cập LMS Courses một chạm:**
  * Tích hợp cơ chế SSO JWT Token tự động từ Portal UTH.
  * Chạm trực tiếp vào môn học trên lịch để mở thẳng lớp học phần trên `courses.ut.edu.vn` không cần đăng nhập lại.
* **📊 Quản lý Điểm số & Tiến độ tích lũy:**
  * Tra cứu bảng điểm chi tiết, GPA thang 4 / thang 10, tổng tín chỉ hoàn thành.
  * Biểu đồ tỷ lệ tiến độ trực quan, phân loại học lực từng học kỳ.
* **💳 Thẻ sinh viên điện tử & Tiện ích:**
  * Mã vạch sinh viên số hóa, thông tin lớp, niên khóa và ngành học.
  * Tra cứu nhanh học phí, lịch thi, tra cứu chương trình đào tạo.
* **⚡ Tối ưu hiệu năng & Caching:**
  * Lưu trữ đệm thông minh (Smart In-Memory Caching) cho lịch tuần, tháng và ngày, giảm thiểu tải API.
  * Giao diện Dark Mode / Light Mode mượt mà.

---

## 🛠 Hướng Dẫn Build & Triển Khai

### 1. Chuẩn bị môi trường
* Flutter SDK: `>= 3.13.5`
* Dart SDK: `>= 3.13.5`
* Android Studio / Xcode (dành cho iOS)

### 2. Cài đặt dependencies
```bash
flutter pub get
```

### 3. Kiểm tra mã nguồn & Tests
```bash
dart analyze
flutter test
```

### 4. Build bản phát hành (Release)

* **Build Android APK:**
```bash
flutter build apk --release
```
*File APK đầu ra:* `build/app/outputs/flutter-apk/app-release.apk`

* **Build Android App Bundle (AAB):**
```bash
flutter build appbundle --release
```

* **Build Web:**
```bash
flutter build web --release
```

---

## 🎨 Logo & Nhận diện thương hiệu

* **Tên ứng dụng:** UTH Flow
* **Tông màu chủ đạo:** Deep Teal (`#008689`), Cyan Turquoise (`#2DD4BF`), Midnight Navy (`#0A2540`).
* **Biểu tượng:** Ruy băng uốn lượn phong cách dòng chảy (Flow) tạo thành biểu tượng chữ U mềm mại và vô tận, đại diện cho dòng chảy học tập không ngừng và sự kết nối thông suốt của sinh viên UTH.

---

## 📄 Bản quyền & Tác giả
Phát triển dành cho cộng đồng sinh viên Trường Đại học Giao thông Vận tải TP.HCM.
