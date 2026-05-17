import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../data/models/user_profile_model.dart';
import '../../providers/user_provider.dart';
import 'steps/name_step.dart';
import 'steps/age_gender_step.dart';
import 'steps/blood_group_step.dart';
import 'steps/allergies_step.dart';
import 'steps/conditions_step.dart';
import 'steps/location_step.dart';
import 'steps/privacy_step.dart';
import 'steps/model_download_step.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 8;

  // Collect user data across steps
  String _name = '';
  int _age = 0;
  String _gender = '';
  String _bloodGroup = '';
  List<String> _allergies = [];
  List<String> _conditions = [];
  bool _privacyMode = false;
  double? _lat;
  double? _lng;

  void _next() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    } else {
      _finish();
    }
  }

  void _back() {
    if (_currentPage > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    }
  }

  Future<void> _finish() async {
    final profile = UserProfile(
      name: _name,
      age: _age,
      gender: _gender,
      bloodGroup: _bloodGroup,
      allergies: _allergies,
      conditions: _conditions,
      privacyMode: _privacyMode,
      latitude: _lat,
      longitude: _lng,
    );
    await context.read<UserProvider>().completeOnboarding(profile);
    if (mounted) context.go(AppRouter.home);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    IconButton(onPressed: _back, icon: const Icon(Icons.arrow_back_rounded), padding: EdgeInsets.zero)
                  else
                    const SizedBox(width: 40),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (_currentPage + 1) / _totalPages,
                        backgroundColor: theme.colorScheme.onSurface.withOpacity(0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        minHeight: 4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text('${_currentPage + 1} of $_totalPages',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5)), textAlign: TextAlign.center),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (p) => setState(() => _currentPage = p),
                children: [
                  NameStep(onNext: _next, onNameChanged: (v) => _name = v),
                  AgeGenderStep(onNext: _next, onChanged: (age, gender) { _age = age; _gender = gender; }),
                  BloodGroupStep(onNext: _next, onChanged: (v) => _bloodGroup = v),
                  AllergiesStep(onNext: _next, onChanged: (v) => _allergies = v),
                  ConditionsStep(onNext: _next, onChanged: (v) => _conditions = v),
                  LocationStep(onNext: _next, onLocationObtained: (lat, lng) { _lat = lat; _lng = lng; }),
                  PrivacyStep(onNext: _next, onChanged: (v) => _privacyMode = v),
                  ModelDownloadStep(onNext: _next),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
