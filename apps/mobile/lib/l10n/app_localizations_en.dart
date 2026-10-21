// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSwahili => 'Kiswahili';

  @override
  String get homeTitle => 'Report an incident';

  @override
  String get homeIntro =>
      'SafeSignal helps matatu and boda-boda commuters in Kenya write down a safety incident. No account is needed, and every detail except what happened is optional.';

  @override
  String get homeReport => 'Report an incident';

  @override
  String get homeReportNow => 'Report what is happening now';

  @override
  String get prototypeTitle => 'Early prototype';

  @override
  String get prototypeBody =>
      'Your report is sent to SafeSignal only when you tap Submit on the last step, and nothing is saved on your phone. In this prototype, reports are stored temporarily and may be cleared.';

  @override
  String get notEmergencyTitle => 'Not an emergency service';

  @override
  String get notEmergencyBody =>
      'SafeSignal does not contact police or anyone else, and does not monitor routes or verify reports. If you are in immediate danger, call 999 or 112.';

  @override
  String stepOf(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get whatHappenedTitle => 'What happened?';

  @override
  String get timingNow => 'Happening now';

  @override
  String get timingAfter => 'Already happened';

  @override
  String get dangerNote =>
      'If you are in immediate danger, call 999 or 112. SafeSignal cannot send help.';

  @override
  String get chooseIncidentError => 'Choose what happened to continue.';

  @override
  String get detailsTitle => 'Details (optional)';

  @override
  String get detailsHint =>
      'Add only what you noticed. Please do not enter names or phone numbers.';

  @override
  String get fieldRoute => 'Route or corridor';

  @override
  String get hintRoute => 'e.g. Ruiru to CBD';

  @override
  String get fieldVehicle => 'Number plate or matatu name';

  @override
  String get hintVehicle => 'e.g. KDA 123A';

  @override
  String get fieldSacco => 'SACCO or operator';

  @override
  String get hintSacco => 'e.g. Super Metro';

  @override
  String get fieldArea => 'Where did it happen?';

  @override
  String get hintArea => 'e.g. near Githurai 45 stage';

  @override
  String get actionContinue => 'Continue';

  @override
  String get actionBack => 'Back';

  @override
  String get incidentHarassmentLabel => 'Someone is harassing me';

  @override
  String get incidentHarassmentDesc =>
      'Persistent verbal remarks, intimidation, or aggressive behavior.';

  @override
  String get incidentThreatsLabel => 'Someone is threatening me';

  @override
  String get incidentThreatsDesc =>
      'Direct verbal or physical threats of harm or extortion.';

  @override
  String get incidentTouchingLabel => 'Unwanted touching';

  @override
  String get incidentTouchingDesc =>
      'Non-consensual physical contact, crowding, or invasion of space.';

  @override
  String get incidentFollowedLabel => 'I think I\'m being followed';

  @override
  String get incidentFollowedDesc =>
      'Someone tailing you at a stage, terminal, or after alighting.';

  @override
  String get incidentDrivingLabel => 'The driver is driving dangerously';

  @override
  String get incidentDrivingDesc =>
      'Excessive speeding, overlapping, reckless overtaking, or impaired driving.';

  @override
  String get incidentUnsureLabel => 'Something else / not sure';

  @override
  String get incidentUnsureDesc =>
      'Unusual disturbance, theft, baggage interference, or other safety concern.';

  @override
  String get supportHeading => 'What would help most?';

  @override
  String get supportIntro =>
      'Choose an option. Nothing is sent until you submit on the last step.';

  @override
  String get supportPrivateTitle => 'Submit without contacting anyone';

  @override
  String get supportPrivateHint =>
      'Your report goes to SafeSignal only. Nobody else is contacted.';

  @override
  String get supportNumbersTitle => 'Show emergency and support phone numbers';

  @override
  String get supportNumbersHint =>
      'Shows official national helplines for you to dial yourself. SafeSignal does not make calls for you.';

  @override
  String get supportTrustedTitle => 'Alert someone I trust';

  @override
  String get supportTrustedHint =>
      'Automated SMS to a person you choose is in development and not available.';

  @override
  String get supportCheckInTitle => 'Ask for a partner check-in';

  @override
  String get supportCheckInHint =>
      'Follow-up safety check-in calls by a partner organization are in development and not available.';

  @override
  String get unavailableTag => 'Unavailable · In development';

  @override
  String get unavailableSemantics => 'Unavailable, in development.';

  @override
  String get chooseSupportError => 'Choose an available option to continue.';

  @override
  String get actionReview => 'Review';

  @override
  String get reviewTitle => 'Review your details';

  @override
  String get reviewIntro =>
      'Nothing has been sent yet. Tap Submit report to send this to SafeSignal. SafeSignal is not an emergency service.';

  @override
  String get reviewRowWhen => 'When';

  @override
  String get reviewRowWhat => 'What happened';

  @override
  String get reviewRowSupport => 'What would help most';

  @override
  String get notProvided => 'Not provided';

  @override
  String get actionSubmit => 'Submit report';

  @override
  String get submitting => 'Submitting…';

  @override
  String get submittingSemantics => 'Submitting your report';

  @override
  String get actionEdit => 'Edit details';

  @override
  String get errValidation =>
      'The server could not accept some details. Tap Edit details to check them, then try again.';

  @override
  String get errTimeout =>
      'The server took too long to respond. Your report may or may not have arrived. You can tap Submit report again: retrying the same report will not create a duplicate while the server keeps running.';

  @override
  String get errOffline =>
      'Could not reach SafeSignal. Check your connection and tap Submit report to try again. Your details are still here.';

  @override
  String errRateLimited(String wait) {
    return 'Too many reports from this connection. Please wait $wait and try again.';
  }

  @override
  String get errUnexpected =>
      'Something went wrong on the server. Your report was not confirmed. Please try again later.';

  @override
  String get errNotConfigured =>
      'This build of the app is not connected to a SafeSignal server, so nothing was sent.';

  @override
  String waitSeconds(int n) {
    return '$n seconds';
  }

  @override
  String waitMinutes(int n) {
    return '$n minutes';
  }

  @override
  String get waitAWhile => 'a while';

  @override
  String get confirmTitle => 'Report received';

  @override
  String get confirmBody =>
      'The SafeSignal server accepted your report. In this prototype, reports are stored temporarily and may be cleared.';

  @override
  String get refCode => 'Reference code';

  @override
  String get copyCode => 'Copy code';

  @override
  String get codeNote =>
      'You cannot look this code up yet, and it may stop being valid.';

  @override
  String get confirmNotice =>
      'Nobody has been contacted. This report has not been verified, reviewed, or forwarded, and nothing is saved on your phone. SafeSignal is not an emergency service. If you are in immediate danger, call 999 or 112.';

  @override
  String get helplinesTitle => 'Emergency and support numbers';

  @override
  String get helplinesIntro =>
      'Call these yourself. SafeSignal does not make calls.';

  @override
  String get helplinePoliceName => 'Police and emergency';

  @override
  String get helplinePoliceDetail => 'If you are in immediate danger';

  @override
  String get helplineMobileName => 'Emergency (mobile)';

  @override
  String get helplineMobileDetail => 'Works from any mobile network';

  @override
  String get helplineGbvName => 'National GBV helpline';

  @override
  String get helplineGbvDetail => 'Support after violence or harassment';

  @override
  String get actionDone => 'Done';

  @override
  String get quickExitLabel => 'Exit';

  @override
  String get quickExitSemantics =>
      'Quick exit. Clears this report and closes SafeSignal.';
}
