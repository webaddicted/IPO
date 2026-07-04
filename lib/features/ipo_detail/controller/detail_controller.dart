import 'package:get/get.dart';
import 'package:untitled_poi/global/base/base_controller.dart';
import 'package:untitled_poi/features/ipo_detail/domain/ipo_detail_model.dart';
import 'package:untitled_poi/features/home/data/ipo_repository.dart';
import 'package:untitled_poi/global/sp/sp_manager.dart';

/// Loads and holds the full IPO detail aggregate for the detail screen.
class DetailController extends BaseController {
  final IpoRepository repo;
  final String ipoId;
  final String companyNameHint;

  DetailController(this.repo, this.ipoId, this.companyNameHint);

  final RxBool loading = true.obs;
  final RxString error = ''.obs;
  final Rxn<IpoDetailModel> detail = Rxn<IpoDetailModel>();
  final RxBool watched = false.obs;

  @override
  void onControllerInit() {
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
