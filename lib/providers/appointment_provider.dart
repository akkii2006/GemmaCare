import 'package:flutter/material.dart';
import '../data/models/appointment_model.dart';
import '../data/models/user_profile_model.dart';
import '../data/repositories/appointment_repository.dart';
import '../services/ai/gemma_local_service.dart';

class AppointmentProvider extends ChangeNotifier {
  final AppointmentRepository _repo = AppointmentRepository();
  final GemmaLocalService _local = GemmaLocalService();

  List<Appointment> _upcoming = [];
  List<Appointment> _past = [];
  bool _isLoading = false;
  bool _isGeneratingPrep = false;
  String _prepProgress = '';

  List<Appointment> get upcoming => _upcoming;
  List<Appointment> get past => _past;
  bool get isLoading => _isLoading;
  bool get isGeneratingPrep => _isGeneratingPrep;
  String get prepProgress => _prepProgress;

  Appointment? get todayAppointment {
    final now = DateTime.now();
    try {
      return _upcoming.firstWhere((a) =>
        a.dateTime.year == now.year &&
        a.dateTime.month == now.month &&
        a.dateTime.day == now.day);
    } catch (_) {
      return null;
    }
  }

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    _upcoming = await _repo.getUpcoming();
    _past = await _repo.getPast();
    _isLoading = false;
    notifyListeners();
  }

  Future<Appointment> addAndPrepare({
    required Appointment appointment,
    required UserProfile? profile,
    void Function(String token)? onPrepToken,
    void Function(String token)? onQuestionsToken,
  }) async {
    // Insert first to get ID
    final id = await _repo.insert(appointment);
    var saved = appointment.copyWith(id: id);
    await load();

    // Generate prep with local Gemma
    _isGeneratingPrep = true;
    _prepProgress = 'Generating prep checklist...';
    notifyListeners();

    final conditionsText = profile?.conditions.isNotEmpty == true
        ? profile!.conditions.join(', ')
        : 'no known conditions';
    final age = profile?.age ?? 0;
    final gender = profile?.gender ?? '';

    // Generate prep checklist
    final prepBuffer = StringBuffer();
    try {
      await _local.chatStreaming(
        systemPrompt: 'You are a medical preparation assistant. Be concise and practical.',
        messages: [{
          'role': 'user',
          'content': '''Generate a preparation checklist for a $age year old $gender with $conditionsText 
going to see a ${appointment.specialty} at ${appointment.hospital} on ${_formatDate(appointment.dateTime)}.
Notes: ${appointment.notes.isNotEmpty ? appointment.notes : 'none'}.

List 5-7 specific preparation steps. One per line, start each with an emoji and action verb. No headers.'''
        }],
        onToken: (t) {
          prepBuffer.write(t);
          onPrepToken?.call(t);
          notifyListeners();
        },
        onDone: () {},
        onError: (_) {},
      );
    } catch (_) {}

    _prepProgress = 'Generating questions to ask...';
    notifyListeners();

    // Generate questions to ask
    final questionsBuffer = StringBuffer();
    try {
      await _local.chatStreaming(
        systemPrompt: 'You are a medical assistant helping patients prepare questions for their doctor.',
        messages: [{
          'role': 'user',
          'content': '''Generate 5 important questions for a $age year old $gender with $conditionsText 
to ask their ${appointment.specialty} doctor.
Patient notes: ${appointment.notes.isNotEmpty ? appointment.notes : 'none'}.

List exactly 5 questions. One per line, start each with a number and "?". No headers.'''
        }],
        onToken: (t) {
          questionsBuffer.write(t);
          onQuestionsToken?.call(t);
          notifyListeners();
        },
        onDone: () {},
        onError: (_) {},
      );
    } catch (_) {}

    // Save AI content to DB
    saved = saved.copyWith(
      prepChecklist: prepBuffer.toString(),
      questionsToAsk: questionsBuffer.toString(),
    );
    await _repo.update(saved);
    await load();

    _isGeneratingPrep = false;
    _prepProgress = '';
    notifyListeners();
    return saved;
  }

  Future<void> savePostNotes({
    required Appointment appointment,
    required String notes,
    void Function(String token)? onSummaryToken,
  }) async {
    _isGeneratingPrep = true;
    _prepProgress = 'Summarizing your notes...';
    notifyListeners();

    final summaryBuffer = StringBuffer();
    try {
      await _local.chatStreaming(
        systemPrompt: 'You are a medical notes summarizer. Extract clear action items.',
        messages: [{
          'role': 'user',
          'content': '''Summarize these post-appointment notes into clear action items:

Notes: $notes

Format: bullet points starting with emoji, max 5 items. Focus on: medications, follow-ups, lifestyle changes, tests ordered.'''
        }],
        onToken: (t) {
          summaryBuffer.write(t);
          onSummaryToken?.call(t);
          notifyListeners();
        },
        onDone: () {},
        onError: (_) {},
      );
    } catch (_) {}

    final updated = appointment.copyWith(
      postNotes: notes,
      aiSummary: summaryBuffer.toString(),
      isUpcoming: false,
    );
    await _repo.update(updated);
    await load();

    _isGeneratingPrep = false;
    _prepProgress = '';
    notifyListeners();
  }

  Future<void> cancel(int id) async {
    await _repo.delete(id);
    await load();
  }

  String _formatDate(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
