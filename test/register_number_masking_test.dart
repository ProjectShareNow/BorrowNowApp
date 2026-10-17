import 'package:flutter_test/flutter_test.dart';
import 'package:borrow_now/utils/helpers.dart';

void main() {
  group('Register Number Masking Tests', () {
    test('Masks last 3 characters with *** and preserves all preceding characters', () {
      expect(AppHelpers.maskRegisterNumber('CE20CS1234'), 'CE20CS1***');
      expect(AppHelpers.maskRegisterNumber('ABC12345'), 'ABC12***');
      expect(AppHelpers.maskRegisterNumber('1234'), '1***');
      expect(AppHelpers.maskRegisterNumber('710021104001'), '710021104***');
    });

    test('Handles short strings (<= 3 characters) by replacing each character with an asterisk', () {
      expect(AppHelpers.maskRegisterNumber('123'), '***');
      expect(AppHelpers.maskRegisterNumber('ABC'), '***');
      expect(AppHelpers.maskRegisterNumber('12'), '**');
      expect(AppHelpers.maskRegisterNumber('AB'), '**');
      expect(AppHelpers.maskRegisterNumber('1'), '*');
      expect(AppHelpers.maskRegisterNumber('A'), '*');
    });

    test('Handles null, empty, and whitespace strings safely returning N/A', () {
      expect(AppHelpers.maskRegisterNumber(null), 'N/A');
      expect(AppHelpers.maskRegisterNumber(''), 'N/A');
      expect(AppHelpers.maskRegisterNumber('   '), 'N/A');
    });

    test('Trims surrounding whitespace before masking', () {
      expect(AppHelpers.maskRegisterNumber('  CE20CS1234  '), 'CE20CS1***');
      expect(AppHelpers.maskRegisterNumber('  1234 '), '1***');
    });
  });
}
