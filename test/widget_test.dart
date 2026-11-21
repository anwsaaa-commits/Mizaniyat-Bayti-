import 'package:flutter_test/flutter_test.dart';
import 'package:mizaniyat_bayti/core/constants/app_constants.dart';

void main() {
  test('application metadata is configured in Arabic', () {
    expect(AppConstants.appName, 'ميزانية بيتي');
    expect(AppConstants.currencySymbol, 'ر.ي');
    expect(AppConstants.databaseVersion, greaterThan(0));
  });

  test('default expense categories are present and unique', () {
    expect(AppConstants.defaultCategories, isNotEmpty);
    expect(
      AppConstants.defaultCategories.toSet().length,
      AppConstants.defaultCategories.length,
    );
    expect(AppConstants.defaultCategories, contains('مواد غذائية'));
    expect(AppConstants.defaultCategories, contains('كهرباء'));
  });
}
