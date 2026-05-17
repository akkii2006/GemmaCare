import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/care_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/places/google_places_service.dart';
import '../../data/models/user_profile_model.dart';
import '../../widgets/common/common_widgets.dart';

class CareScreen extends StatefulWidget {
  final bool embedded;
  const CareScreen({super.key, this.embedded = false});

  @override
  State<CareScreen> createState() => _CareScreenState();
}

class _CareScreenState extends State<CareScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  bool _isSearchMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<CareProvider>().init();
      _loadNearby();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  UserProfile get _profile => context.read<UserProvider>().profile;

  Future<void> _loadNearby({bool forceRefresh = false}) async {
    final lat = _profile.latitude;
    final lng = _profile.longitude;
    if (lat == null || lng == null || lat == 0.0 || lng == 0.0) return;

    if (forceRefresh) {
      await context.read<CareProvider>().refresh(
        lat: lat, lng: lng,
        userConditions: _profile.conditions,
        userGender: _profile.gender,
        userAge: _profile.age,
      );
    } else {
      await context.read<CareProvider>().fetchNearby(
        lat: lat, lng: lng,
        userConditions: _profile.conditions,
        userGender: _profile.gender,
        userAge: _profile.age,
      );
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() => _isSearchMode = false);
      context.read<CareProvider>().clearSearch();
      return;
    }
    setState(() => _isSearchMode = true);
    _searchDebounce = Timer(const Duration(milliseconds: 800), () {
      final lat = _profile.latitude ?? 0.0;
      final lng = _profile.longitude ?? 0.0;
      if (lat == 0.0 && lng == 0.0) return;
      context.read<CareProvider>().smartSearch(
        query: value,
        lat: lat, lng: lng,
        userConditions: _profile.conditions,
        userGender: _profile.gender,
        userAge: _profile.age,
      );
    });
  }

  void _showRadiusPicker() {
    final provider = context.read<CareProvider>();
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Search Radius',
                style: Theme.of(ctx).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Tap to change. Will refresh results.',
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.5))),
            const SizedBox(height: 16),
            ...AppConstants.radiusOptions.map((r) {
              final isSelected = provider.radiusMeters == r;
              final label = r >= 1000 ? '${r ~/ 1000} km' : '$r m';
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: isSelected ? AppColors.primary : null,
                ),
                title: Text(label),
                onTap: () async {
                  Navigator.pop(ctx);
                  await provider.setRadius(r);
                  _loadNearby(forceRefresh: true);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<CareProvider>();
    final radiusLabel = provider.radiusMeters >= 1000
        ? '${provider.radiusMeters ~/ 1000} km'
        : '${provider.radiusMeters} m';

    final body = Column(
      children: [
        Material(
          color: theme.scaffoldBackgroundColor,
          child: Column(
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      if (!widget.embedded)
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      Expanded(
                        child: Text('Find Care',
                            style: theme.textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700)),
                      ),
                      // Radius chip
                      GestureDetector(
                        onTap: _showRadiusPicker,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.radar_rounded,
                                  size: 14, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(radiusLabel,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded),
                        onPressed: () => _loadNearby(forceRefresh: true),
                        tooltip: 'Refresh',
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: SearchBar(
                  controller: _searchController,
                  hintText: 'Search...',
                  leading: const Icon(Icons.search_rounded),
                  trailing: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      ),
                  ],
                  padding: const WidgetStatePropertyAll(
                      EdgeInsets.symmetric(horizontal: 16)),
                  elevation: const WidgetStatePropertyAll(0),
                  backgroundColor:
                      WidgetStatePropertyAll(theme.cardTheme.color),
                  onChanged: _onSearchChanged,
                ),
              ),
              if (provider.isLoadingInsights && !_isSearchMode)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 12, height: 12,
                        child: CircularProgressIndicator(
                            color: AppColors.primary, strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          provider.insightProgress.isNotEmpty
                              ? provider.insightProgress
                              : 'Analyzing with AI + web search...',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: AppColors.primary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              if (!_isSearchMode)
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor:
                      theme.colorScheme.onSurface.withOpacity(0.5),
                  indicatorColor: AppColors.primary,
                  tabs: const [
                    Tab(text: 'Hospitals'),
                    Tab(text: 'Doctors'),
                    Tab(text: 'Pharmacies'),
                  ],
                ),
            ],
          ),
        ),
        Expanded(
          child: _isSearchMode
              ? _SearchResultsView(
                  onRefresh: () => _onSearchChanged(_searchController.text),
                )
              : provider.isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: AppColors.primary),
                          SizedBox(height: 16),
                          Text('Finding nearby care...'),
                        ],
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _HospitalTab(onRefresh: () => _loadNearby(forceRefresh: true)),
                        _DoctorTab(onRefresh: () => _loadNearby(forceRefresh: true)),
                        _PharmacyTab(onRefresh: () => _loadNearby(forceRefresh: true)),
                      ],
                    ),
        ),
      ],
    );

    if (widget.embedded) return body;
    return Scaffold(
      floatingActionButton: const EmergencyFab(),
      body: body,
    );
  }
}

