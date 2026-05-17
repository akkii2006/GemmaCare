import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/common/common_widgets.dart';

class BloodGroupStep extends StatefulWidget {
  final VoidCallback onNext;
  final void Function(String) onChanged;

  const BloodGroupStep({super.key, required this.onNext, required this.onChanged});

  @override
  State<BloodGroupStep> createState() => _BloodGroupStepState();
}

class _BloodGroupStepState extends State<BloodGroupStep> {
  String? _selected;
  final List<String> _groups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', "Don't know"];

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
            child: const Icon(Icons.bloodtype_outlined, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 24),
          Text('Blood group', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Critical for emergency situations.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6))),
          const SizedBox(height: 32),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _groups.map((g) {
              final selected = _selected == g;
              return GestureDetector(
                onTap: () {
                  setState(() => _selected = g);
                  widget.onChanged(g);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: selected ? AppColors.primary : Colors.transparent),
                  ),
                  child: Text(g, style: theme.textTheme.titleSmall?.copyWith(color: selected ? Colors.white : null, fontWeight: FontWeight.w600)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 40),
          GemmaButton(label: 'Continue', onPressed: widget.onNext),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
