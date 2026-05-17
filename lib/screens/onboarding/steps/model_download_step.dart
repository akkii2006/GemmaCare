import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/model_download_provider.dart';
import '../../../widgets/common/common_widgets.dart';

class ModelDownloadStep extends StatelessWidget {
  final VoidCallback onNext;

  const ModelDownloadStep({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<ModelDownloadProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.download_rounded, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 24),
          Text('Download AI model', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('GemmaCare needs to download the Gemma 4 model to your device. This is a one-time download of about 3.5GB. Use Wi-Fi for best results.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6))),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.memory_rounded, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Gemma 4 E4B', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                          Text('3.5GB - Runs entirely on your device', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                        ],
                      ),
                    ),
                  ],
                ),
                if (provider.isDownloading) ...[
                  const SizedBox(height: 20),
                  LinearProgressIndicator(
                    value: provider.progress,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    borderRadius: BorderRadius.circular(4),
                    minHeight: 6,
                  ),
                  const SizedBox(height: 8),
                  Text('${(provider.progress * 100).toStringAsFixed(0)}% downloaded',
                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                ],
                if (provider.isDownloaded) ...[
                  const SizedBox(height: 16),
                  Row(children: [
                    const Icon(Icons.check_circle_rounded, color: AppColors.success),
                    const SizedBox(width: 8),
                    Text('Model downloaded', style: theme.textTheme.titleSmall?.copyWith(color: AppColors.success, fontWeight: FontWeight.w600)),
                  ]),
                ],
                if (provider.error != null) ...[
                  const SizedBox(height: 16),
                  Text('Download failed. Please try again.', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.error)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),
          if (!provider.isDownloaded && !provider.isDownloading)
            GemmaButton(label: 'Download Model', icon: Icons.download_rounded, onPressed: () => context.read<ModelDownloadProvider>().startDownload()),
          if (provider.isDownloading)
            GemmaButton(label: 'Downloading...', loading: true, onPressed: () {}),
          if (provider.isDownloaded) ...[
            GemmaButton(label: 'Get Started', icon: Icons.arrow_forward_rounded, onPressed: onNext),
          ],
          const SizedBox(height: 12),
          if (!provider.isDownloaded && !provider.isDownloading)
            GemmaButton(
              label: 'Skip for now',
              outlined: true,
              onPressed: onNext,
            ),
          const SizedBox(height: 8),
          if (!provider.isDownloaded && !provider.isDownloading)
            Text('You can download later from Settings. Some features will be limited without the model.',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5)), textAlign: TextAlign.center),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
