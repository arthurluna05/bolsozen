import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class ThemePreferenceStore {
  Future<bool?> readDark();
  Future<void> saveDark(bool dark);
}

final class LocalThemePreferences implements ThemePreferenceStore {
  LocalThemePreferences({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();
  static const key = 'bolsozen.theme.dark';
  final SharedPreferencesAsync _preferences;
  @override
  Future<bool?> readDark() => _preferences.getBool(key);
  @override
  Future<void> saveDark(bool dark) => _preferences.setBool(key, dark);
}

final class ThemeController extends ChangeNotifier {
  ThemeController({this.store});
  final ThemePreferenceStore? store;
  ThemeMode _mode = ThemeMode.light;
  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;
  bool get isSaving => _saving;
  bool _saving = false, _disposed = false;
  String? failure;

  Future<void> load() async {
    try {
      final dark = await store?.readDark() ?? false;
      if (_disposed) return;
      _mode = dark ? ThemeMode.dark : ThemeMode.light;
    } catch (_) {
      if (_disposed) return;
      failure = 'Não foi possível ler a preferência de tema.';
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> setDark(bool dark) async {
    if (_disposed || _saving || dark == isDark) return;
    _saving = true;
    failure = null;
    final previous = _mode;
    _mode = dark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    try {
      await store?.saveDark(dark);
    } catch (_) {
      if (_disposed) return;
      _mode = previous;
      failure = 'Não foi possível salvar o tema. Tente novamente.';
    } finally {
      _saving = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class ThemeScope extends InheritedNotifier<ThemeController> {
  const ThemeScope({
    required ThemeController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);
  static ThemeController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ThemeScope>()?.notifier;
}
