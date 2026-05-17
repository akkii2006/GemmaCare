import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../providers/user_provider.dart';
import '../../providers/care_provider.dart';
import '../../providers/appointment_provider.dart';
import '../../widgets/home/home_widgets.dart';
import '../../widgets/common/common_widgets.dart';
import '../scan/scan_screen.dart';
import '../care/care_screen.dart';
import '../chat/chat_mode_screen.dart';
import '../emergency/emergency_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncData();
      context.read<AppointmentProvider>().load();
    });
  }

  Future<void> _syncData() async {
    if (!mounted) return;
    final user = context.read<UserProvider>().profile;
    if (user.latitude != null && user.longitude != null) {
      await context.read<CareProvider>().fetchNearby(lat: user.latitude! ?? 0.0, lng: user.longitude! ?? 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const _HomeContent(),
      const ScanScreen(embedded: true),
      const ChatModeScreen(embedded: true),
      const CareScreen(embedded: true),
      const EmergencyScreen(embedded: true),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: screens),
      floatingActionButton: _selectedIndex != 4 ? const EmergencyFab() : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.document_scanner_outlined),
            selectedIcon: Icon(Icons.document_scanner_rounded),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_hospital_outlined),
            selectedIcon: Icon(Icons.local_hospital_rounded),
            label: 'Care',
          ),
          NavigationDestination(
            icon: Icon(Icons.emergency_outlined),
            selectedIcon: Icon(Icons.emergency_rounded),
            label: 'Emergency',
          ),
        ],
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userName = context.watch<UserProvider>().profile.name;
    final appointments = context.watch<AppointmentProvider>().upcoming;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: Text(
            'GemmaCare',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          backgroundColor: theme.scaffoldBackgroundColor,
          foregroundColor: theme.colorScheme.onSurface,
            elevation: 0,
            floating: true,
            actions: [
              IconButton(
                onPressed: () => context.push(AppRouter.appointments),
                icon: const Icon(Icons.calendar_month_outlined),
              ),
              IconButton(
                onPressed: () => context.push(AppRouter.profile),
                icon: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'G',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Text(
                _getGreeting(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              Text(
                userName.isNotEmpty ? 'Hello, $userName' : 'Welcome to GemmaCare',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              const EmergencyBanner(),
              const SizedBox(height: 24),
              Text(
                'Quick actions',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              const QuickActionBar(),
              const SizedBox(height: 24),
              if (appointments.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Upcoming appointments',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    TextButton(
                      onPressed: () => context.push(AppRouter.appointments),
                      child: const Text('See all'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...appointments.take(2).map((a) {
                  final dt = a.dateTime;
                  final dateStr = '${dt.day}/${dt.month}/${dt.year}';
                final timeStr =
                '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: RecentActivityCard(
                    title: a.doctorName,
                    subtitle: '$dateStr at $timeStr - ${a.hospital}',
                    icon: Icons.calendar_today_rounded,
                    onTap: () => context.push(AppRouter.appointments),
                  ),
                );
                }),
                const SizedBox(height: 24),
              ],
              Text(
                'What can I help with?',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              RecentActivityCard(
                title: 'Scan a document',
                subtitle: 'Upload a prescription, X-ray, or lab report',
                icon: Icons.document_scanner_rounded,
                onTap: () => context.push(AppRouter.scan),
              ),
              const SizedBox(height: 10),
              RecentActivityCard(
                title: 'Chat with AI',
                subtitle: 'Medical, mental health, nutrition support',
                icon: Icons.chat_bubble_outline_rounded,
                onTap: () => context.push(AppRouter.chatMode),
              ),
              const SizedBox(height: 10),
              RecentActivityCard(
                title: 'Find nearby care',
                subtitle: 'Doctors, hospitals, and pharmacies near you',
                icon: Icons.local_hospital_outlined,
                onTap: () => context.push(AppRouter.care),
              ),
              const SizedBox(height: 80),
            ]),
          ),
        ),
      ],
    );
  }
}
