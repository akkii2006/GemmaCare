import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/scan_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common/common_widgets.dart';

class ScanScreen extends StatelessWidget {
  final bool embedded;
  const ScanScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<ScanProvider>();

    final body = CustomScrollView(
      slivers: [
        SliverAppBar.large(
          title: const Text('Scan & Analyze'),
          backgroundColor: theme.scaffoldBackgroundColor,
          foregroundColor: theme.colorScheme.onSurface,
          automaticallyImplyLeading: !embedded,
          elevation: 0,
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Text(
                'Document type',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              _DocumentTypeSelector(
                selected: provider.documentType,
                onChanged: (type) =>
                    context.read<ScanProvider>().setDocumentType(type),
              ),
              const SizedBox(height: 24),
              _UploadArea(
                selectedImage: provider.selectedImage,
                isPdf: provider.isPdf,
                onCameraTap: () => _pickImage(context, camera: true),
                onGalleryTap: () => _pickImage(context, camera: false),
                onPdfTap: () => _pickPdf(context),
                onClear: () => context.read<ScanProvider>().clearSelection(),
              ),
              const SizedBox(height: 24),
              if (provider.selectedImage != null &&
                  provider.result == null &&
                  !provider.isAnalyzing &&
                  !provider.isStreaming &&
                  !provider.isConvertingPdf)
                GemmaButton(
                  label: 'Analyze Document',
                  icon: Icons.auto_awesome_rounded,
                  onPressed: () => _analyze(context),
                ),
              if (provider.history.isNotEmpty) ...[
                const SizedBox(height: 28),
                Row(
                  children: [
                    Text(
                      'Recent scans',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    Text(
                      'Swipe to delete',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ...provider.history.map((scan) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Dismissible(
                    key: Key(scan.id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) =>
                        context.read<ScanProvider>().deleteScan(scan.id),
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.delete_outline_rounded,
                          color: Colors.white),
                    ),
                    child: Material(
                      color: theme.cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          context.read<ScanProvider>().loadResult(scan);
                          context.push(AppRouter.scanResult);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              if (scan.imagePath.isNotEmpty &&
                                  File(scan.imagePath).existsSync())
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(scan.imagePath),
                                    width: 52,
                                    height: 52,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              else
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _docIcon(scan.documentType),
                                    color: AppColors.primary,
                                    size: 22,
                                  ),
                                ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      scan.documentType,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                          fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${scan.scannedAt.day}/${scan.scannedAt.month}/${scan.scannedAt.year}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.5),
                                      ),
                                    ),
                                    if (scan.followUpMessages.isNotEmpty)
                                      Text(
                                        '${scan.followUpMessages.length ~/ 2} follow-up questions',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                          color: AppColors.primary
                                              .withOpacity(0.7),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.3),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                )),
              ] else
                Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.document_scanner_outlined,
                          size: 48,
                          color: theme.colorScheme.onSurface.withOpacity(0.2),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No scans yet',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Upload a medical document to get started',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 80),
            ]),
          ),
        ),
      ],
    );

    if (embedded) return body;
    return Scaffold(floatingActionButton: const EmergencyFab(), body: body);
  }

  Future<void> _pickImage(BuildContext context,
      {required bool camera}) async {
    final provider = context.read<ScanProvider>();
    if (camera) {
      await provider.pickFromCamera();
    } else {
      await provider.pickFromGallery();
    }
  }

  Future<void> _pickPdf(BuildContext context) async {
    await context.read<ScanProvider>().pickPdf();
  }

  Future<void> _analyze(BuildContext context) async {
    final provider = context.read<ScanProvider>();
    final profile = context.read<UserProvider>().profile;
    final privacyMode = context.read<SettingsProvider>().privacyMode;

    AnalysisMode mode = AnalysisMode.local;

    // Show model picker for PDFs unless privacy mode is on
    if (!privacyMode) {
      final chosen = await _showModelPicker(context, isPdf: provider.isPdf);
      if (chosen == null) return; // user dismissed
      mode = chosen;
    }

    context.push(AppRouter.scanResult);
    await provider.analyze(profile: profile, mode: mode);
  }

  Future<AnalysisMode?> _showModelPicker(BuildContext context, {required bool isPdf}) {
    final theme = Theme.of(context);
    final title = isPdf
        ? 'How would you like to analyze this PDF?'
        : 'How would you like to analyze this image?';
    final localSubtitle = isPdf
        ? 'Slower but fully private - Gemma 4 on your phone'
        : 'Fully private - Gemma 4 vision on your phone';
    final remoteSubtitle = isPdf
        ? 'Gemma 4 31B - faster for long PDFs'
        : 'Gemma 4 31B - more detailed analysis';

    return showModalBottomSheet<AnalysisMode>(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Choose how GemmaCare reads your document.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 20),
            _ModelOptionTile(
              icon: Icons.memory_rounded,
              iconColor: AppColors.primary,
              title: 'On-device',
              subtitle: localSubtitle,
              onTap: () => Navigator.of(ctx).pop(AnalysisMode.local),
            ),
            const SizedBox(height: 12),
            _ModelOptionTile(
              icon: Icons.cloud_rounded,
              iconColor: Colors.blue,
              title: 'Cloud',
              subtitle: remoteSubtitle,
              onTap: () => Navigator.of(ctx).pop(AnalysisMode.remote),
            ),
          ],
        ),
      ),
    );
  }

  IconData _docIcon(String type) {
    switch (type) {
      case 'Prescription':      return Icons.medication_outlined;
      case 'X-Ray':             return Icons.image_search_rounded;
      case 'Blood Report':      return Icons.science_outlined;
      case 'Discharge Summary': return Icons.description_outlined;
      default:                  return Icons.receipt_long_rounded;
    }
  }
}

