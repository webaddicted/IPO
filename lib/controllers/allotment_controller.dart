import 'package:get/get.dart';

import '../model/bean/allotment_model.dart';
import '../services/ipo_repository.dart';

/// Backs the allotment-status bottom sheet for a single IPO.
class AllotmentController extends GetxController {
  final IpoRepository repo;
  final String ipoId;
  final String companyName;
  final String? registrar;

  AllotmentController(this.repo, this.ipoId, this.companyName, this.registrar);

  final RxBool loading = false.obs;
  final RxString error = ''.obs;
  final Rxn<AllotmentResult> result = Rxn<AllotmentResult>();

  static final RegExp _panRegex = RegExp(r'^[A-Za-z]{5}[0-9]{4}[A-Za-z]$');

  String? validatePan(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'PAN is required';
    if (!_panRegex.hasMatch(v)) return 'Enter a valid PAN (e.g. ABCDE1234F)';
    return null;
  }

  Future<void> submit({required String pan, String? applicationNumber}) async {
    loading.value = true;
    error.value = '';
    result.value = null;
    try {
      result.value = await repo.checkAllotment(
        AllotmentRequest(
          ipoId: ipoId,
          pan: pan.trim().toUpperCase(),
          applicationNumber: applicationNumber?.trim(),
        ),
        registrarName: registrar,
        companyName: companyName,
      );
    } catch (e) {
      error.value = e is Exception ? e.toString().replaceFirst('ApiException: ', '') : '$e';
    } finally {
      loading.value = false;
    }
  }

  void reset() {
    result.value = null;
    error.value = '';
  }
}
