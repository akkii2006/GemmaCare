import 'package:url_launcher/url_launcher.dart';

class CallService {
  Future<void> call(String number) async {
    final uri = Uri(scheme: 'tel', path: number.replaceAll(' ', '').replaceAll('-', ''));
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> callEmergency() => call('112');
}
