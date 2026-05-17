import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/common/common_widgets.dart';

class AllergiesStep extends StatefulWidget {
  final VoidCallback onNext;
  final void Function(List<String>) onChanged;

  const AllergiesStep({super.key, required this.onNext, required this.onChanged});

  @override
  State<AllergiesStep> createState() => _AllergiesStepState();
}

class _AllergiesStepState extends State<AllergiesStep> {
  final _controller = TextEditingController();
  final List<String> _allergies = [];

  void _add() {
    final text = _controller.text.trim();
    if (text.isNotEmpty && !_allergies.contains(text)) {
      setState(() => _allergies.add(text));
      _controller.clear();
      widget.onChanged(_allergies);
    }
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
            decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
            child: Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 28),
          ),
          const SizedBox(height: 24),
          Text('Known allergies', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Add any allergies you have. Skip if none.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6))),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(child: GemmaTextField(hint: 'e.g. Penicillin, Peanuts', controller: _controller)),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: _add,
                style: FilledButton.styleFrom(minimumSize: const Size(56, 56), padding: EdgeInsets.zero),
                child: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_allergies.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _allergies.map((a) => Chip(
                label: Text(a),
                deleteIcon: const Icon(Icons.close_rounded, size: 16),
                onDeleted: () {
                  setState(() => _allergies.remove(a));
                  widget.onChanged(_allergies);
                },
                backgroundColor: AppColors.warning.withOpacity(0.1),
                labelStyle: theme.textTheme.labelMedium?.copyWith(color: AppColors.warning),
                side: BorderSide.none,
              )).toList(),
            ),
          const SizedBox(height: 40),
          GemmaButton(label: 'Continue', onPressed: widget.onNext),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
