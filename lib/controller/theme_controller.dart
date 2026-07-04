import 'package:untitled_poi/global/base/base_controller.dart';
import 'package:untitled_poi/global/sp/sp_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class ThemeController extends BaseController {
  static ThemeController get to => Get.find();

  bool get isDarkMode => SpManager.isDarkTheme;

  @override
  void onControllerInit() {
    Get.changeThemeMode(isDarkMode ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> toggleTheme() async {
    final newTheme = !isDarkMode;
    await SpManager.setDarkTheme(newTheme);
    Get.changeThemeMode(newTheme ? ThemeMode.dark : ThemeMode.light);
    update();
  }

  void applyLightTheme() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    update();
  }

  void applyDarkTheme() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    update();
  }
}
