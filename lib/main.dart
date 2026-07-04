import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled_poi/controller/initial_binding.dart';
import 'package:untitled_poi/controller/routes.dart';
import 'package:untitled_poi/controller/theme_controller.dart';
import 'package:untitled_poi/global/constant/app_constant.dart';
import 'package:untitled_poi/global/constant/routers_const.dart';
import 'package:untitled_poi/global/services/supabase_service.dart';
import 'package:untitled_poi/global/sp/sp_helper.dart';
import 'package:untitled_poi/global/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSDK();
  runApp(const App());
}

Future<void> initSDK() async {
  await SpHelper.init();
  await SupabaseService.init();
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      init: ThemeController(),
      builder: (controller) => GetMaterialApp(
        title: AppConstant.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        scrollBehavior: const MaterialScrollBehavior().copyWith(
          physics: const BouncingScrollPhysics(),
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
            PointerDeviceKind.stylus,
          },
        ),
        initialBinding: InitialBinding(),
        initialRoute: RoutersConst.initialRoute,
        getPages: routes(),
      ),
    );
  }
}
