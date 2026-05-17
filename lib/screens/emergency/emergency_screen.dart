import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../providers/emergency_provider.dart';
import '../../providers/user_provider.dart';

class EmergencyScreen extends StatefulWidget {
  final bool embedded;
  const EmergencyScreen({super.key, this.embedded = false});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAmbulances());
  }

  Future<void> _loadAmbulances({bool forceRefresh = false}) async {
    final profile = context.read<UserProvider>().profile;
    final lat = profile.latitude ?? 0.0;
    final lng = profile.longitude ?? 0.0;
    if (lat == 0.0 && lng == 0.0) return;
    final city = await _extractCityFromCoords(lat, lng);
    print('[EMERGENCY] City: $city');
    if (!mounted) return;
    await context.read<EmergencyProvider>().loadAmbulances(
      lat: lat, lng: lng, city: city, forceRefresh: forceRefresh,
    );
  }

  Future<String> _extractCityFromCoords(double lat, double lng) async {
    try {
      final uri = Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json'
          '?latlng=$lat,$lng&key=${AppConstants.googleMapsApiKey}');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final components =
            (data['results']?[0]?['address_components'] as List?) ?? [];
        for (final c in components) {
          final types = List<String>.from(c['types'] ?? []);
          if (types.contains('locality')) return c['long_name'] as String;
        }
      }
    } catch (_) {}
    return 'your city';
  }

  Widget _loadingCard(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }

  Widget _emptyCard(String message, {VoidCallback? onRetry}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded,
              color: theme.colorScheme.onSurface.withOpacity(0.3), size: 32),
          const SizedBox(height: 8),
          Text(message,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5))),
          if (onRetry != null) ...[
            const SizedBox(height: 8),
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final emergency = context.watch<EmergencyProvider>();

    final body = CustomScrollView(
      slivers: [
        SliverAppBar(
          title: const Text('Emergency'),
          backgroundColor: AppColors.error,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: !widget.embedded,
          elevation: 0,
          expandedHeight: 180,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              onPressed: () => _loadAmbulances(forceRefresh: true),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              color: AppColors.error,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 48),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: FilledButton.icon(
                      onPressed: () => launchUrl(Uri.parse('tel:112')),
                      icon: const Icon(Icons.phone_rounded, size: 22),
                      label: const Text('Call 112 — Emergency',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800)),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.error,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
          sliver: SliverList(
            delegate: SliverChildListDelegate([

              // Government ambulance
              Text('Government Ambulance',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              ..._ambulanceNumbers.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _EmergencyNumberCard(
                  title: a['title']!,
                  number: a['number']!,
                  subtitle: a['subtitle']!,
                  color: AppColors.error,
                ),
              )),

              const SizedBox(height: 24),

              // Major hospital ambulances
              Row(
                children: [
                  Expanded(
                    child: Text('Major Hospital Ambulances',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  if (emergency.isLoadingMajor)
                    const SizedBox(width: 14, height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.error)),
                ],
              ),
              const SizedBox(height: 4),
              Text('Top hospitals in your city · found by AI',
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.4))),
              const SizedBox(height: 12),

              if (emergency.isLoadingMajor &&
                  emergency.majorHospitalAmbulances.isEmpty)
                _loadingCard('Finding top hospitals in your city...')
              else if (emergency.majorHospitalAmbulances.isEmpty &&
                  !emergency.isLoadingMajor)
                _emptyCard('Could not find major hospitals',
                    onRetry: () => _loadAmbulances(forceRefresh: true))
              else
                ...emergency.majorHospitalAmbulances.map((a) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _EmergencyNumberCard(
                        title: a.name,
                        number: a.phone,
                        subtitle: a.phone.isEmpty
                            ? 'Tap to search online'
                            : 'Emergency helpline',
                        color: const Color(0xFFB71C1C),
                        onEmptyTap: a.phone.isEmpty
                            ? () => launchUrl(Uri.parse(
                                'https://www.google.com/search?q=${Uri.encodeComponent(a.name + ' ambulance number')}'))
                            : null,
                      ),
                    )),

              const SizedBox(height: 24),

              // Private ambulances
              Row(
                children: [
                  Expanded(
                    child: Text('Private Ambulances Nearby',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  if (emergency.isLoadingPrivate)
                    const SizedBox(width: 14, height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.primary)),
                ],
              ),
              const SizedBox(height: 4),
              Text('Found via Google Maps + web search',
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.4))),
              const SizedBox(height: 12),

              if (emergency.isLoadingPrivate &&
                  emergency.privateAmbulances.isEmpty)
                _loadingCard('Searching nearby ambulance services...')
              else if (emergency.privateAmbulances.isEmpty &&
                  !emergency.isLoadingPrivate)
                _emptyCard('No private ambulances found nearby',
                    onRetry: () => _loadAmbulances(forceRefresh: true))
              else
                ...emergency.privateAmbulances.map((a) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _EmergencyNumberCard(
                        title: a.name,
                        number: a.phone,
                        subtitle: a.address,
                        color: const Color(0xFFE65100),
                        rating: a.rating,
                        source: a.source,
                      ),
                    )),

              const SizedBox(height: 24),

              // Other emergency numbers
              Text('Other Emergency Numbers',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              ..._otherNumbers.map((a) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _EmergencyNumberCard(
                      title: a['title']!,
                      number: a['number']!,
                      subtitle: a['subtitle']!,
                      color: AppColors.primary,
                    ),
                  )),

              const SizedBox(height: 24),

              // First aid guides
              Text('First Aid Guides',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              ..._firstAidGuides.map((g) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _FirstAidCard(
                      title: g['title'] as String,
                      description: g['description'] as String,
                      icon: g['icon'] as IconData,
                      type: g['type'] as String,
                    ),
                  )),

              const SizedBox(height: 20),
            ]),
          ),
        ),
      ],
    );

    if (widget.embedded) return body;
    return Scaffold(body: body);
  }
}

