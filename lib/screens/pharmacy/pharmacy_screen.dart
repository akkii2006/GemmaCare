import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/care_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/places/google_places_service.dart';
import '../../widgets/common/common_widgets.dart';

class PharmacyScreen extends StatefulWidget {
  const PharmacyScreen({super.key});

  @override
  State<PharmacyScreen> createState() => _PharmacyScreenState();
}

class _PharmacyScreenState extends State<PharmacyScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadIfNeeded());
  }

  Future<void> _loadIfNeeded() async {
    final provider = context.read<CareProvider>();
    if (provider.pharmacies.isNotEmpty) return;

    final userProfile = context.read<UserProvider>().profile;
    final lat = userProfile.latitude;
    final lng = userProfile.longitude;
    if (lat == null || lng == null || lat == 0.0 || lng == 0.0) return;

    await provider.fetchNearby(
      lat: lat,
      lng: lng,
      userConditions: userProfile.conditions,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<CareProvider>();
    final userProfile = context.read<UserProvider>().profile;
    final lat = userProfile.latitude ?? 0.0;
    final lng = userProfile.longitude ?? 0.0;
    final hasLocation = lat != 0.0 && lng != 0.0;

    var pharmacies = provider.pharmacies;
    if (_searchQuery.isNotEmpty) {
      pharmacies = pharmacies
          .where((p) =>
      p.name.toLowerCase().contains(_searchQuery) ||
          p.address.toLowerCase().contains(_searchQuery))
          .toList();
    }

    return Scaffold(
      floatingActionButton: const EmergencyFab(),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Nearby Pharmacies'),
            backgroundColor: theme.scaffoldBackgroundColor,
            foregroundColor: theme.colorScheme.onSurface,
            elevation: 0,
            floating: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(68),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: SearchBar(
                  hintText: 'Search medicines or pharmacies',
                  leading: const Icon(Icons.search_rounded),
                  padding: const WidgetStatePropertyAll(
                      EdgeInsets.symmetric(horizontal: 16)),
                  elevation: const WidgetStatePropertyAll(0),
                  backgroundColor:
                  WidgetStatePropertyAll(theme.cardTheme.color),
                  onChanged: (v) =>
                      setState(() => _searchQuery = v.toLowerCase()),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                provider.isLoading
                    ? [
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(60),
                      child: Column(
                        children: [
                          CircularProgressIndicator(
                              color: AppColors.primary),
                          SizedBox(height: 16),
                          Text('Finding nearby pharmacies...'),
                        ],
                      ),
                    ),
                  )
                ]
                    : !hasLocation
                    ? [
                  Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.location_off_rounded,
                            size: 48,
                            color: theme.colorScheme.onSurface
                                .withOpacity(0.2),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Location not set',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Set your location in profile to find nearby pharmacies.',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.5)),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                ]
                    : pharmacies.isEmpty
                    ? [
                  Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.local_pharmacy_outlined,
                            size: 48,
                            color: theme.colorScheme.onSurface
                                .withOpacity(0.2),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No pharmacies found',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(
                                fontWeight:
                                FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Try refreshing or check your location.',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(
                                color: theme
                                    .colorScheme.onSurface
                                    .withOpacity(0.5)),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: _loadIfNeeded,
                            child: const Text('Refresh'),
                          ),
                        ],
                      ),
                    ),
                  )
                ]
                    : pharmacies
                    .map((p) => Padding(
                  padding:
                  const EdgeInsets.only(bottom: 10),
                  child: _PharmacyCard(place: p),
                ))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PharmacyCard extends StatelessWidget {
  final PlaceResult place;
  const _PharmacyCard({required this.place});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.local_pharmacy_rounded,
                color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.name,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: place.openNow
                            ? AppColors.success
                            : AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      place.openNow ? 'Open now' : 'Closed',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: place.openNow
                            ? AppColors.success
                            : AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${place.distanceKm.toStringAsFixed(1)} km',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
                if (place.address.isNotEmpty)
                  Text(
                    place.address,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => launchUrl(Uri.parse(
                'https://maps.google.com/?q=${place.lat},${place.lng}')),
            style: FilledButton.styleFrom(
              minimumSize: const Size(48, 48),
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Icon(Icons.directions_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}