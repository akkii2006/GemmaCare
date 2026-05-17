import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/user_provider.dart';
import '../../data/models/appointment_model.dart';

class NewAppointmentScreen extends StatefulWidget {
  const NewAppointmentScreen({super.key});

  @override
  State<NewAppointmentScreen> createState() => _NewAppointmentScreenState();
}

class _NewAppointmentScreenState extends State<NewAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _doctorCtrl = TextEditingController();
  final _specialtyCtrl = TextEditingController();
  final _hospitalCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);

  bool _isSubmitting = false;
  String _prepText = '';
  String _questionsText = '';
  String _phase = ''; // 'prep' | 'questions' | 'done'

  final _specialties = [
    'General Physician', 'Cardiologist', 'Neurologist', 'Orthopedic',
    'Dermatologist', 'Gynecologist', 'Pediatrician', 'Psychiatrist',
    'Ophthalmologist', 'ENT Specialist', 'Diabetologist', 'Oncologist',
    'Urologist', 'Gastroenterologist', 'Pulmonologist', 'Other',
  ];

  @override
  void dispose() {
    _doctorCtrl.dispose();
    _specialtyCtrl.dispose();
    _hospitalCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context, initialTime: _selectedTime);
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _prepText = '';
      _questionsText = '';
      _phase = 'prep';
    });

    final dt = DateTime(
      _selectedDate.year, _selectedDate.month, _selectedDate.day,
      _selectedTime.hour, _selectedTime.minute,
    );

    final appointment = Appointment(
      doctorName: _doctorCtrl.text.trim(),
      specialty: _specialtyCtrl.text.trim(),
      hospital: _hospitalCtrl.text.trim(),
      dateTime: dt,
      notes: _notesCtrl.text.trim(),
      isUpcoming: true,
    );

    final profile = context.read<UserProvider>().profile;

    await context.read<AppointmentProvider>().addAndPrepare(
      appointment: appointment,
      profile: profile,
      onPrepToken: (t) => setState(() => _prepText += t),
      onQuestionsToken: (t) {
        setState(() {
          _phase = 'questions';
          _questionsText += t;
        });
      },
    );

    setState(() {
      _isSubmitting = false;
      _phase = 'done';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Appointment'),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Doctor name
              _SectionLabel('Doctor'),
              TextFormField(
                controller: _doctorCtrl,
                decoration: _inputDecoration('Dr. Name', Icons.person_outline_rounded),
                validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Specialty
              _SectionLabel('Specialty'),
              DropdownButtonFormField<String>(
                value: _specialtyCtrl.text.isEmpty ? null : _specialtyCtrl.text,
                decoration: _inputDecoration('Select specialty', Icons.medical_services_outlined),
                items: _specialties.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => _specialtyCtrl.text = v ?? '',
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Hospital
              _SectionLabel('Hospital / Clinic'),
              TextFormField(
                controller: _hospitalCtrl,
                decoration: _inputDecoration('Hospital name', Icons.local_hospital_outlined),
                validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Date & Time
              _SectionLabel('Date & Time'),
              Row(
                children: [
                  Expanded(
                    child: _PickerTile(
                      icon: Icons.calendar_today_rounded,
                      label: '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      onTap: _pickDate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PickerTile(
                      icon: Icons.access_time_rounded,
                      label: _selectedTime.format(context),
                      onTap: _pickTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Notes
              _SectionLabel('Notes (optional)'),
              TextFormField(
                controller: _notesCtrl,
                decoration: _inputDecoration('Symptoms, concerns, questions...', Icons.notes_rounded),
                maxLines: 3,
              ),
              const SizedBox(height: 28),

              // Submit button
              if (!_isSubmitting && _phase != 'done')
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: const Text('Add & Prepare with AI'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),

              // AI Generation progress
              if (_isSubmitting || _phase == 'done') ...[
                // Prep checklist
                _AiSection(
                  title: '📋 Preparation Checklist',
                  subtitle: 'What to do before your appointment',
                  content: _prepText,
                  isLoading: _isSubmitting && _phase == 'prep',
                  color: AppColors.primary,
                ),
                const SizedBox(height: 16),

                // Questions to ask
                _AiSection(
                  title: '❓ Questions to Ask',
                  subtitle: 'Personalized for your health profile',
                  content: _questionsText,
                  isLoading: _isSubmitting && _phase == 'questions',
                  color: const Color(0xFF7B61FF),
                ),

                if (_phase == 'done') ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Done'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        backgroundColor: AppColors.success,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon, size: 20),
    filled: true,
    fillColor: Theme.of(context).cardTheme.color,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text,
        style: Theme.of(context).textTheme.titleSmall
            ?.copyWith(fontWeight: FontWeight.w600)),
  );
}

class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18,
                color: theme.colorScheme.onSurface.withOpacity(0.5)),
            const SizedBox(width: 8),
            Text(label, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _AiSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final String content;
  final bool isLoading;
  final Color color;

  const _AiSection({
    required this.title,
    required this.subtitle,
    required this.content,
    required this.isLoading,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    Text(subtitle,
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5))),
                  ],
                ),
              ),
              if (isLoading)
                SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: color)),
            ],
          ),
          if (content.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(content,
                style: theme.textTheme.bodySmall?.copyWith(height: 1.6)),
          ] else if (isLoading)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text('Generating...',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.4))),
            ),
        ],
      ),
    );
  }
}