// ─── Search Results ──────────────────────────────────────────────────────────

class _SearchResultsView extends StatelessWidget {
  final VoidCallback onRefresh;
  const _SearchResultsView({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CareProvider>();
    final profile = context.read<UserProvider>().profile;

    if (provider.isSearching) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 12),
            Text('Searching...'),
          ],
        ),
      );
    }

    if (provider.searchResults.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('No results found'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: provider.searchResults.length,
      itemBuilder: (context, i) {
        final place = provider.searchResults[i];
        final insight = provider.insights[place.placeId];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _PlaceCard(
            place: place,
            insight: insight,
            icon: Icons.place_rounded,
          ),
        );
      },
    );
  }
}

// ─── Hospital Tab ────────────────────────────────────────────────────────────

class _HospitalTab extends StatelessWidget {
  final VoidCallback onRefresh;
  const _HospitalTab({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CareProvider>();
    final profile = context.read<UserProvider>().profile;
    final lat = profile.latitude ?? 0.0;
    final lng = profile.longitude ?? 0.0;

    if (lat == 0.0 && lng == 0.0) return _NoLocation(onRefresh: onRefresh);
    if (provider.hospitals.isEmpty && !provider.isLoading) {
      return _EmptyState(
        icon: Icons.local_hospital_outlined,
        title: 'No hospitals found',
        subtitle: 'Try increasing the search radius.',
        onRefresh: onRefresh,
      );
    }

    // Split filtered vs normal
    final visible = provider.hospitals
        .where((h) => !(provider.insights[h.placeId]?.filteredOut ?? false))
        .toList();
    final filtered = provider.hospitals
        .where((h) => provider.insights[h.placeId]?.filteredOut ?? false)
        .toList();

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        children: [
          ...visible.map((h) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PlaceCard(
              place: h,
              insight: provider.insights[h.placeId],
              icon: Icons.local_hospital_rounded,
            ),
          )),
          if (filtered.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.filter_list_rounded, size: 14,
                      color: Colors.grey),
                  const SizedBox(width: 6),
                  Text('Not recommended for your profile',
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: Colors.grey)),
                ],
              ),
            ),
            ...filtered.map((h) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Opacity(
                opacity: 0.5,
                child: _PlaceCard(
                  place: h,
                  insight: provider.insights[h.placeId],
                  icon: Icons.local_hospital_rounded,
                  showFilterReason: true,
                ),
              ),
            )),
          ],
        ],
      ),
    );
  }
}

// ─── Doctor Tab ──────────────────────────────────────────────────────────────

