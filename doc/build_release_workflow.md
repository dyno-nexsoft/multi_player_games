# GitHub Actions CI/CD Workflow — Build & Release APK

Tài liệu này hướng dẫn cách hoạt động của hệ thống CI/CD (GitHub Actions) để tự động hóa quy trình build và phân phối tệp APK cho dự án Party Game Hub.

---

## 1. Tổng Quan Workflow

Luồng CI/CD được cấu hình để thực hiện 2 nhiệm vụ chính:
1. **Build & Verify**: Biên dịch mã nguồn Flutter sang tệp APK Release khi có thay đổi mã nguồn mới (push/pull request/chạy thủ công).
2. **Release**: Tự động tạo một GitHub Release mới và đính kèm tệp APK Release khi có một phiên bản mới được đánh tag (ví dụ: `v1.0.0`).

Tệp cấu hình nằm tại: [release_apk.yml](file:///e:/Projects/multi_player_games/.github/workflows/release_apk.yml)

---

## 2. Kịch Bản Kích Hoạt (Triggers)

Workflow hỗ trợ 3 hình thức kích hoạt:
- **Push lên nhánh `main`**: Tự động build để xác minh không có lỗi biên dịch.
- **Push thẻ phiên bản (Tags matching `v*`)**: Tự động build và tạo Release trên GitHub kèm APK.
- **Chạy thủ công (`workflow_dispatch`)**: Cho phép dev bấm nút "Run workflow" trên giao diện GitHub Actions để tải APK về bất cứ lúc nào.

---

## 3. Các Bước Build Chi Tiết (Build Steps)

Do mã nguồn Flutter nằm trong thư mục con `code/`, toàn bộ các lệnh build đều được thực thi tại thư mục này thông qua thiết lập `defaults.run.working-directory: code`.

Các bước thực hiện trong runner `ubuntu-latest`:
1. **Checkout Code**: Lấy mã nguồn từ GitHub.
2. **Setup Java 17 (Temurin)**: Cài đặt JDK phiên bản 17 (Gradle yêu cầu để biên dịch Android). Cấu hình cache cho Gradle giúp tăng tốc build các lần sau.
3. **Setup Flutter**: Cài đặt SDK Flutter kênh `stable` và bật tính năng cache SDK.
4. **Install Dependencies**: Chạy lệnh `flutter pub get`.
5. **Build APK**: Chạy lệnh `flutter build apk --release`.
6. **Upload APK Artifact**: Tải tệp `app-release.apk` lên hệ thống lưu trữ tạm thời của GitHub Action (tải về từ trang Summary của Action run).

---

## 4. Quy Trình Tạo Release (Release Step)

Khi tag có định dạng bắt đầu bằng chữ `v` (ví dụ `v1.0.0`) được push lên GitHub:
1. Workflow tải tệp APK đã build thành công từ bước trước.
2. Sử dụng Action `softprops/action-gh-release@v2` để tạo mới một bản Release trên GitHub.
3. Đính kèm tệp `app-release.apk` vào bản Release đó để người dùng tải trực tiếp.

---

## 5. Lưu Ý Về Ký Chữ Ký (Android Signing)

Hiện tại, cấu hình Gradle của ứng dụng (`code/android/app/build.gradle.kts`) đang sử dụng chữ ký Debug cho bản Release:
```kotlin
buildTypes {
    release {
        // Signing with the debug keys for now, so `flutter run --release` works.
        signingConfig = signingConfigs.getByName("debug")
    }
}
```

Do đó, tệp APK đầu ra từ CI/CD có thể cài đặt trực tiếp trên thiết bị Android để thử nghiệm nhưng chưa đủ điều kiện để upload lên Google Play Store.

### Hướng dẫn nâng cấp ký chữ ký thật (khi deploy Play Store)
Khi cần phát hành chính thức:
1. Tạo keystore: `keytool -genkey -v -keystore my-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias my-key-alias`
2. Mã hóa file `.jks` sang dạng base64 string:
   - Trên Linux/macOS: `openssl base64 -in my-release-key.jks -out keystore-base64.txt`
   - Trên Windows (PowerShell): `[Convert]::ToBase64String([IO.File]::ReadAllBytes("my-release-key.jks")) > keystore-base64.txt`
3. Thêm các Secret sau vào GitHub Repository:
   - `KEYSTORE_BASE64`: Nội dung tệp `keystore-base64.txt`.
   - `KEYSTORE_PASSWORD`: Mật khẩu của keystore.
   - `KEY_ALIAS`: Alias của key.
   - `KEY_PASSWORD`: Mật khẩu của key.
4. Cập nhật workflow để giải mã file keystore và cấu hình Gradle đọc từ Environment Variables.
