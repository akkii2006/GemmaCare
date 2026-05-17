import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../widgets/chat/chat_widgets.dart';
import '../../widgets/common/common_widgets.dart';

class ChatModeScreen extends StatelessWidget {
  final bool embedded;

  const ChatModeScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final body = CustomScrollView(
      slivers: [
        SliverAppBar.large(
          title: const Text('Chat'),
          backgroundColor: theme.scaffoldBackgroundColor,
          foregroundColor: theme.colorScheme.onSurface,
          automaticallyImplyLeading: !embedded,
          elevation: 0,
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Text(
                'Select a mode',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Each mode is tuned for a specific type of conversation.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 16),
              ChatModeCard(
                title: 'General',
                description: 'Ask me anything',
                icon: Icons.chat_bubble_outline_rounded,
                color: AppColors.primary,
                onTap: () => context.push('${AppRouter.chat}?mode=general'),
              ),
              const SizedBox(height: 10),
              ChatModeCard(
                title: 'Medical',
                description: 'Symptoms, medicines, health advice',
                icon: Icons.medical_services_outlined,
                color: const Color(0xFF1E88E5),
                onTap: () => context.push('${AppRouter.chat}?mode=medical'),
              ),
              const SizedBox(height: 10),
              ChatModeCard(
                title: 'Mental Health',
                description: 'Talk about how you feel',
                icon: Icons.self_improvement_rounded,
                color: const Color(0xFF8E24AA),
                onTap: () => context.push('${AppRouter.chat}?mode=mental'),
              ),
              const SizedBox(height: 10),
              ChatModeCard(
                title: 'Nutrition',
                description: 'Diet, meals, supplements',
                icon: Icons.restaurant_outlined,
                color: AppColors.success,
                onTap: () => context.push('${AppRouter.chat}?mode=nutrition'),
              ),
              const SizedBox(height: 10),
              ChatModeCard(
                title: 'First Aid',
                description: 'Immediate help guidance',
                icon: Icons.health_and_safety_outlined,
                color: AppColors.error,
                onTap: () => context.push('${AppRouter.chat}?mode=firstaid'),
              ),
              const SizedBox(height: 80),
            ]),
          ),
        ),
      ],
    );

    if (embedded) return body;
    return Scaffold(floatingActionButton: const EmergencyFab(), body: body);
  }
}