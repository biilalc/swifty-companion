// 42 "users" endpoint'i ile konusan katman. HTTP hatalarini uygulamaya
// ozel exception'lara cevirir - boylece UI katmani Dio'ya bagimli olmaz.

import 'package:dio/dio.dart';

import '../../../core/errors/app_exceptions.dart' as app_err;
import '../../../core/utils/logger.dart';
import '../../models/user_model.dart';

class UserApi {
  final Dio _dio;

  UserApi(this._dio);

  /// Login'i verilen kullanicinin tum detaylarini getirir.
  /// Endpoint: GET /v2/users/:login
  ///
  /// Throws:
  /// - [UserNotFoundException] eger login 404 donduyse.
  /// - [RateLimitException] 429'da.
  /// - [UnauthorizedException] 401'de (refresh bile kurtaramadiysa).
  /// - [NetworkException] ag hatalarinda.
  /// - [TimeoutException] timeout'ta.
  /// - [ServerException] 5xx'te.
  Future<UserModel> getUserByLogin(String login) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/v2/users/$login');
      if (response.data == null) {
        throw const app_err.UnknownException('Empty response');
      }
      return UserModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapDioError(e, loginForNotFound: login);
    } catch (e, st) {
      appLogger.e('getUserByLogin beklenmedik hata',
          error: e, stackTrace: st);
      throw app_err.UnknownException('Failed to fetch user', e);
    }
  }

  /// Giris yapmis kullanicinin kendi profilini getirir.
  /// Endpoint: GET /v2/me
  Future<UserModel> getMe() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/v2/me');
      if (response.data == null) {
        throw const app_err.UnknownException('Empty response');
      }
      return UserModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapDioError(e);
    } catch (e, st) {
      appLogger.e('getMe beklenmedik hata', error: e, stackTrace: st);
      throw app_err.UnknownException('Failed to fetch /me', e);
    }
  }

  /// Tum Dio exception turlerini AppException hierarsisine cevirir.
  /// Bu tek noktada toplamak UI katmaninin her hata turunu ayri ayri
  /// handle etmek zorunda kalmamasini saglar.
  app_err.AppException _mapDioError(
    DioException e, {
    String? loginForNotFound,
  }) {
    final status = e.response?.statusCode;
    appLogger.w('API hatasi: status=$status, type=${e.type}, msg=${e.message}');

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return app_err.TimeoutException('API request timed out', e);
      case DioExceptionType.connectionError:
        return app_err.NetworkException('Cannot connect to 42 API', e);
      case DioExceptionType.badCertificate:
        return app_err.NetworkException('Invalid SSL certificate', e);
      case DioExceptionType.cancel:
        // Cancel genellikle AuthInterceptor'un token yok demesiyle olur.
        final inner = e.error;
        if (inner is app_err.AppException) return inner;
        return app_err.UnauthorizedException('Request cancelled', e);
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        // status code'a gore siniflan.
        break;
    }

    if (status == null) {
      return app_err.UnknownException('Unknown error', e);
    }
    if (status == 401) {
      return app_err.UnauthorizedException('Session expired', e);
    }
    if (status == 403) {
      // 42 API bazen erisimi reddeder (ornek: staff'a ozel data).
      return app_err.UnauthorizedException('Access forbidden', e);
    }
    if (status == 404 && loginForNotFound != null) {
      return app_err.UserNotFoundException(loginForNotFound, cause: e);
    }
    if (status == 404) {
      return const app_err.UnknownException('Resource not found');
    }
    if (status == 429) {
      final retryAfter = int.tryParse(
        e.response?.headers.value('retry-after') ?? '',
      );
      return app_err.RateLimitException(
        retryAfterSeconds: retryAfter,
        cause: e,
      );
    }
    if (status >= 500) {
      return app_err.ServerException(statusCode: status, cause: e);
    }
    return app_err.UnknownException('HTTP $status', e);
  }
}
