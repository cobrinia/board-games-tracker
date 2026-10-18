import 'package:board_games/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.email', () {
    test('accepts normal addresses', () {
      expect(Validators.email('pavlo@lpnu.ua'), isNull);
      expect(Validators.email('  a.b+games@gmail.com '), isNull);
    });
    test('rejects empty and malformed values', () {
      expect(Validators.email(''), 'Please enter your email');
      expect(Validators.email('pavlo'), 'Please enter a valid email address');
      expect(Validators.email('pavlo@lpnu'), 'Please enter a valid email address');
      expect(Validators.email('a b@c.com'), 'Please enter a valid email address');
    });
  });

  group('Validators.newPassword', () {
    test('needs 8+ characters with letters and digits', () {
      expect(Validators.newPassword('board123'), isNull);
      expect(Validators.newPassword('short1'), 'At least 8 characters');
      expect(Validators.newPassword('password'), 'Use both letters and numbers');
      expect(Validators.newPassword('12345678'), 'Use both letters and numbers');
      expect(
        Validators.newPassword('board 123'),
        'Password must not contain spaces',
      );
    });
  });

  test('confirmPassword compares with the current password text', () {
    var password = 'board123';
    final validate = Validators.confirmPassword(() => password);
    expect(validate('board123'), isNull);
    password = 'changed99';
    expect(validate('board123'), 'Passwords do not match');
    expect(validate(''), 'Please repeat the password');
  });

  test('name is required, 2–30 characters and contains letters', () {
    expect(Validators.name('Pavlo'), isNull);
    expect(Validators.name('Павло'), isNull);
    expect(Validators.name(' '), 'Please enter your name');
    expect(Validators.name('P'), 'Name is too short (min 2 characters)');
    expect(Validators.name('1234'), 'Name must contain letters');
    expect(Validators.name('a' * 31), 'Name is too long (max 30 characters)');
  });

  test('httpsUrl accepts only https links', () {
    expect(Validators.httpsUrl('https://example.com/a.png'), isNull);
    expect(
      Validators.httpsUrl('http://example.com/a.png'),
      'The link must start with https://',
    );
    expect(Validators.httpsUrl('not a link'), 'This is not a valid link');
  });
}
