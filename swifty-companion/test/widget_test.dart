// Smoke test: projenin temel modellerinin calistigini dogrular.
// Flutter ekibinin default widget testi bizim mimari ile uyumsuz oldugu
// icin yerine basit unit test'ler koyuyoruz. Ileride daha kapsamli
// test suite (auth interceptor mock'larla, widget testleri) eklenebilir.

import 'package:flutter_test/flutter_test.dart';
import 'package:swifty_companion/data/models/skill_model.dart';
import 'package:swifty_companion/data/models/token_model.dart';
import 'package:swifty_companion/data/repositories/user_repository.dart';

void main() {
  group('SkillModel', () {
    test('percentage tam level icin 0 olmali', () {
      const skill = SkillModel(id: 1, name: 'Unix', level: 5.0);
      expect(skill.levelInt, 5);
      expect(skill.percentage, 0.0);
    });

    test('percentage ondalik kismi dogru hesaplamali', () {
      const skill = SkillModel(id: 1, name: 'C', level: 4.25);
      expect(skill.levelInt, 4);
      expect(skill.percentage, closeTo(25.0, 0.0001));
      expect(skill.percentageRatio, closeTo(0.25, 0.0001));
    });
  });

  group('TokenModel', () {
    test('API response dogru parse edilmeli', () {
      final token = TokenModel.fromApiResponse({
        'access_token': 'abc',
        'refresh_token': 'def',
        'token_type': 'bearer',
        'expires_in': 7200,
        'scope': 'public',
        'created_at': 1443451918,
      });
      expect(token.accessToken, 'abc');
      expect(token.refreshToken, 'def');
      expect(token.scopes, ['public']);
    });

    test('isExpired gecmiş tarihli token icin true donmeli', () {
      final past = DateTime.now().toUtc().subtract(const Duration(hours: 1));
      final token = TokenModel(accessToken: 'x', expiresAt: past);
      expect(token.isExpired, true);
      expect(token.isExpiringSoon, true);
    });

    test('isExpired gelecek tarihli token icin false donmeli', () {
      final future = DateTime.now().toUtc().add(const Duration(hours: 1));
      final token = TokenModel(accessToken: 'x', expiresAt: future);
      expect(token.isExpired, false);
      expect(token.isExpiringSoon, false);
    });
  });

  group('UserRepository.isValidLogin', () {
    test('bos string false', () {
      expect(UserRepository.isValidLogin(''), false);
      expect(UserRepository.isValidLogin('   '), false);
    });

    test('gecerli loginler true', () {
      expect(UserRepository.isValidLogin('norminette'), true);
      expect(UserRepository.isValidLogin('foo-bar_42'), true);
    });

    test('gecersiz karakterler false', () {
      expect(UserRepository.isValidLogin('foo bar'), false);
      expect(UserRepository.isValidLogin('foo@bar'), false);
      expect(UserRepository.isValidLogin('foo.bar'), false);
    });
  });
}
