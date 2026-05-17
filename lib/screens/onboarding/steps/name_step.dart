import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/common/common_widgets.dart';

class NameStep extends StatefulWidget {
  final VoidCallback onNext;
  final void Function(String) onNameChanged;

  const NameStep({super.key, required this.onNext, required this.onNameChanged});

  @override
  State<NameStep> createState() => _NameStepState();
}

class _NameStepState extends State<NameStep> {
  final _controller = TextEditingController();

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
            child: const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 24),
          Text("What's your name?", style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('This helps us personalize your experience.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6))),
          const SizedBox(height: 32),
          GemmaTextField(
            hint: 'Enter your name',
            controller: _controller,
            onChanged: widget.onNameChanged,
          ),
          const SizedBox(height: 40),
          GemmaButton(label: 'Continue', onPressed: widget.onNext),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