class _DoctorTab extends StatelessWidget {
  final VoidCallback onRefresh;
  const _DoctorTab({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CareProvider>();
    final profile = context.read<UserProvider>().profile;
    final lat = profile.latitude ?? 0.0;
    final lng = profile.longitude ?? 0.0;

    if (lat == 0.0 && lng == 0.0) return _NoLocation(onRefresh: onRefresh);
    if (provider.doctors.isEmpty && !provider.isLoading) {
      return _EmptyState(
        icon: Icons.person_search_rounded,
        title: 'No doctors found',
        subtitle: 'Try searching by specialty.',
        onRefresh: onRefresh,
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        itemCount: provider.doctors.length,
        itemBuilder: (context, i) {
          final doctor = provider.doctors[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PlaceCard(
              place: doctor,
              insight: provider.insights[doctor.placeId],
              icon: Icons.person_rounded,
            ),
          );
        },
      ),
    );
  }
}

// ─── Pharmacy Tab ─────────────────────────────────────────────────────────────

class _PharmacyTab extends StatelessWidget {
  final VoidCallback onRefresh;
  const _PharmacyTab({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CareProvider>();
    final profile = context.read<UserProvider>().profile;
    final lat = profile.latitude ?? 0.0;
    final lng = profile.longitude ?? 0.0;

    if (lat == 0.0 && lng == 0.0) return _NoLocation(onRefresh: onRefresh);
    if (provider.pharmacies.isEmpty && !provider.isLoading) {
      return _EmptyState(
        icon: Icons.local_pharmacy_outlined,
        title: 'No pharmacies found',
        subtitle: 'Try increasing the search radius.',
        onRefresh: onRefresh,
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        itemCount: provider.pharmacies.length,
        itemBuilder: (context, i) {
          final pharmacy = provider.pharmacies[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PlaceCard(
              place: pharmacy,
              insight: provider.insights[pharmacy.placeId],
              icon: Icons.local_pharmacy_rounded,
            ),
          );
        },
      ),
    );
  }
}

// ─── Unified Place Card ───────────────────────────────────────────────────────

class _PlaceCard extends StatelessWidget {
  final PlaceResult place;
  final HospitalInsight? insight;
  final IconData icon;
  final bool showFilterReason;

