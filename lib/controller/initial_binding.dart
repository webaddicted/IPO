import 'package:get/get.dart';
import 'package:untitled_poi/features/home/controller/home_controller.dart';
import 'package:untitled_poi/features/home/data/ipo_repository.dart';

/// Registers app-wide singletons available from app start.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<IpoRepository>(IpoRepository(), permanent: true);
    Get.put<HomeController>(HomeController(Get.find<IpoRepository>()));
  }
}