class _ModelOptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModelOptionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.cardTheme.color,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurface.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentTypeSelector extends StatelessWidget {
  final String selected;
  final void Function(String) onChanged;

  const _DocumentTypeSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final types = [
      ('prescription',      'Prescription', Icons.medication_outlined),
      ('xray',              'X-Ray',        Icons.image_search_rounded),
      ('blood_report',      'Blood Report', Icons.science_outlined),
      ('discharge_summary', 'Discharge',    Icons.description_outlined),
    ];

    return Row(
      children: types.map((t) {
        final isSelected = selected == t.$1;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => onChanged(t.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : theme.colorScheme.onSurface.withOpacity(0.08),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(t.$3,
                        size: 20,
                        color: isSelected
                            ? Colors.white
                            : theme.colorScheme.onSurface.withOpacity(0.5)),
                    const SizedBox(height: 4),
                    Text(
                      t.$2,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isSelected
                            ? Colors.white
                            : theme.colorScheme.onSurface.withOpacity(0.6),
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _UploadArea extends StatelessWidget {
  final File? selectedImage;
  final bool isPdf;
  final VoidCallback onCameraTap;
  final VoidCallback onGalleryTap;
  final VoidCallback onPdfTap;
  final VoidCallback onClear;

  const _UploadArea({
    required this.selectedImage,
    required this.isPdf,
    required this.onCameraTap,
    required this.onGalleryTap,
    required this.onPdfTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (selectedImage != null && isPdf) {
      return Stack(
        children: [
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.picture_as_pdf_rounded,
                      color: AppColors.primary, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedImage!.path.split('/').last,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'PDF ready to analyze',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.primary.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onClear,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      );
    }

    if (selectedImage != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              selectedImage!,
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onClear,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 28),
          Icon(Icons.upload_file_rounded,
              size: 40, color: AppColors.primary.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text(
            'Upload a document',
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Images or PDF supported',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _UploadOption(
                icon: Icons.camera_alt_outlined,
                label: 'Camera',
                onTap: onCameraTap,
              ),
              const SizedBox(width: 12),
              _UploadOption(
                icon: Icons.photo_library_outlined,
                label: 'Gallery',
                onTap: onGalleryTap,
              ),
              const SizedBox(width: 12),
              _UploadOption(
                icon: Icons.picture_as_pdf_rounded,
                label: 'PDF',
                onTap: onPdfTap,
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _UploadOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _UploadOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}