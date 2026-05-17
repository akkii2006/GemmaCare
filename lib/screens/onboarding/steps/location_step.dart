import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/location_service.dart';
import '../../../widgets/common/common_widgets.dart';

class LocationStep extends StatefulWidget {
  final VoidCallback onNext;
  final void Function(double lat, double lng) onLocationObtained;

  const LocationStep({super.key, required this.onNext, required this.onLocationObtained});

  @override
  State<LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends State<LocationStep> {
  final LocationService _locationService = LocationService();
  bool _granted = false;
  bool _loading = false;

  Future<void> _requestLocation() async {
    setState(() => _loading = true);
    final pos = await _locationService.getCurrentPosition();
    if (pos != null) {
      widget.onLocationObtained(pos.latitude, pos.longitude);
      setState(() { _granted = true; _loading = false; });
    } else {
      setState(() => _loading = false);
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
            decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
            child: Icon(Icons.location_on_outlined, color: AppColors.success, size: 28),
          ),
          const SizedBox(height: 24),
          Text('Your location', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Used to find doctors, hospitals, and pharmacies near you. Never shared with anyone.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6))),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                const Icon(Icons.shield_outlined, size: 40, color: AppColors.success),
                const SizedBox(height: 12),
                Text('Your location stays on your device', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700), textAlign: TextAlign.center),
                const SizedBox(height: 6),
                Text('GemmaCare never uploads your location to any server.',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)), textAlign: TextAlign.center),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (!_granted)
            GemmaButton(label: 'Allow Location Access', icon: Icons.location_on_rounded, loading: _loading, onPressed: _requestLocation)
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.success),
                const SizedBox(width: 12),
                Text('Location access granted', style: theme.textTheme.titleSmall?.copyWith(color: AppColors.success, fontWeight: FontWeight.w600)),
              ]),
            ),
          const SizedBox(height: 12),
          GemmaButton(label: 'Continue', onPressed: widget.onNext),
          const SizedBox(height: 12),
          GemmaButton(label: 'Skip for now', outlined: true, onPressed: widget.onNext),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
