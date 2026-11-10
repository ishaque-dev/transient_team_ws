import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transient_team_ws/core/constants/app_strings.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit(this._preferences) : super(_read(_preferences));

  final SharedPreferences _preferences;

  static ThemeMode _read(SharedPreferences preferences) {
    final stored = preferences.getString(AppStrings.sharedPrefThemeKey);
    return ThemeMode.values.asNameMap()[stored] ?? ThemeMode.dark;
  }

  Future<void> setMode(ThemeMode mode) async {
    emit(mode);
    await _preferences.setString(AppStrings.sharedPrefThemeKey, mode.name);
  }
}
