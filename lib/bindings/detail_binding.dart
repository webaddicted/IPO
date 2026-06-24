import 'package:get/get.dart';

import '../controllers/detail_controller.dart';
import '../services/ipo_repository.dart';

/// Builds a DetailController from the route arguments {id, name}.
class DetailBinding extends Bindings {
  @override
  void dependencies() {
    final args = (Get.arguments as Map?) ?? const {};
    Get.create<DetailController>(() => DetailController(
          Get.find<IpoRepository>(),
          args['id']?.toString() ?? '',
          args['name']?.toString() ?? '',
        ));
  }
}
