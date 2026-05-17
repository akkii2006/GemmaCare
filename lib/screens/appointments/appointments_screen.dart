import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/user_provider.dart';
import '../../data/models/appointment_model.dart';
import '../../widgets/common/common_widgets.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  bool _showUpcoming = true;

  @override
  void initState() {
    super.initState();
    context.read<AppointmentProvider>().load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<AppointmentProvider>();
    final list = _showUpcoming ? provider.upcoming : provider.past;
    final today = provider.todayAppointment;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRouter.newAppointment),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Appointment'),
        backgroundColor: AppColors.primary,
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Appointments'),
            backgroundColor: theme.scaffoldBackgroundColor,
            foregroundColor: theme.colorScheme.onSurface,
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: SegmentedButton<bool>(
                  selected: {_showUpcoming},
                  onSelectionChanged: (v) =>
                      setState(() => _showUpcoming = v.first),
                  segments: const [
                    ButtonSegment(value: true, label: Text('Upcoming')),
                    ButtonSegment(value: false, label: Text('Past')),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Today's appointment banner
                if (today != null && _showUpcoming) ...[
                  _TodayBanner(appointment: today),
                  const SizedBox(height: 20),
                ],

                if (list.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.calendar_month_outlined,
                              size: 48,
                              color: theme.colorScheme.onSurface.withOpacity(0.2)),
                          const SizedBox(height: 12),
                          Text(
                            _showUpcoming
                                ? 'No upcoming appointments'
                                : 'No past appointments',
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.5)),
                          ),
                          const SizedBox(height: 16),
                          if (_showUpcoming)
                            OutlinedButton.icon(
                              onPressed: () => context.push(AppRouter.newAppointment),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Book appointment'),
                            ),
                        ],
                      ),
                    ),
                  )
                else
                  ...list.map((a) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _AppointmentCard(
                            appointment: a, isUpcoming: _showUpcoming),
                      )),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Today Banner ─────────────────────────────────────────────────────────────

class _TodayBanner extends StatelessWidget {
  final Appointment appointment;
  const _TodayBanner({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeStr =
        '${appointment.dateTime.hour.toString().padLeft(2, '0')}:${appointment.dateTime.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('TODAY',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1)),
              ),
              const Spacer(),
              Text(timeStr,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),
            ],
          ),
          const SizedBox(height: 10),
          Text(appointment.doctorName,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18)),
          Text(appointment.specialty,
              style: TextStyle(color: Colors.white.withOpacity(0.8))),
          const SizedBox(height: 4),
          Text(appointment.hospital,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.7), fontSize: 13)),
          if (appointment.prepChecklist.isNotEmpty) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _showPrepSheet(context, appointment),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.checklist_rounded,
                        color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text('View prep checklist',
                        style: TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showPrepSheet(BuildContext context, Appointment a) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _PrepSheet(appointment: a),
    );
  }
}

// ─── Appointment Card ─────────────────────────────────────────────────────────

