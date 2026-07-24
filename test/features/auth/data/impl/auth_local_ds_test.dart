import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transient_team_ws/core/constants/app_strings.dart';
import 'package:transient_team_ws/core/error/common_failures.dart';
import 'package:transient_team_ws/features/auth/data/impl/auth_local_ds_impl.dart';
import 'package:transient_team_ws/features/auth/data/models/user_model.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  late AuthLocalDsImpl localDs;
  late MockSharedPreferences mockPrefs;

  setUp(() {
    mockPrefs = MockSharedPreferences();
    localDs = AuthLocalDsImpl(mockPrefs);
  });

  const tUserModel = UserModel(id: 'uid123', email: 'test@example.com');

  group('getCurrentUser', () {
    test('should return UserModel when there is a cached user', () async {
      // arrange
      when(() => mockPrefs.getString(AppStrings.sharedPrefUserKey))
          .thenReturn(jsonEncode(tUserModel.toJson()));

      // act
      final result = await localDs.getCurrentUser();

      // assert
      expect(result, tUserModel);
    });

    test('should return null when there is no cached user', () async {
      // arrange
      when(() => mockPrefs.getString(AppStrings.sharedPrefUserKey)).thenReturn(null);

      // act
      final result = await localDs.getCurrentUser();

      // assert
      expect(result, null);
    });
  });

  group('cacheCurrentUser', () {
    test('should call setString on SharedPreferences', () async {
      // arrange
      when(() => mockPrefs.setString(any(), any())).thenAnswer((_) async => true);

      // act
      await localDs.cacheCurrentUser(tUserModel);

      // assert
      verify(() => mockPrefs.setString(
            AppStrings.sharedPrefUserKey,
            jsonEncode(tUserModel.toJson()),
          )).called(1);
    });

    test('should throw CacheWriteFailure when saving fails', () async {
      // arrange
      when(() => mockPrefs.setString(any(), any())).thenAnswer((_) async => false);

      // act & assert
      expect(() => localDs.cacheCurrentUser(tUserModel), throwsA(isA<CacheWriteFailure>()));
    });
  });

  group('clearUser', () {
    test('should call remove on SharedPreferences', () async {
      // arrange
      when(() => mockPrefs.remove(any())).thenAnswer((_) async => true);

      // act
      await localDs.clearUser();

      // assert
      verify(() => mockPrefs.remove(AppStrings.sharedPrefUserKey)).called(1);
    });
  });
}