final _ambulanceNumbers = [
  {'title': '108 - Ambulance', 'number': '108',
    'subtitle': 'Free emergency ambulance service'},
  {'title': '102 - Govt Ambulance', 'number': '102',
    'subtitle': 'Government ambulance for pregnant women & newborns'},
];

final _otherNumbers = [
  {'title': '112 - National Emergency', 'number': '112',
    'subtitle': 'Police, fire, and medical emergencies'},
  {'title': '1066 - Blood Bank', 'number': '1066',
    'subtitle': 'Emergency blood requirement'},
  {'title': '1800-180-1104 - Poison Control', 'number': '18001801104',
    'subtitle': 'National poison control helpline'},
];

final _firstAidGuides = [
  {'title': 'CPR', 'description': 'Cardiopulmonary resuscitation steps',
    'icon': Icons.favorite_border_rounded, 'type': 'cpr'},
  {'title': 'Choking', 'description': 'Heimlich maneuver and airway clearance',
    'icon': Icons.air_rounded, 'type': 'choking'},
  {'title': 'Burns', 'description': 'Treatment for thermal and chemical burns',
    'icon': Icons.local_fire_department_rounded, 'type': 'burns'},
  {'title': 'Bleeding', 'description': 'How to control severe bleeding',
    'icon': Icons.bloodtype_outlined, 'type': 'bleeding'},
  {'title': 'Stroke', 'description': 'Recognize and respond to stroke signs',
    'icon': Icons.psychology_outlined, 'type': 'stroke'},
];

class _EmergencyNumberCard extends StatelessWidget {
  final String title;
  final String number;
  final String subtitle;
  final Color color;
  final double? rating;
  final String? source;
  final VoidCallback? onEmptyTap;

  const _EmergencyNumberCard({
    required this.title,
    required this.number,
    required this.subtitle,
    required this.color,
    this.rating,
    this.source,
    this.onEmptyTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPhone = number.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.local_hospital_rounded, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (rating != null)
                  Row(children: [
                    Icon(Icons.star_rounded,
                        size: 12, color: const Color(0xFFFFA000)),
                    const SizedBox(width: 2),
                    Text(rating!.toStringAsFixed(1),
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: const Color(0xFFFFA000))),
                    if (source == 'web') ...[
                      const SizedBox(width: 6),
                      Text('· web',
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.4))),
                    ],
                  ]),
              ],
            ),
          ),
          if (hasPhone)
            FilledButton(
              onPressed: () => launchUrl(Uri.parse('tel:$number')),
              style: FilledButton.styleFrom(
                backgroundColor: color,
                minimumSize: const Size(56, 40),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Icon(Icons.phone_rounded, size: 18),
            )
          else
            OutlinedButton(
              onPressed: onEmptyTap,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(56, 40),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Icon(Icons.search_rounded, size: 18),
            ),
        ],
      ),
    );
  }
}

class _FirstAidCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final String type;

  const _FirstAidCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.cardTheme.color,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('${AppRouter.firstAidDetail}?type=$type'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    Text(description,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6))),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
