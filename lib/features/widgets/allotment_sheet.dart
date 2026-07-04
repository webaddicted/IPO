import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:untitled_poi/features/ipo_detail/controller/allotment_controller.dart';
import 'package:untitled_poi/features/ipo_detail/domain/allotment_model.dart';
import 'package:untitled_poi/features/home/data/ipo_repository.dart';
import 'package:untitled_poi/global/theme/app_colors.dart';
import 'package:untitled_poi/global/theme/text_style.dart';
import 'package:untitled_poi/global/utils/responsive.dart';
import 'package:untitled_poi/features/widgets/app_surface.dart';

/// Bottom sheet (mobile) or dialog (web) for checking IPO allotment status by PAN.
class AllotmentSheet extends StatefulWidget {
  final String ipoId;
  final String companyName;
  final String? registrar;

  const AllotmentSheet({
    super.key,
    required this.ipoId,
    required this.companyName,
    this.registrar,
  });

  /// Opens the sheet as a modal — dialog on wide screens, bottom sheet on mobile.
  static Future<void> show(
    BuildContext context, {
    required String ipoId,
    required String companyName,
    String? registrar,
  }) {
    final sheet = AllotmentSheet(
      ipoId: ipoId,
      companyName: companyName,
      registrar: registrar,
    );

    if (Responsive.isWide(context)) {
      return showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: sheet,
          ),
        ),
      );
    }

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => sheet,
    );
  }

  @override
  State<AllotmentSheet> createState() => _AllotmentSheetState();
}

class _AllotmentSheetState extends State<AllotmentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _panCtrl = TextEditingController();
  final _appCtrl = TextEditingController();
  late final AllotmentController _c;

  @override
  void initState() {
    super.initState();
    _c = Get.put(
      AllotmentController(
        Get.find<IpoRepository>(),
        widget.ipoId,
        widget.companyName,
        widget.registrar,
      ),
      tag: 'allotment-${widget.ipoId}',
    );
  }

  @override
  void dispose() {
    _panCtrl.dispose();
    _appCtrl.dispose();
    Get.delete<AllotmentController>(tag: 'allotment-${widget.ipoId}');
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.validate() ?? false) {
      _c.submit(pan: _panCtrl.text, applicationNumber: _appCtrl.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isDialog = Responsive.isWide(context);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: AppSurfaceCard(
        padding: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(24, isDialog ? 24 : 16, 24, 20),
              decoration: const BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isDialog)
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Check Allotment', style: AppTextStyle.display.copyWith(fontSize: 22)),
                            const SizedBox(height: 4),
                            Text(
                              widget.companyName,
                              style: AppTextStyle.body.copyWith(
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isDialog)
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded, color: Colors.white),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _panCtrl,
                          textCapitalization: TextCapitalization.characters,
                          maxLength: 10,
                          inputFormatters: [
                            UpperCaseFormatter(),
                            FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'PAN Number',
                            hintText: 'ABCDE1234F',
                            counterText: '',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          validator: _c.validatePan,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _appCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Application No. (optional)',
                            prefixIcon: Icon(Icons.numbers_rounded),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Obx(() => SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _c.loading.value ? null : _submit,
                          child: _c.loading.value
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Check Status'),
                        ),
                      )),
                  Obx(() {
                    if (_c.error.isNotEmpty) {
                      return _MessageBox(
                        icon: Icons.error_outline_rounded,
                        color: AppColors.loss,
                        text: _c.error.value,
                      );
                    }
                    final r = _c.result.value;
                    if (r == null) return const SizedBox.shrink();
                    return _ResultView(result: r);
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  final AllotmentResult result;
  const _ResultView({required this.result});

  @override
  Widget build(BuildContext context) {
    switch (result.outcome) {
      case AllotmentOutcome.allotted:
        return _MessageBox(
          icon: Icons.check_circle_rounded,
          color: AppColors.gain,
          text: 'Allotted${result.sharesAllotted != null ? ' ${result.sharesAllotted} shares' : ''}! 🎉',
        );
      case AllotmentOutcome.notAllotted:
        return _MessageBox(
          icon: Icons.cancel_outlined,
          color: AppColors.loss,
          text: 'Not allotted this time.',
        );
      case AllotmentOutcome.notFound:
        return _MessageBox(
          icon: Icons.search_off_rounded,
          color: AppColors.statusUpcoming,
          text: result.message ?? 'No record found for this PAN.',
        );
      case AllotmentOutcome.manualCheckRequired:
        return _ManualCheck(result: result);
      case AllotmentOutcome.error:
        return _MessageBox(
          icon: Icons.error_outline_rounded,
          color: AppColors.loss,
          text: result.message ?? 'Something went wrong.',
        );
    }
  }
}

class _ManualCheck extends StatelessWidget {
  final AllotmentResult result;
  const _ManualCheck({required this.result});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MessageBox(
          icon: Icons.open_in_new_rounded,
          color: AppColors.primary,
          text: result.message ?? 'Check on the registrar portal.',
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.launch_rounded),
            label: Text('Open ${result.registrar ?? 'registrar'} portal'),
            onPressed: () async {
              final url = result.manualCheckUrl;
              if (url == null) return;
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ),
      ],
    );
  }
}

class _MessageBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _MessageBox({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: AppTextStyle.body),
          ),
        ],
      ),
    );
  }
}

class UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
