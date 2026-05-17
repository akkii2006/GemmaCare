import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/common/common_widgets.dart';

class PrivacyStep extends StatefulWidget {
  final VoidCallback onNext;
  final void Function(bool) onChanged;

  const PrivacyStep({super.key, required this.onNext, required this.onChanged});

  @override
  State<PrivacyStep> createState() => _PrivacyStepState();
}

class _PrivacyStepState extends State<PrivacyStep> {
  bool _privacyMode = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 24),
          Text('Privacy settings', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Choose how GemmaCare processes your data.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6))),
          const SizedBox(height: 32),
          _ModeCard(
            title: 'Smart mode',
            description: 'Uses the 4B on-device model for everyday tasks. Routes complex tasks like X-ray analysis to the 31B model on private compute.',
            icon: Icons.auto_awesome_rounded,
            selected: !_privacyMode,
            onTap: () { setState(() => _privacyMode = false); widget.onChanged(false); },
          ),
          const SizedBox(height: 12),
          _ModeCard(
            title: 'Privacy mode',
            description: 'Everything runs on the 4B model on your device. No data ever leaves your phone.',
            icon: Icons.shield_rounded,
            selected: _privacyMode,
            onTap: () { setState(() => _privacyMode = true); widget.onChanged(true); },
          ),
          const SizedBox(height: 16),
          Text('You can change this anytime in Settings.', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5))),
          const SizedBox(height: 32),
          GemmaButton(label: 'Continue', onPressed: widget.onNext),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModeCard({required this.title, required this.description, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.08) : theme.cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : Colors.transparent, width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary.withOpacity(0.15) : theme.colorScheme.onSurface.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: selected ? AppColors.primary : theme.colorScheme.onSurface.withOpacity(0.5), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: selected ? AppColors.primary : null)),
                  const SizedBox(height: 4),
                  Text(description, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
