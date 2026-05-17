import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/common/common_widgets.dart';

class ConditionsStep extends StatefulWidget {
  final VoidCallback onNext;
  final void Function(List<String>) onChanged;

  const ConditionsStep({super.key, required this.onNext, required this.onChanged});

  @override
  State<ConditionsStep> createState() => _ConditionsStepState();
}

class _ConditionsStepState extends State<ConditionsStep> {
  final _controller = TextEditingController();
  final List<String> _conditions = [];
  final List<String> _common = ['Diabetes', 'Hypertension', 'Asthma', 'Heart disease', 'Thyroid', 'Arthritis'];

  void _toggle(String c) {
    setState(() => _conditions.contains(c) ? _conditions.remove(c) : _conditions.add(c));
    widget.onChanged(_conditions);
  }

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
            child: const Icon(Icons.medical_information_outlined, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 24),
          Text('Existing conditions', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Select or type your existing medical conditions.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6))),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _common.map((c) {
              final selected = _conditions.contains(c);
              return FilterChip(
                label: Text(c),
                selected: selected,
                onSelected: (_) => _toggle(c),
                selectedColor: AppColors.primary.withOpacity(0.15),
                labelStyle: theme.textTheme.labelMedium?.copyWith(color: selected ? AppColors.primary : null, fontWeight: selected ? FontWeight.w700 : null),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: GemmaTextField(hint: 'Other condition', controller: _controller)),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: () {
                  final text = _controller.text.trim();
                  if (text.isNotEmpty) { _toggle(text); _controller.clear(); }
                },
                style: FilledButton.styleFrom(minimumSize: const Size(56, 56), padding: EdgeInsets.zero),
                child: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: 40),
          GemmaButton(label: 'Continue', onPressed: widget.onNext),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
