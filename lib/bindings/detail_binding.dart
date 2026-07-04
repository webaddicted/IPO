import 'package:get/get.dart';

import '../controllers/detail_controller.dart';
import '../services/ipo_repository.dart';

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
