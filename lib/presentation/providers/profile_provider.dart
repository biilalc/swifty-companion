// Profile ekraninin state'ini yonetir. Aranan kullaniciyi fetch eder,
// cursus secimi gibi UI state'ini de burada tutar.

import 'package:flutter/foundation.dart';

import '../../core/errors/app_exceptions.dart';
import '../../core/utils/logger.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';

enum ProfileStatus { idle, loading, loaded, error }

class ProfileProvider extends ChangeNotifier {
  final UserRepository _repo;

  ProfileProvider(this._repo);

  ProfileStatus _status = ProfileStatus.idle;
  UserModel? _user;
  String? _errorKey;
  Map<String, String>? _errorArgs;

  /// Kullanici birden fazla cursus'a dahilse hangisinin gosterildiginin
  /// takibi. null ise primaryCursus gosterilir.
  int? _selectedCursusId;

  ProfileStatus get status => _status;
  UserModel? get user => _user;
  String? get errorKey => _errorKey;
  Map<String, String>? get errorArgs => _errorArgs;
  int? get selectedCursusId => _selectedCursusId;
  bool get isLoading => _status == ProfileStatus.loading;

  /// Verilen login'in detaylarini fetch eder.
  Future<void> loadUser(String login) async {
    _status = ProfileStatus.loading;
    _errorKey = null;
    _errorArgs = null;
    _user = null;
    _selectedCursusId = null;
    notifyListeners();

    try {
      final user = await _repo.getUser(login);
      _user = user;
      // Varsayilan cursus olarak primaryCursus'u sec.
      _selectedCursusId = user.primaryCursus?.cursusId;
      _status = ProfileStatus.loaded;
    } on UserNotFoundException catch (e) {
      appLogger.i('Kullanici bulunamadi: ${e.login}');
      _errorKey = 'errors.user_not_found';
      _errorArgs = {'login': e.login};
      _status = ProfileStatus.error;
    } on AppException catch (e) {
      appLogger.w('loadUser hatasi: ${e.message}');
      _errorKey = _mapToErrorKey(e);
      _status = ProfileStatus.error;
    } catch (e, st) {
      appLogger.e('loadUser beklenmedik hata', error: e, stackTrace: st);
      _errorKey = 'errors.unknown';
      _status = ProfileStatus.error;
    }
    notifyListeners();
  }

  /// Kullanicinin baska bir cursus'una gecis yaparken cagrilir.
  void selectCursus(int cursusId) {
    if (_selectedCursusId == cursusId) return;
    _selectedCursusId = cursusId;
    notifyListeners();
  }

  /// Manuel retry icin.
  Future<void> retry() async {
    final login = _user?.login;
    if (login != null) {
      await loadUser(login);
    }
  }

  /// Yeni bir profile girmeden state'i temizler (iyi UX icin).
  void clear() {
    _user = null;
    _status = ProfileStatus.idle;
    _errorKey = null;
    _errorArgs = null;
    _selectedCursusId = null;
    notifyListeners();
  }

  String _mapToErrorKey(AppException e) {
    if (e is NetworkException) return 'errors.network';
    if (e is TimeoutException) return 'errors.timeout';
    if (e is UnauthorizedException) return 'errors.unauthorized';
    if (e is RateLimitException) return 'errors.rate_limited';
    if (e is ServerException) return 'errors.server';
    return 'errors.unknown';
  }
}
