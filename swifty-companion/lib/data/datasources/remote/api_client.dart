// 42 API ile konusmak icin yapilandirilmis Dio client. AuthInterceptor
// ile birlikte calisir. Timeout'lar production icin makul degerlerle
// ayarlandi.

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/config/env_config.dart';
import '../../../core/utils/logger.dart';
import 'auth_interceptor.dart';

class ApiClient {
  final Dio dio;

  ApiClient._(this.dio);

  factory ApiClient.create({required AuthInterceptor authInterceptor}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: EnvConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        headers: const {
          'Accept': 'application/json',
        },
        // Sadece 2xx'i basarili say; digerlerini exception'a ceviririm ki
        // repository katmaninda try/catch ile anlamli hata uretebilelim.
        validateStatus: (status) => status != null && status >= 200 && status < 300,
        // 42 API rate limit cok dar (2 req/sn); fazla istek yigmamak icin.
        responseType: ResponseType.json,
      ),
    );

    dio.interceptors.add(authInterceptor);

    // Debug modunda isteklerin log'lanmasi hayat kurtarir. Release'de kapali.
    if (kDebugMode) {
      dio.interceptors.add(_LoggingInterceptor());
    }

    return ApiClient._(dio);
  }
}

/// Basit ama kullanisli bir isteklog interceptor'i. Token gibi hassas
/// bilgileri log'lamamaya dikkat ediyor.
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    appLogger.d('-> ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    appLogger.d(
      '<- ${response.statusCode} ${response.requestOptions.uri}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    appLogger.w(
      '!! ${err.response?.statusCode} ${err.requestOptions.uri} - ${err.message}',
    );
    handler.next(err);
  }
}
