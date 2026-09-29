import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract final class ThemeController {
  static const _storage = FlutterSecureStorage();
  static final mode=ValueNotifier<ThemeMode>(ThemeMode.light);
  static Future<void> load() async => set(await _storage.read(key: 'theme_mode') ?? 'light', persist: false);
  static Future<void> set(String value,{bool persist=true}) async {
    mode.value=value=='dark'?ThemeMode.dark:ThemeMode.light;
    if(persist)await _storage.write(key:'theme_mode',value:value);
  }
  static Future<void> toggle()=>set(mode.value==ThemeMode.dark?'light':'dark');
  static String get value=>switch(mode.value){ThemeMode.dark=>'dark',ThemeMode.light=>'light',_=>'system'};
}
