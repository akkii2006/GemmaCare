import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/common/common_widgets.dart';

class AgeGenderStep extends StatefulWidget {
  final VoidCallback onNext;
  final void Function(int age, String gender) onChanged;

  const AgeGenderStep({super.key, required this.onNext, required this.onChanged});

  @override
  State<AgeGenderStep> createState() => _AgeGenderStepState();
}

class _AgeGenderStepState extends State<AgeGenderStep> {
  final _ageController = TextEditingController();
  String? _selectedGender;
  final List<String> _genders = ['Male', 'Female', 'Other', 'Prefer not to say'];

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
            child: const Icon(Icons.cake_outlined, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 24),
          Text('Age and gender', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Helps us give you relevant health information.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6))),
          const SizedBox(height: 32),
          GemmaTextField(
            hint: 'Your age',
            controller: _ageController,
            keyboardType: TextInputType.number,
            onChanged: (v) => widget.onChanged(int.tryParse(v) ?? 0, _selectedGender ?? ''),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            children: _genders.map((g) {
              final selected = _selectedGender == g;
              return ChoiceChip(
                label: Text(g),
                selected: selected,
                onSelected: (_) {
                  setState(() => _selectedGender = g);
                  widget.onChanged(int.tryParse(_ageController.text) ?? 0, g);
                },
                selectedColor: AppColors.primary.withOpacity(0.15),
                labelStyle: theme.textTheme.labelMedium?.copyWith(
                  color: selected ? AppColors.primary : null,
                  fontWeight: selected ? FontWeight.w700 : null,
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
