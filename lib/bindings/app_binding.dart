import 'package:get/get.dart';

import '../controllers/home_controller.dart';
import '../services/ipo_repository.dart';

/// Registers app-wide singletons available from app start.
class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<IpoRepository>(IpoRepository(), permanent: true);
    Get.put<HomeController>(HomeController(Get.find<IpoRepository>()));
  }
}
