import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

/// Upload ảnh lên Cloudinary qua unsigned upload preset → trả về `secure_url`.
///
/// Dùng chung cho avatar, ảnh sản phẩm... (truyền [folder] để phân loại).
/// Unsigned: an toàn gọi từ client, không cần API secret. Cấu hình cloud name +
/// preset trong `firebase_config.json` (xem AppConfig).
class Cloudinary {
  static Future<String> uploadImage(
    File file, {
    String folder = 'uploads',
  }) async {
    final cloud = AppConfig.cloudinaryCloudName;
    final preset = AppConfig.cloudinaryUploadPreset;
    if (cloud.isEmpty || preset.isEmpty) {
      throw Exception(
        'Cloudinary chưa cấu hình (CLOUDINARY_CLOUD_NAME/PRESET).',
      );
    }
    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloud/image/upload',
    );
    final req = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = preset
      ..fields['folder'] = folder
      ..files.add(await http.MultipartFile.fromPath('file', file.path));
    final res = await http.Response.fromStream(await req.send());
    if (res.statusCode != 200) {
      throw Exception('Cloudinary upload lỗi ${res.statusCode}: ${res.body}');
    }
    return jsonDecode(res.body)['secure_url'] as String;
  }
}
