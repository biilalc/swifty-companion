// Home ekraninin state'ini tutan provider. Kendi profil bilgimizi
// cekmek ve arama girisinin validasyonundan sorumlu.

import 'package:flutter/foundation.dart';

import '../../core/errors/app_exceptions.dart';
import '../../core/utils/logger.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';

enum HomeStatus { idle, loading, loaded, error }

class HomeProvider extends ChangeNotifier {
  final UserRepository _repo;

  HomeProvider(this._repo);

  HomeStatus _status = HomeStatus.idle;
  UserModel? _me;
  String? _errorKey;
  Map<String, String>? _errorArgs;

  HomeStatus get status => _status;
  UserModel? get me => _me;
  String? get errorKey => _errorKey;
  Map<String, String>? get errorArgs => _errorArgs;
  bool get isLoading => _status == HomeStatus.loading;

  /// Kendi profilimizi getirir. Home ekrani acilir acilmaz cagirilir.
  Future<void> loadMe({bool force = false}) async {
    // Force degilse ve zaten yuklediysek tekrar cagirma (gereksiz API hit).
    if (!force && _me != null) return;
    _status = HomeStatus.loading;
    _errorKey = null;
    _errorArgs = null;
    notifyListeners();

    try {
      _me = await _repo.getMe();
      _status = HomeStatus.loaded;
    } on AppException catch (e) {
      appLogger.w('loadMe basarisiz: ${e.message}');
      _errorKey = _mapToErrorKey(e);
      _status = HomeStatus.error;
    } catch (e, st) {
      appLogger.e('loadMe beklenmedik hata', error: e, stackTrace: st);
      _errorKey = 'errors.unknown';
      _status = HomeStatus.error;
    }
    notifyListeners();
  }

  /// AppException'ları easy_localization key'lerine cevirir.
  String _mapToErrorKey(AppException e) {
    if (e is NetworkException) return 'errors.network';
    if (e is TimeoutException) return 'errors.timeout';
    if (e is UnauthorizedException) return 'errors.unauthorized';
    if (e is RateLimitException) return 'errors.rate_limited';
    if (e is ServerException) return 'errors.server';
    return 'errors.unknown';
  }
}
