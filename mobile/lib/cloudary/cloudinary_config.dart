/// Cấu hình Cloudinary cho việc lưu trữ hình ảnh trên ứng dụng FAP Check-in.
class CloudinaryConfig {
  CloudinaryConfig._();

  /// Cloud Name trên Cloudinary
  static String cloudName = const String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
    defaultValue: 'fapcheckin',
  );

  /// Upload preset unsigned (cho phép upload trực tiếp từ client)
  static String uploadPreset = const String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
    defaultValue: 'fapcheckin_avatars',
  );

  /// Thư mục lưu trữ ảnh đại diện trên Cloudinary (mặc định: 'cloudary')
  static String folder = const String.fromEnvironment(
    'CLOUDINARY_FOLDER',
    defaultValue: 'cloudary',
  );

  /// API Key (tùy chọn khi cần)
  static String apiKey = const String.fromEnvironment(
    'CLOUDINARY_API_KEY',
    defaultValue: '',
  );

  /// Cập nhật cấu hình động tại runtime
  static void update({
    String? newCloudName,
    String? newUploadPreset,
    String? newFolder,
  }) {
    if (newCloudName != null && newCloudName.trim().isNotEmpty) {
      cloudName = newCloudName.trim();
    }
    if (newUploadPreset != null && newUploadPreset.trim().isNotEmpty) {
      uploadPreset = newUploadPreset.trim();
    }
    if (newFolder != null && newFolder.trim().isNotEmpty) {
      folder = newFolder.trim();
    }
  }
}
