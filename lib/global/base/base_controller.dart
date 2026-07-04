import 'package:flutter/material.dart';
import 'package:get/get.dart';

abstract class BaseController extends GetxController {
  final RxBool _isLoading = false.obs;
  final RxBool _isError = false.obs;
  final RxString _errorMessage = ''.obs;
  final Rx<Exception?> _exception = Rx<Exception?>(null);

  bool get isLoading => _isLoading.value;
  bool get isError => _isError.value;
  String get errorMessage => _errorMessage.value;
  Exception? get exception => _exception.value;

  @protected
  void onControllerInit() {}

  @protected
  void onControllerReady() {}

  @protected
  void onControllerClose() {}

  @override
  void onInit() {
    super.onInit();
    onControllerInit();
  }

  @override
  void onReady() {
    super.onReady();
    onControllerReady();
  }

  @override
  void onClose() {
    onControllerClose();
    super.onClose();
  }

  void showLoading() {
    _isLoading.value = true;
    _isError.value = false;
    _errorMessage.value = '';
  }

  void hideLoading() {
    _isLoading.value = false;
  }

  void setError(String message, [Exception? e]) {
    _isError.value = true;
    _errorMessage.value = message;
    _exception.value = e;
    _isLoading.value = false;
  }

  void clearError() {
    _isError.value = false;
    _errorMessage.value = '';
    _exception.value = null;
  }

  Future<T?> executeWithLoading<T>({
    required Future<T> Function() action,
    String? errorMessage,
    bool showError = true,
  }) async {
    try {
      showLoading();
      final result = await action();
      hideLoading();
      return result;
    } catch (e) {
      if (showError) {
        setError(
          errorMessage ?? e.toString(),
          e is Exception ? e : Exception(e.toString()),
        );
      } else {
        hideLoading();
      }
      return null;
    }
  }

  Future<T?>? toNamed<T>(String routeName, {dynamic arguments}) {
    return Get.toNamed<T>(routeName, arguments: arguments);
  }

  void back<T>([T? result]) {
    Get.back<T>(result: result);
  }

  T? getArguments<T>() => Get.arguments as T?;
}
