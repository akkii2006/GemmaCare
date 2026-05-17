import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/scan/scan_screen.dart';
import '../../screens/scan/scan_result_screen.dart';
import '../../screens/care/care_screen.dart';
import '../../screens/care/doctor_detail_screen.dart';
import '../../screens/care/hospital_detail_screen.dart';
import '../../screens/chat/chat_mode_screen.dart';
import '../../screens/chat/chat_screen.dart';
import '../../screens/emergency/emergency_screen.dart';
import '../../screens/emergency/first_aid_detail_screen.dart';
import '../../screens/appointments/appointments_screen.dart';
import '../../screens/appointments/new_appointment_screen.dart';
import '../../screens/pharmacy/pharmacy_screen.dart';
import '../../screens/profile/profile_screen.dart';

class AppRouter {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String scan = '/scan';
  static const String scanResult = '/scan/result';
  static const String care = '/care';
  static const String doctorDetail = '/care/doctor';
  static const String hospitalDetail = '/care/hospital';
  static const String chatMode = '/chat/mode';
  static const String chat = '/chat';
  static const String emergency = '/emergency';
  static const String firstAidDetail = '/emergency/first-aid';
  static const String appointments = '/appointments';
  static const String newAppointment = '/appointments/new';
  static const String pharmacy = '/pharmacy';
  static const String profile = '/profile';

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    routes: [
      GoRoute(path: splash, builder: (context, state) => const SplashScreen()),
      GoRoute(path: onboarding, builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: home, builder: (context, state) => const HomeScreen()),
      GoRoute(path: scan, builder: (context, state) => const ScanScreen()),
      GoRoute(path: scanResult, builder: (context, state) => const ScanResultScreen()),
      GoRoute(path: care, builder: (context, state) => const CareScreen()),
      GoRoute(path: doctorDetail, builder: (context, state) => const DoctorDetailScreen()),
      GoRoute(path: hospitalDetail, builder: (context, state) => const HospitalDetailScreen()),
      GoRoute(path: chatMode, builder: (context, state) => const ChatModeScreen()),
      GoRoute(
        path: chat,
        builder: (context, state) {
          final mode = state.uri.queryParameters['mode'] ?? 'general';
          return ChatScreen(mode: mode);
        },
      ),
      GoRoute(path: emergency, builder: (context, state) => const EmergencyScreen()),
      GoRoute(
        path: firstAidDetail,
        builder: (context, state) {
          final type = state.uri.queryParameters['type'] ?? 'cpr';
          return FirstAidDetailScreen(type: type);
        },
      ),
      GoRoute(path: appointments, builder: (context, state) => const AppointmentsScreen()),
      GoRoute(path: newAppointment, builder: (context, state) => const NewAppointmentScreen()),
      GoRoute(path: pharmacy, builder: (context, state) => const PharmacyScreen()),
      GoRoute(path: profile, builder: (context, state) => const ProfileScreen()),
    ],
  );
}
