import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/quiz_model.dart';

class ApiService {
  // Đối với Windows desktop chạy local: sử dụng localhost hoặc 127.0.0.1
  // Đối với Android emulator: đổi thành http://10.0.2.2:5000/api
  // Đối với thiết bị thật: sử dụng địa chỉ IP nội bộ của máy tính bạn (ví dụ: http://192.168.1.50:5000/api)
  static const String baseUrl = 'https://exercise-afc3.onrender.com/api';

  // Lấy danh sách tất cả đề thi
  static Future<List<Quiz>> getQuizzes() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/quizzes')).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Quiz.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load quizzes. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối tới server: $e\nHãy đảm bảo server Node.js đang chạy và đúng địa chỉ IP/port.');
    }
  }

  // Lấy chi tiết một đề thi
  static Future<Quiz> getQuiz(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/quizzes/$id')).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        return Quiz.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load quiz details. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối tới server: $e');
    }
  }

  // Tạo một đề thi mới
  static Future<Quiz> createQuiz(Quiz quiz) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/quizzes'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(quiz.toJson()),
      ).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 201) {
        return Quiz.fromJson(jsonDecode(response.body));
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to create quiz');
      }
    } catch (e) {
      throw Exception('Lỗi khi tạo đề thi: $e');
    }
  }

  // Cập nhật đề thi đã có
  static Future<Quiz> updateQuiz(String id, Quiz quiz) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/quizzes/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(quiz.toJson()),
      ).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        return Quiz.fromJson(jsonDecode(response.body));
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update quiz');
      }
    } catch (e) {
      throw Exception('Lỗi khi cập nhật đề thi: $e');
    }
  }

  // Xóa đề thi (tiện ích mở rộng)
  static Future<void> deleteQuiz(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/quizzes/$id')).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete quiz. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Lỗi khi xóa đề thi: $e');
    }
  }
}
