import 'package:flutter_test/flutter_test.dart';
import 'package:reducer/core/utils/target_dimension_calculator.dart';

void main() {
  group('TargetDimensions.fromScale', () {
    test('should correctly scale 100x100 to 50x50 with 50% scale', () {
      final result = TargetDimensions.fromScale(
        originalWidth: 100,
        originalHeight: 100,
        scalePercent: 50,
      );
      expect(result.width, 50);
      expect(result.height, 50);
    });

    test('should handle rounding (101x101 at 50% -> 50x50)', () {
      final result = TargetDimensions.fromScale(
        originalWidth: 101,
        originalHeight: 101,
        scalePercent: 50,
      );
      // 101 * 0.5 = 50.5 -> toInt() = 50
      expect(result.width, 50);
      expect(result.height, 50);
    });

    test('should respect minimum constraint', () {
      final result = TargetDimensions.fromScale(
        originalWidth: 10,
        originalHeight: 10,
        scalePercent: 5,
        min: 5,
      );
      // 10 * 0.05 = 0.5 -> clamped to 5
      expect(result.width, 5);
      expect(result.height, 5);
    });

    test('should respect maximum constraint', () {
      final result = TargetDimensions.fromScale(
        originalWidth: 1000,
        originalHeight: 1000,
        scalePercent: 200,
        max: 1500,
      );
      expect(result.width, 1500);
      expect(result.height, 1500);
    });

    test('should handle 0% scale', () {
      final result = TargetDimensions.fromScale(
        originalWidth: 100,
        originalHeight: 100,
        scalePercent: 0,
        min: 1,
      );
      expect(result.width, 1);
      expect(result.height, 1);
    });
  });
}
