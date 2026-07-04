import 'dart:async';
import 'package:get/get.dart';

import '../model/bean/ipo_model.dart';
import '../services/ipo_repository.dart';

/// Drives the home screen: bottom-nav (mainline / sme) × tab (current / listed).
class HomeController extends GetxController {
  final IpoRepository repo;
  HomeController(this.repo);

  // 0 = MainLine, 1 = SME  (index 2 'Offers' is a placeholder screen)
  final RxInt navIndex = 0.obs;
  // 0 = Current, 1 = Listed
  final RxInt tabIndex = 0.obs;

  final RxBool loading = true.obs;
  final RxString error = ''.obs;
  final RxList<IpoModel> ipos = <IpoModel>[].obs;

  StreamSubscription<List<IpoModel>>? _sub;

  IpoKind get kind => navIndex.value == 1 ? IpoKind.sme : IpoKind.mainline;
  bool get listed => tabIndex.value == 1;

  @override
  void onInit() {
    super.onInit();
    _subscribe();
  }

  void selectNav(int i) {
    if (i == navIndex.value) return;
    navIndex.value = i;
    if (i == 2) return; // Offers tab — no IPO list
    _subscribe();
  }

  void selectTab(int i) {
    if (i == tabIndex.value) return;
    tabIndex.value = i;
    _subscribe();
  }

  Future<void> refreshData() async {
    try {
      loading.value = true;
      ipos.value = await repo.fetchIpos(kind: kind, listed: listed);
      error.value = '';
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  void _subscribe() {
    _sub?.cancel();
    loading.value = true;
    error.value = '';
    ipos.clear();
    _sub = repo.watchIpos(kind: kind, listed: listed).listen(
      (data) {
        ipos.value = data;
        loading.value = false;
      },
      onError: (e) async {
        try {
          ipos.value = await repo.fetchIpos(kind: kind, listed: listed);
          error.value = '';
        } catch (fallbackError) {
          error.value = fallbackError.toString();
        } finally {
          loading.value = false;
        }
      },
    );
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
