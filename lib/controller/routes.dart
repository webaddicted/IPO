import 'package:get/get.dart';
import 'package:untitled_poi/features/home/presentation/home_screen.dart';
import 'package:untitled_poi/features/ipo_detail/presentation/detail_binding.dart';
import 'package:untitled_poi/features/ipo_detail/presentation/ipo_detail_screen.dart';
import 'package:untitled_poi/global/constant/routers_const.dart';

List<GetPage<dynamic>> routes() {
  return [
    GetPage(name: RoutersConst.home, page: () => const HomeScreen()),
    GetPage(
      name: RoutersConst.detail,
      page: () => const IpoDetailScreen(),
      binding: DetailBinding(),
    ),
  ];
}