  const _PlaceCard({
    required this.place,
    required this.insight,
    required this.icon,
    this.showFilterReason = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRecommended = insight?.recommendedForUser ?? false;
    final specialization = insight?.specialization;
    final phone = insight?.phone ?? '';
    final openNow = insight?.openNow ?? place.openNow;
    final isAnalyzing = insight == null;

    return Material(
      color: theme.cardTheme.color,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => _PlaceDetailScreen(place: place, insight: insight),
        )),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isRecommended
                          ? AppColors.primary.withOpacity(0.1)
                          : theme.colorScheme.onSurface.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon,
                        color: isRecommended
                            ? AppColors.primary
                            : theme.colorScheme.onSurface.withOpacity(0.4),
                        size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(place.name,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(place.address,
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.5)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _Badge(
                      icon: Icons.near_me_rounded,
                      label: '${place.distanceKm.toStringAsFixed(1)} km',
                      color: theme.colorScheme.onSurface.withOpacity(0.5)),
                  const SizedBox(width: 6),
                  if (place.rating > 0) ...[
                    _Badge(
                        icon: Icons.star_rounded,
                        label: place.rating.toStringAsFixed(1),
                        color: const Color(0xFFFFA000)),
                    const SizedBox(width: 6),
                  ],
                  _Badge(
                      icon: Icons.circle,
                      label: openNow ? 'Open' : 'Closed',
                      color: openNow ? AppColors.success : AppColors.error,
                      iconSize: 8),
                  const Spacer(),
                  if (isAnalyzing)
                    SizedBox(
                      width: 12, height: 12,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: theme.colorScheme.onSurface.withOpacity(0.3)),
                    )
                  else if (specialization != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(specialization,
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
              if (showFilterReason && (insight?.filterReason ?? '').isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(insight!.filterReason,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: AppColors.error)),
              ],
              if (isRecommended) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.success.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline_rounded,
                          size: 14, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text('Recommended for you',
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  if (phone.isNotEmpty) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => launchUrl(Uri.parse('tel:$phone')),
                        icon: const Icon(Icons.phone_outlined, size: 16),
                        label: const Text('Call'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          textStyle: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => launchUrl(Uri.parse(
                          'https://maps.google.com/?q=${place.lat},${place.lng}')),
                      icon: const Icon(Icons.directions_rounded, size: 16),
                      label: const Text('Directions'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        textStyle: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Place Detail Screen ──────────────────────────────────────────────────────

class _PlaceDetailScreen extends StatelessWidget {
  final PlaceResult place;
  final HospitalInsight? insight;

  const _PlaceDetailScreen({required this.place, required this.insight});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final phone = insight?.phone ?? '';
    final website = insight?.website ?? '';
    final hours = insight?.weekdayHours ?? [];
    final pros = insight?.pros ?? [];
    final cons = insight?.cons ?? [];
    final recommendationReason = insight?.recommendationReason ?? '';
    final isRecommended = insight?.recommendedForUser ?? false;
    final specialization = insight?.specialization ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(place.name),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          Row(
            children: [
              _Badge(
                  icon: Icons.near_me_rounded,
                  label: '${place.distanceKm.toStringAsFixed(1)} km',
                  color: theme.colorScheme.onSurface.withOpacity(0.5)),
              const SizedBox(width: 6),
              if (place.rating > 0) ...[
                _Badge(
                    icon: Icons.star_rounded,
                    label: '${place.rating.toStringAsFixed(1)} (${place.userRatingsTotal})',
                    color: const Color(0xFFFFA000)),
                const SizedBox(width: 6),
              ],
              _Badge(
                  icon: Icons.circle,
                  label: (insight?.openNow ?? place.openNow) ? 'Open' : 'Closed',
                  color: (insight?.openNow ?? place.openNow)
                      ? AppColors.success
                      : AppColors.error,
                  iconSize: 8),
            ],
          ),
          const SizedBox(height: 8),
          Text(place.address,
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6))),
          if (specialization.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(specialization,
                  style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
          ],
          if (isRecommended && recommendationReason.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withOpacity(0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      size: 16, color: AppColors.success),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(recommendationReason,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.success)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              if (phone.isNotEmpty) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => launchUrl(Uri.parse('tel:$phone')),
                    icon: const Icon(Icons.phone_outlined, size: 16),
                    label: const Text('Call'),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => launchUrl(Uri.parse(
                      'https://maps.google.com/?q=${place.lat},${place.lng}')),
                  icon: const Icon(Icons.directions_rounded),
                  label: const Text('Directions'),
                ),
              ),
            ],
          ),
          if (website.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => launchUrl(Uri.parse(website)),
                icon: const Icon(Icons.language_rounded),
                label: Text(website, overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
          if (pros.isNotEmpty || cons.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('AI Insights',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Based on Google reviews + web sources',
                style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.4))),
            const SizedBox(height: 12),
            if (pros.isNotEmpty) ...[
              Text('What patients say is good',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              ...pros.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.add_circle_outline_rounded,
                            size: 16, color: AppColors.success),
                        const SizedBox(width: 6),
                        Expanded(
                            child: Text(p,
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(height: 1.4))),
                      ],
                    ),
                  )),
            ],
            if (cons.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Watch out for',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              ...cons.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.remove_circle_outline_rounded,
                            size: 16, color: AppColors.error),
                        const SizedBox(width: 6),
                        Expanded(
                            child: Text(c,
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(height: 1.4))),
                      ],
                    ),
                  )),
            ],
          ],
          if (hours.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Opening Hours',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: hours
                    .map((h) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(h,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(height: 1.5)),
                        ))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final double iconSize;

  const _Badge({
    required this.icon,
    required this.label,
    required this.color,
    this.iconSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: iconSize, color: color),
        const SizedBox(width: 3),
        Text(label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _NoLocation extends StatelessWidget {
  final VoidCallback onRefresh;
  const _NoLocation({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off_rounded,
                size: 48,
                color: theme.colorScheme.onSurface.withOpacity(0.2)),
            const SizedBox(height: 16),
            Text('Location not set',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Set your location in profile to find nearby care.',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5)),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRefresh, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onRefresh;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 48,
                color: theme.colorScheme.onSurface.withOpacity(0.2)),
            const SizedBox(height: 12),
            Text(title,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5)),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRefresh, child: const Text('Refresh')),
          ],
        ),
      ),
    );
  }
}
