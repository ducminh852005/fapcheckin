import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'cloudinary_config.dart';

/// Kết quả trả về sau khi tải ảnh lên Cloudinary
class CloudinaryUploadResult {
  final String url;
  final String secureUrl;
  final String publicId;
  final String format;
  final int? width;
  final int? height;
  final int? bytes;

  const CloudinaryUploadResult({
    required this.url,
    required this.secureUrl,
    required this.publicId,
    required this.format,
    this.width,
    this.height,
    this.bytes,
  });

  factory CloudinaryUploadResult.fromJson(Map<String, dynamic> json) {
    return CloudinaryUploadResult(
      url: (json['url'] ?? '').toString(),
      secureUrl: (json['secure_url'] ?? json['url'] ?? '').toString(),
      publicId: (json['public_id'] ?? '').toString(),
      format: (json['format'] ?? '').toString(),
      width: json['width'] is int ? json['width'] as int : null,
      height: json['height'] is int ? json['height'] as int : null,
      bytes: json['bytes'] is int ? json['bytes'] as int : null,
    );
  }
}

/// Dịch vụ tải ảnh đại diện lên Cloudinary cho Mobile
class CloudinaryService {
  CloudinaryService({Dio? client}) : _dio = client ?? Dio();
  final Dio _dio;

  /// Tải ảnh lên Cloudinary vào thư mục [folder] (mặc định: 'cloudary')
  Future<CloudinaryUploadResult> uploadAvatar({
    required Uint8List bytes,
    required String fileName,
    String? folder,
    String? cloudName,
    String? uploadPreset,
  }) async {
    final name = cloudName ?? CloudinaryConfig.cloudName;
    final preset = uploadPreset ?? CloudinaryConfig.uploadPreset;
    final targetFolder = folder ?? CloudinaryConfig.folder;

    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
      'upload_preset': preset,
      'folder': targetFolder,
    });

    final endpoint = 'https://api.cloudinary.com/v1_1/$name/image/upload';
    final response = await _dio.post(
      endpoint,
      data: formData,
      options: Options(
        headers: {'Accept': 'application/json'},
        sendTimeout: const Duration(seconds: 25),
        receiveTimeout: const Duration(seconds: 25),
      ),
    );

    if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
      return CloudinaryUploadResult.fromJson(
        response.data as Map<String, dynamic>,
      );
    }

    throw Exception(
      'Tải ảnh lên Cloudinary thất bại: HTTP ${response.statusCode}',
    );
  }
}

