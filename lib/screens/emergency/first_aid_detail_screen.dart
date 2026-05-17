import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/call_service.dart';

class FirstAidDetailScreen extends StatelessWidget {
  final String type;

  const FirstAidDetailScreen({super.key, required this.type});

  Map<String, dynamic> get _content {
    switch (type) {
      case 'cpr':
        return {
          'title': 'CPR',
          'subtitle': 'Cardiopulmonary Resuscitation',
          'icon': Icons.favorite_border_rounded,
          'steps': [
            {'step': '1', 'title': 'Check for safety', 'detail': 'Make sure the scene is safe for you and the victim.'},
            {'step': '2', 'title': 'Check responsiveness', 'detail': 'Tap the shoulder and shout "Are you okay?"'},
            {'step': '3', 'title': 'Call for help', 'detail': 'Call 112 or ask someone nearby to call immediately.'},
            {'step': '4', 'title': 'Position your hands', 'detail': 'Place the heel of your hand on the center of the chest. Place your other hand on top.'},
            {'step': '5', 'title': 'Give chest compressions', 'detail': 'Push down at least 5 cm deep at 100-120 compressions per minute. Allow chest to fully rise between each.'},
            {'step': '6', 'title': 'Give rescue breaths', 'detail': 'Tilt the head back, lift the chin, and give 2 rescue breaths each lasting 1 second.'},
            {'step': '7', 'title': 'Continue cycles', 'detail': 'Continue 30 compressions and 2 breaths until help arrives or the person starts breathing normally.'},
          ],
        };
      case 'choking':
        return {
          'title': 'Choking',
          'subtitle': 'Airway Obstruction Relief',
          'icon': Icons.air_rounded,
          'steps': [
            {'step': '1', 'title': 'Assess the situation', 'detail': 'If the person can cough, speak, or breathe, encourage them to keep coughing.'},
            {'step': '2', 'title': 'Call for help', 'detail': 'Call 112 immediately if the person cannot breathe.'},
            {'step': '3', 'title': 'Give 5 back blows', 'detail': 'Lean the person forward and give 5 firm back blows between the shoulder blades with the heel of your hand.'},
            {'step': '4', 'title': 'Give 5 abdominal thrusts', 'detail': 'Stand behind the person, make a fist above the navel, and give 5 quick inward and upward thrusts.'},
            {'step': '5', 'title': 'Repeat', 'detail': 'Alternate between 5 back blows and 5 abdominal thrusts until the object is cleared or help arrives.'},
          ],
        };
      case 'burns':
        return {
          'title': 'Burns',
          'subtitle': 'Burn Treatment',
          'icon': Icons.local_fire_department_rounded,
          'steps': [
            {'step': '1', 'title': 'Cool the burn', 'detail': 'Run cool (not cold) water over the burn for 10-20 minutes immediately.'},
            {'step': '2', 'title': 'Remove clothing', 'detail': 'Gently remove clothing and jewelry near the burn unless stuck to skin.'},
            {'step': '3', 'title': 'Cover the burn', 'detail': 'Cover with a clean, non-fluffy material like cling film or a clean plastic bag.'},
            {'step': '4', 'title': 'Do not', 'detail': 'Do not use ice, butter, toothpaste, or any cream on the burn.'},
            {'step': '5', 'title': 'Seek help', 'detail': 'Call 112 for severe burns, burns on face or hands, or burns larger than 3cm.'},
          ],
        };
      case 'bleeding':
        return {
          'title': 'Bleeding',
          'subtitle': 'Severe Bleeding Control',
          'icon': Icons.bloodtype_outlined,
          'steps': [
            {'step': '1', 'title': 'Apply pressure', 'detail': 'Press firmly on the wound with a clean cloth or bandage. Use your hand if nothing else is available.'},
            {'step': '2', 'title': 'Maintain pressure', 'detail': 'Keep pressing without removing the cloth. If it soaks through, add more on top.'},
            {'step': '3', 'title': 'Elevate', 'detail': 'If possible, raise the injured area above heart level.'},
            {'step': '4', 'title': 'Call 112', 'detail': 'Call emergency services for severe bleeding that does not stop.'},
            {'step': '5', 'title': 'Treat for shock', 'detail': 'Keep the person warm and lying down. Do not give food or water.'},
          ],
        };
      default:
        return {
          'title': 'Stroke',
          'subtitle': 'Stroke Recognition',
          'icon': Icons.psychology_outlined,
          'steps': [
            {'step': '1', 'title': 'Use FAST', 'detail': 'Face drooping, Arm weakness, Speech difficulty, Time to call 112.'},
            {'step': '2', 'title': 'Check face', 'detail': 'Ask them to smile. Is one side drooping?'},
            {'step': '3', 'title': 'Check arms', 'detail': 'Ask them to raise both arms. Does one drift downward?'},
            {'step': '4', 'title': 'Check speech', 'detail': 'Ask them to repeat a simple phrase. Is their speech slurred or strange?'},
            {'step': '5', 'title': 'Call 112', 'detail': 'If any of the above are present, call 112 immediately. Time is critical.'},
          ],
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = _content;
    final steps = content['steps'] as List<Map<String, String>>;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text(content['title'] as String),
            backgroundColor: theme.scaffoldBackgroundColor,
            foregroundColor: theme.colorScheme.onSurface,
            elevation: 0,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      Icon(content['icon'] as IconData, color: AppColors.primary, size: 22),
                      const SizedBox(width: 10),
                      Text(content['subtitle'] as String, style: theme.textTheme.titleSmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      FilledButton(
                        onPressed: () => CallService().callEmergency(),
                        style: FilledButton.styleFrom(minimumSize: const Size(80, 36), padding: const EdgeInsets.symmetric(horizontal: 12)),
                        child: const Text('Call 112'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ...steps.asMap().entries.map((e) => _StepItem(step: e.value['step']!, title: e.value['title']!, detail: e.value['detail']!, isLast: e.key == steps.length - 1)),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final String step;
  final String title;
  final String detail;
  final bool isLast;

  const _StepItem({required this.step, required this.title, required this.detail, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 36, height: 36,
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(step, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
            ),
            if (!isLast) Container(width: 2, height: 50, color: AppColors.primary.withOpacity(0.2)),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(detail, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.75), height: 1.6)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
