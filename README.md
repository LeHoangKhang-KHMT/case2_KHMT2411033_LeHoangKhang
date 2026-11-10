# Case Study 2 - Ứng dụng quản lý và giao công việc nhóm

- MSSV: KHMT2411033
- Họ tên: Lê Hoàng Khang

## Công nghệ
Flutter (TaskManager) · Node.js/Express (api) · MongoDB Atlas · JWT · Nodemailer

## Chức năng
- A. Tài khoản: đăng ký, đăng nhập, đăng xuất, xem/cập nhật thông tin, đổi mật khẩu
- B. Công việc: tạo, xem danh sách/chi tiết, sửa, xóa, cập nhật trạng thái, tìm kiếm, lọc, sắp xếp
- C. Giao việc và chia sẻ: giao nhiều người, người phụ trách chính, chia sẻ viewer/editor, thu hồi quyền
- D. Thông báo: thông báo trong ứng dụng, email, lịch sử email, nhắc việc trước hạn
- E. Thống kê: theo trạng thái, giao việc/phụ trách, sắp đến hạn/quá hạn, lịch sử hoạt động

## Cách chạy

### 1. Backend (`api`)
```bash
cd api
npm install
cp .env.example .env
```
Mở `api/.env` và điền:
- `MONGODB_URI`: chuỗi kết nối MongoDB Atlas (có tên database `task_manager`)
- `JWT_SECRET`: chuỗi bí mật bất kỳ
- (Tùy chọn) `SMTP_USER`, `SMTP_PASS`, `MAIL_FROM` để gửi email thật qua Gmail

```bash
npm run dev
```
API chạy tại `http://localhost:3000`. Kiểm tra: `http://localhost:3000/api/health`.

Lưu ý: cần thêm địa chỉ IP của máy vào **Network Access** của Atlas.

### 2. Ứng dụng Flutter (`TaskManager`)
```bash
cd TaskManager
flutter pub get
flutter run -d chrome
```
Địa chỉ API nằm trong `TaskManager/lib/utils/constants.dart` (`kBaseUrl`):
- Chrome: `http://localhost:3000/api`
- Android emulator: `http://10.0.2.2:3000/api`
- Điện thoại thật: `http://<IP máy chạy backend>:3000/api`

## Cấu trúc thư mục
- `api/`: backend Express (models, controllers, routes, services, middleware)
- `TaskManager/`: ứng dụng Flutter (screens, services, models, widgets)