class _AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final bool isUpcoming;

  const _AppointmentCard(
      {required this.appointment, required this.isUpcoming});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dt = appointment.dateTime;
    final dateStr = '${dt.day}/${dt.month}/${dt.year}';
    final timeStr =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    final hasPrepared = appointment.prepChecklist.isNotEmpty;
    final hasPostNotes = appointment.postNotes.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text(
                  appointment.doctorName.isNotEmpty
                      ? appointment.doctorName[0]
                      : 'D',
                  style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(appointment.doctorName,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    Text(appointment.specialty,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              if (hasPrepared)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome_rounded,
                          size: 12, color: AppColors.success),
                      const SizedBox(width: 3),
                      Text('Prepared',
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(children: [
            _Chip(icon: Icons.calendar_today_rounded, text: dateStr),
            const SizedBox(width: 12),
            _Chip(icon: Icons.access_time_rounded, text: timeStr),
          ]),
          const SizedBox(height: 6),
          _Chip(
              icon: Icons.local_hospital_outlined,
              text: appointment.hospital),

          if (hasPostNotes && !isUpcoming) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(appointment.aiSummary.isNotEmpty
                  ? appointment.aiSummary
                  : appointment.postNotes,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(height: 1.5),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis),
            ),
          ],

          const SizedBox(height: 12),

          if (isUpcoming) ...[
            if (hasPrepared)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showPrepSheet(context, appointment),
                  icon: const Icon(Icons.checklist_rounded, size: 16),
                  label: const Text('View AI Prep'),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 40)),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _generatePrep(context),
                  icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                  label: const Text('Generate AI Prep'),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 40)),
                ),
              ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _confirmCancel(context),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error)),
                  child: const Text('Cancel'),
                ),
              ),
            ]),
          ] else ...[
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _addPostNotes(context),
                  icon: const Icon(Icons.notes_rounded, size: 16),
                  label: Text(hasPostNotes ? 'Edit notes' : 'Add notes'),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 40)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push(AppRouter.newAppointment),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Book again'),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 40)),
                ),
              ),
            ]),
          ],
        ],
      ),
    );
  }

  void _showPrepSheet(BuildContext context, Appointment a) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _PrepSheet(appointment: a),
    );
  }

  Future<void> _generatePrep(BuildContext context) async {
    final profile = context.read<UserProvider>().profile;
    final provider = context.read<AppointmentProvider>();
    await provider.addAndPrepare(
      appointment: appointment,
      profile: profile,
    );
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel appointment?'),
        content: const Text('This will remove the appointment.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Cancel appointment',
                  style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirm == true && appointment.id != null) {
      context.read<AppointmentProvider>().cancel(appointment.id!);
    }
  }

  Future<void> _addPostNotes(BuildContext context) async {
    final ctrl = TextEditingController(text: appointment.postNotes);
    String summaryText = '';
    bool generating = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Post-appointment notes',
                  style: Theme.of(ctx).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Gemma will summarize your action items',
                  style: Theme.of(ctx).textTheme.labelSmall?.copyWith(
                      color: Theme.of(ctx)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.5))),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText:
                      'What did the doctor say? Any medications, follow-ups, tests?',
                  filled: true,
                  fillColor: Theme.of(ctx).cardTheme.color,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
              if (summaryText.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(summaryText,
                      style: Theme.of(ctx)
                          .textTheme
                          .bodySmall
                          ?.copyWith(height: 1.5)),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: generating
                      ? null
                      : () async {
                          setState(() => generating = true);
                          await context
                              .read<AppointmentProvider>()
                              .savePostNotes(
                            appointment: appointment,
                            notes: ctrl.text,
                            onSummaryToken: (t) =>
                                setState(() => summaryText += t),
                          );
                          setState(() => generating = false);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                  icon: generating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.auto_awesome_rounded),
                  label: Text(generating ? 'Summarizing...' : 'Save & Summarize'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Prep Sheet ───────────────────────────────────────────────────────────────

class _PrepSheet extends StatelessWidget {
  final Appointment appointment;
  const _PrepSheet({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, controller) => SingleChildScrollView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(appointment.doctorName,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            Text('${appointment.specialty} · ${appointment.hospital}',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5))),
            const SizedBox(height: 20),

            if (appointment.prepChecklist.isNotEmpty) ...[
              _SheetSection(
                title: '📋 Preparation Checklist',
                content: appointment.prepChecklist,
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
            ],

            if (appointment.questionsToAsk.isNotEmpty)
              _SheetSection(
                title: '❓ Questions to Ask',
                content: appointment.questionsToAsk,
                color: const Color(0xFF7B61FF),
              ),

            if (appointment.postNotes.isNotEmpty) ...[
              const SizedBox(height: 16),
              _SheetSection(
                title: '📝 Post-visit Notes',
                content: appointment.aiSummary.isNotEmpty
                    ? appointment.aiSummary
                    : appointment.postNotes,
                color: AppColors.success,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SheetSection extends StatelessWidget {
  final String title;
  final String content;
  final Color color;

  const _SheetSection(
      {required this.title, required this.content, required this.color});

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
          Text(title,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Text(content,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.6)),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Chip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14,
          color: theme.colorScheme.onSurface.withOpacity(0.5)),
      const SizedBox(width: 4),
      Text(text,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7))),
    ]);
  }
}
