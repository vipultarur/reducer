import 'package:flutter_test/flutter_test.dart';
import 'package:reducer/core/utils/target_dimension_calculator.dart';

void main() {
  group('TargetDimensionCalculator Tests', () {
    test('Calculates 50% scale correctly', () {
      final target = TargetDimensions.fromScale(
        originalWidth: 1000,
        originalHeight: 800,
        scalePercent: 50,
      );

      expect(target.width, 500);
      expect(target.height, 400);
    });

    test('Calculates 200% scale correctly', () {
      final target = TargetDimensions.fromScale(
        originalWidth: 100,
        originalHeight: 100,
        scalePercent: 200,
      );

      expect(target.width, 200);
      expect(target.height, 200);
    });

    test('Maintains minimum 1px dimension', () {
      final target = TargetDimensions.fromScale(
        originalWidth: 10,
        originalHeight: 10,
        scalePercent: 1,
      );

      expect(target.width, greaterThanOrEqualTo(1));
      expect(target.height, greaterThanOrEqualTo(1));
    });
  });
}
