import 'package:get/get.dart';

import 'package:untitled_poi/features/ipo_detail/controller/detail_controller.dart';
import 'package:untitled_poi/features/home/data/ipo_repository.dart';

/// Builds a DetailController from the route arguments {id, name}.
class DetailBinding extends Bindings {
  @override
  void dependencies() {
    final args = (Get.arguments as Map?) ?? const {};
    final id = args['id']?.toString() ?? '';
    final name = args['name']?.toString() ?? '';

    // lazyPut: one controller per route visit. Get.create would spawn a new
    // instance on every GetView rebuild (Get.find), leaving loading stuck true.
    if (Get.isRegistered<DetailController>()) {
      Get.delete<DetailController>();
    }
    Get.lazyPut<DetailController>(
      () => DetailController(Get.find<IpoRepository>(), id, name),
    );
  }
}
