# Changelog

Tất cả các thay đổi đáng chú ý của dự án **UTH Flow** sẽ được ghi chép tại tài liệu này.

---

## [0.0.1] - 2026-10-20

### 🚀 Ra mắt phiên bản đầu tiên (Initial Alpha Release)

Phiên bản đầu tiên của **UTH Flow** - Ứng dụng trợ lý học tập thông minh và hiện đại dành riêng cho sinh viên Trường Đại học Giao thông vận tải TP.HCM (UTH).

#### ✨ Tính năng nổi bật

- **Lịch học & Thời khóa biểu thông minh**:
  - Tự động hiển thị lịch học hôm nay hoặc ca học ngày mai khi hôm nay không có lớp.
  - Giao diện Timeline hiện đại: phân biệt ca đang diễn ra (*Đang học*), ca sắp tới và ca đã kết thúc.
  - Lịch tháng (Calendar view) trực quan với chấm chỉ thị ngày có môn học.
  - **Một chạm vào LMS Courses**: Chạm trực tiếp vào ca học để mở ngay trang khoá học trên Moodle LMS.

- **Kết quả học tập & Tổng quan GPA**:
  - Tra cứu điểm trung bình tích lũy GPA (Hệ 4 và Hệ 10).
  - Biểu đồ tiến độ hoàn thành tín chỉ dạng Donut Chart và biểu đồ cột điểm số từng học kỳ.
  - Bảng điểm chi tiết từng môn học theo từng học kỳ.

- **Đồng bộ Deadlines Moodle LMS**:
  - Xem danh sách bài tập, bài kiểm tra sắp đến hạn từ LMS Moodle.
  - Bộ lọc thời gian tiện lợi: 1 ngày, 7 ngày, 30 ngày và tất cả.

- **Thẻ sinh viên điện tử & Mã vạch**:
  - Thẻ sinh viên số hóa chuẩn nhận diện thương hiệu UTH.
  - Tích hợp mã vạch Barcode tạo từ MSSV để quét mượn sách thư viện và điểm danh.

- **Đa tài khoản (Account Switcher)**:
  - Lưu và chuyển đổi mượt mà giữa nhiều tài khoản sinh viên khác nhau.
  - Bảo mật thông tin đăng nhập với `flutter_secure_storage`.

- **Cổng tiện ích sinh viên**:
  - Tổng hợp đầy đủ các dịch vụ công và cổng đào tạo từ Portal UTH kèm công cụ tìm kiếm nhanh.
  - Kênh thông báo nhanh từ Portal UTH với cơ chế phòng ngừa lỗi mạng và timeout 3s.

- **Giao diện & Tối ưu hóa**:
  - Tone màu chủ đạo Teal `#008689` đặc trưng kết hợp Dark/Light mode linh hoạt.
  - Tối ưu hóa dung lượng: Tree-shaking icon giảm hơn 97%, hỗ trợ offline caching.
