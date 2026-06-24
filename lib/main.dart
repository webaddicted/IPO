import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'bindings/app_binding.dart';
import 'bindings/detail_binding.dart';
import 'constants/routers_const.dart';
import 'constants/string_const.dart';
import 'screens/home_screen.dart';
import 'screens/ipo_detail_screen.dart';
import 'services/supabase_service.dart';
import 'sp/sp_helper.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SpHelper.init();
  await SupabaseService.init();
  runApp(const IpoTrackerApp());
}

class IpoTrackerApp extends StatelessWidget {
  const IpoTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: StringConst.appName,
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
      initialBinding: AppBinding(),
      initialRoute: Routes.home,
      getPages: [
        GetPage(name: Routes.home, page: () => const HomeScreen()),
        GetPage(
          name: Routes.detail,
          page: () => const IpoDetailScreen(),
          binding: DetailBinding(),
        ),

      ],
    );
  }
}
