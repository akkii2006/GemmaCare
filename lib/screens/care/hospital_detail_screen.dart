import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/hospital_model.dart';
import '../../services/call_service.dart';

class HospitalDetailScreen extends StatelessWidget {
  const HospitalDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hospital = GoRouterState.of(context).extra as Hospital?;
    final name = hospital?.name ?? 'Apollo Hospitals';
    final type = hospital?.type ?? 'Multi-specialty Private Hospital';
    final address = hospital?.address ?? 'Jubilee Hills, Hyderabad';
    final rating = hospital?.rating ?? 4.6;
    final phone = hospital?.phone ?? '';
    final ambulanceNumber = hospital?.ambulanceNumber ?? '';
    final hasAmbulance = hospital?.hasAmbulance ?? true;
    final specialties = hospital?.specialties ?? ['Cardiology', 'Neurology', 'Oncology', 'Orthopedics'];

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
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                      child: const Icon(Icons.local_hospital_rounded, color: AppColors.primary, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                          Text(type, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                          if (rating > 0)
                            Row(children: [
                              const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFFA000)),
                              const SizedBox(width: 4),
                              Text('$rating', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                            ]),
                        ],
                      ),
                    ),
                  ],
                ),
                if (hasAmbulance && ambulanceNumber.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.emergency_rounded, color: AppColors.primary, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Ambulance', style: theme.textTheme.labelMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                              Text(ambulanceNumber, style: theme.textTheme.titleMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: () => CallService().call(ambulanceNumber),
                          icon: const Icon(Icons.phone_rounded, size: 16),
                          label: const Text('Call'),
                          style: FilledButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size(80, 40), padding: const EdgeInsets.symmetric(horizontal: 14)),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                if (address.isNotEmpty) _InfoTile(icon: Icons.location_on_outlined, text: address),
                if (phone.isNotEmpty) _InfoTile(icon: Icons.phone_outlined, text: phone),
                if (specialties.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('Specialties', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: specialties.map((s) => Chip(label: Text(s))).toList()),
                ],
                const SizedBox(height: 80),
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
              Expanded(child: OutlinedButton.icon(onPressed: phone.isNotEmpty ? () => CallService().call(phone) : null, icon: const Icon(Icons.phone_outlined), label: const Text('Call'))),
              const SizedBox(width: 12),
              Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.directions_rounded), label: const Text('Directions'))),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoTile({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurface.withOpacity(0.5)),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.75)))),
        ],
      ),
    );
  }
}
