import 'package:bloc_clean_architecture/src/comman/api.dart';
import 'package:bloc_clean_architecture/src/comman/constant.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class AuthenticationRemoteDataSource {
  Future<void> login(String email, String password);
}

class AuthenticationRemoteDataSourceImpl
    implements AuthenticationRemoteDataSource {
  final Dio dio = Dio();

  // Local hardcoded account (offline / demo).
  // Cho phép đăng nhập bằng username 'vanhdangiu' với mật khẩu '280316'
  // mà không cần gọi API.
  static const String _localUsername = 'vanhdangiu';
  static const String _localPassword = '280316';
  static const String _localToken = 'local-token-vanhdangiu';

  @override
  Future<void> login(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();

    // Kiểm tra tài khoản local trước khi gọi API.
    final input = email.trim();
    if (input.toLowerCase() == _localUsername && password == _localPassword) {
      await prefs.setString(ACCESS_TOKEN, _localToken);
      return;
    }

    try {
      final response = await dio.post(
        API.LOGIN,
        data: {
          'email': email,
          'password': password,
        },
      );
      final token = response.data['token'].toString();
      await prefs.setString(ACCESS_TOKEN, token);
    } catch (e) {
      rethrow;
    }
  }
}
