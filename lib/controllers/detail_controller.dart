import 'package:get/get.dart';

import '../model/bean/ipo_detail_model.dart';
import '../services/ipo_repository.dart';
import '../sp/sp_manager.dart';

/// Loads and holds the full IPO detail aggregate for the detail screen.
class DetailController extends GetxController {
  final IpoRepository repo;
  final String ipoId;
  final String companyNameHint;

  DetailController(this.repo, this.ipoId, this.companyNameHint);

  final RxBool loading = true.obs;
  final RxString error = ''.obs;
  final Rxn<IpoDetailModel> detail = Rxn<IpoDetailModel>();
  final RxBool watched = false.obs;

  @override
  void onInit() {
    super.onInit();
    watched.value = SpManager.isWatched(ipoId);
    load();
  }

  Future<void> load() async {
    if (ipoId.isEmpty) {
      error.value = 'Missing IPO id';
      loading.value = false;
      return;
    }
    try {
      loading.value = true;
      error.value = '';
      detail.value = await repo.fetchDetail(ipoId);
    } catch (e) {
      error.value = e.toString();
      detail.value = null;
    } finally {
      loading.value = false;
    }
  }

  Future<void> toggleWatch() async {
    await SpManager.toggleWatch(ipoId);
    watched.value = SpManager.isWatched(ipoId);
  }
}
