import 'package:flutter/material.dart';

abstract final class ThemeController {
  static final mode=ValueNotifier<ThemeMode>(ThemeMode.light);
  static void set(String value){mode.value=switch(value){'dark'=>ThemeMode.dark,'light'=>ThemeMode.light,_=>ThemeMode.system};}
  static String get value=>switch(mode.value){ThemeMode.dark=>'dark',ThemeMode.light=>'light',_=>'system'};
}
