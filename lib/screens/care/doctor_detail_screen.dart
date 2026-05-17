import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../data/models/doctor_model.dart';
import '../../services/call_service.dart';

class DoctorDetailScreen extends StatelessWidget {
  const DoctorDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final doctor = GoRouterState.of(context).extra as Doctor?;
    final name = doctor?.name ?? 'Dr. Arjun Mehta';
    final specialty = doctor?.specialty ?? 'General Physician';
    final hospital = doctor?.hospital ?? 'Apollo Hospitals, Hyderabad';
    final rating = doctor?.rating ?? 4.8;
    final reviewCount = doctor?.reviewCount ?? 312;
    final phone = doctor?.phone ?? '';
    final peopleSay = doctor?.peopleSay ?? '';
    final fee = doctor?.consultationFee ?? 600;
    final appointmentProcess = doctor?.appointmentProcess ?? 'Available on Practo and walk-in on weekdays 10AM-1PM.';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text(name),
            backgroundColor: theme.scaffoldBackgroundColor,
            foregroundColor: theme.colorScheme.onSurface,
            elevation: 0,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text(name.isNotEmpty ? name[0] : 'D',
                          style: theme.textTheme.headlineSmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                          Text(specialty, style: theme.textTheme.titleSmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                          Row(children: [
                            const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFFA000)),
                            const SizedBox(width: 4),
                            Text('$rating', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                            Text(' ($reviewCount reviews)', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5))),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _InfoRow(icon: Icons.local_hospital_outlined, text: hospital),
                const SizedBox(height: 8),
                _InfoRow(icon: Icons.currency_rupee_rounded, text: 'Consultation: Rs. $fee'),
                const SizedBox(height: 24),
                _Section(title: 'How to book', child: Text(appointmentProcess,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.8), height: 1.6))),
                if (peopleSay.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _Section(
                    title: 'What people say',
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(14)),
                      child: Text('"$peopleSay"',
                          style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic, color: theme.colorScheme.onSurface.withOpacity(0.75), height: 1.6)),
                    ),
                  ),
                ],
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: phone.isNotEmpty ? () => CallService().call(phone) : null,
                  icon: const Icon(Icons.phone_outlined),
                  label: const Text('Call'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: () => context.push(AppRouter.newAppointment, extra: doctor),
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: const Text('Book Appointment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurface.withOpacity(0.5)),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)))),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}
