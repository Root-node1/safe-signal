import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_sw.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('sw'),
  ];

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageSwahili.
  ///
  /// In en, this message translates to:
  /// **'Kiswahili'**
  String get languageSwahili;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Report an incident'**
  String get homeTitle;

  /// No description provided for @homeIntro.
  ///
  /// In en, this message translates to:
  /// **'SafeSignal helps matatu and boda-boda commuters in Kenya write down a safety incident. No account is needed, and every detail except what happened is optional.'**
  String get homeIntro;

  /// No description provided for @homeReport.
  ///
  /// In en, this message translates to:
  /// **'Report an incident'**
  String get homeReport;

  /// No description provided for @homeReportNow.
  ///
  /// In en, this message translates to:
  /// **'Report what is happening now'**
  String get homeReportNow;

  /// No description provided for @prototypeTitle.
  ///
  /// In en, this message translates to:
  /// **'Early prototype'**
  String get prototypeTitle;

  /// No description provided for @prototypeBody.
  ///
  /// In en, this message translates to:
  /// **'Your report is sent to SafeSignal only when you tap Submit on the last step, and nothing is saved on your phone. In this prototype, reports are stored temporarily and may be cleared.'**
  String get prototypeBody;

  /// No description provided for @notEmergencyTitle.
  ///
  /// In en, this message translates to:
  /// **'Not an emergency service'**
  String get notEmergencyTitle;

  /// No description provided for @notEmergencyBody.
  ///
  /// In en, this message translates to:
  /// **'SafeSignal does not contact police or anyone else, and does not monitor routes or verify reports. If you are in immediate danger, call 999 or 112.'**
  String get notEmergencyBody;

  /// No description provided for @stepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String stepOf(int current, int total);

  /// No description provided for @whatHappenedTitle.
  ///
  /// In en, this message translates to:
  /// **'What happened?'**
  String get whatHappenedTitle;

  /// No description provided for @timingNow.
  ///
  /// In en, this message translates to:
  /// **'Happening now'**
  String get timingNow;

  /// No description provided for @timingAfter.
  ///
  /// In en, this message translates to:
  /// **'Already happened'**
  String get timingAfter;

  /// No description provided for @dangerNote.
  ///
  /// In en, this message translates to:
  /// **'If you are in immediate danger, call 999 or 112. SafeSignal cannot send help.'**
  String get dangerNote;

  /// No description provided for @chooseIncidentError.
  ///
  /// In en, this message translates to:
  /// **'Choose what happened to continue.'**
  String get chooseIncidentError;

  /// No description provided for @detailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Details (optional)'**
  String get detailsTitle;

  /// No description provided for @detailsHint.
  ///
  /// In en, this message translates to:
  /// **'Add only what you noticed. Please do not enter names or phone numbers.'**
  String get detailsHint;

  /// No description provided for @fieldRoute.
  ///
  /// In en, this message translates to:
  /// **'Route or corridor'**
  String get fieldRoute;

  /// No description provided for @hintRoute.
  ///
  /// In en, this message translates to:
  /// **'e.g. Ruiru to CBD'**
  String get hintRoute;

  /// No description provided for @fieldVehicle.
  ///
  /// In en, this message translates to:
  /// **'Number plate or matatu name'**
  String get fieldVehicle;

  /// No description provided for @hintVehicle.
  ///
  /// In en, this message translates to:
  /// **'e.g. KDA 123A'**
  String get hintVehicle;

  /// No description provided for @fieldSacco.
  ///
  /// In en, this message translates to:
  /// **'SACCO or operator'**
  String get fieldSacco;

  /// No description provided for @hintSacco.
  ///
  /// In en, this message translates to:
  /// **'e.g. Super Metro'**
  String get hintSacco;

  /// No description provided for @fieldArea.
  ///
  /// In en, this message translates to:
  /// **'Where did it happen?'**
  String get fieldArea;

  /// No description provided for @hintArea.
  ///
  /// In en, this message translates to:
  /// **'e.g. near Githurai 45 stage'**
  String get hintArea;

  /// No description provided for @actionContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get actionContinue;

  /// No description provided for @actionBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get actionBack;

  /// No description provided for @incidentHarassmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Someone is harassing me'**
  String get incidentHarassmentLabel;

  /// No description provided for @incidentHarassmentDesc.
  ///
  /// In en, this message translates to:
  /// **'Persistent verbal remarks, intimidation, or aggressive behavior.'**
  String get incidentHarassmentDesc;

  /// No description provided for @incidentThreatsLabel.
  ///
  /// In en, this message translates to:
  /// **'Someone is threatening me'**
  String get incidentThreatsLabel;

  /// No description provided for @incidentThreatsDesc.
  ///
  /// In en, this message translates to:
  /// **'Direct verbal or physical threats of harm or extortion.'**
  String get incidentThreatsDesc;

  /// No description provided for @incidentTouchingLabel.
  ///
  /// In en, this message translates to:
  /// **'Unwanted touching'**
  String get incidentTouchingLabel;

  /// No description provided for @incidentTouchingDesc.
  ///
  /// In en, this message translates to:
  /// **'Non-consensual physical contact, crowding, or invasion of space.'**
  String get incidentTouchingDesc;

  /// No description provided for @incidentFollowedLabel.
  ///
  /// In en, this message translates to:
  /// **'I think I\'m being followed'**
  String get incidentFollowedLabel;

  /// No description provided for @incidentFollowedDesc.
  ///
  /// In en, this message translates to:
  /// **'Someone tailing you at a stage, terminal, or after alighting.'**
  String get incidentFollowedDesc;

  /// No description provided for @incidentDrivingLabel.
  ///
  /// In en, this message translates to:
  /// **'The driver is driving dangerously'**
  String get incidentDrivingLabel;

  /// No description provided for @incidentDrivingDesc.
  ///
  /// In en, this message translates to:
  /// **'Excessive speeding, overlapping, reckless overtaking, or impaired driving.'**
  String get incidentDrivingDesc;

  /// No description provided for @incidentUnsureLabel.
  ///
  /// In en, this message translates to:
  /// **'Something else / not sure'**
  String get incidentUnsureLabel;

  /// No description provided for @incidentUnsureDesc.
  ///
  /// In en, this message translates to:
  /// **'Unusual disturbance, theft, baggage interference, or other safety concern.'**
  String get incidentUnsureDesc;

  /// No description provided for @supportHeading.
  ///
  /// In en, this message translates to:
  /// **'What would help most?'**
  String get supportHeading;

  /// No description provided for @supportIntro.
  ///
  /// In en, this message translates to:
  /// **'Choose an option. Nothing is sent until you submit on the last step.'**
  String get supportIntro;

  /// No description provided for @supportPrivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Submit without contacting anyone'**
  String get supportPrivateTitle;

  /// No description provided for @supportPrivateHint.
  ///
  /// In en, this message translates to:
  /// **'Your report goes to SafeSignal only. Nobody else is contacted.'**
  String get supportPrivateHint;

  /// No description provided for @supportNumbersTitle.
  ///
  /// In en, this message translates to:
  /// **'Show emergency and support phone numbers'**
  String get supportNumbersTitle;

  /// No description provided for @supportNumbersHint.
  ///
  /// In en, this message translates to:
  /// **'Shows official national helplines for you to dial yourself. SafeSignal does not make calls for you.'**
  String get supportNumbersHint;

  /// No description provided for @supportTrustedTitle.
  ///
  /// In en, this message translates to:
  /// **'Alert someone I trust'**
  String get supportTrustedTitle;

  /// No description provided for @supportTrustedHint.
  ///
  /// In en, this message translates to:
  /// **'Automated SMS to a person you choose is in development and not available.'**
  String get supportTrustedHint;

  /// No description provided for @supportCheckInTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask for a partner check-in'**
  String get supportCheckInTitle;

  /// No description provided for @supportCheckInHint.
  ///
  /// In en, this message translates to:
  /// **'Follow-up safety check-in calls by a partner organization are in development and not available.'**
  String get supportCheckInHint;

  /// No description provided for @unavailableTag.
  ///
  /// In en, this message translates to:
  /// **'Unavailable · In development'**
  String get unavailableTag;

  /// No description provided for @unavailableSemantics.
  ///
  /// In en, this message translates to:
  /// **'Unavailable, in development.'**
  String get unavailableSemantics;

  /// No description provided for @chooseSupportError.
  ///
  /// In en, this message translates to:
  /// **'Choose an available option to continue.'**
  String get chooseSupportError;

  /// No description provided for @actionReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get actionReview;

  /// No description provided for @reviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review your details'**
  String get reviewTitle;

  /// No description provided for @reviewIntro.
  ///
  /// In en, this message translates to:
  /// **'Nothing has been sent yet. Tap Submit report to send this to SafeSignal. SafeSignal is not an emergency service.'**
  String get reviewIntro;

  /// No description provided for @reviewRowWhen.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get reviewRowWhen;

  /// No description provided for @reviewRowWhat.
  ///
  /// In en, this message translates to:
  /// **'What happened'**
  String get reviewRowWhat;

  /// No description provided for @reviewRowSupport.
  ///
  /// In en, this message translates to:
  /// **'What would help most'**
  String get reviewRowSupport;

  /// No description provided for @notProvided.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get notProvided;

  /// No description provided for @actionSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit report'**
  String get actionSubmit;

  /// No description provided for @submitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting…'**
  String get submitting;

  /// No description provided for @submittingSemantics.
  ///
  /// In en, this message translates to:
  /// **'Submitting your report'**
  String get submittingSemantics;

  /// No description provided for @actionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit details'**
  String get actionEdit;

  /// No description provided for @errValidation.
  ///
  /// In en, this message translates to:
  /// **'The server could not accept some details. Tap Edit details to check them, then try again.'**
  String get errValidation;

  /// No description provided for @errTimeout.
  ///
  /// In en, this message translates to:
  /// **'The server took too long to respond. Your report may or may not have arrived. You can tap Submit report again: retrying the same report will not create a duplicate while the server keeps running.'**
  String get errTimeout;

  /// No description provided for @errOffline.
  ///
  /// In en, this message translates to:
  /// **'Could not reach SafeSignal. Check your connection and tap Submit report to try again. Your details are still here.'**
  String get errOffline;

  /// No description provided for @errRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many reports from this connection. Please wait {wait} and try again.'**
  String errRateLimited(String wait);

  /// No description provided for @errUnexpected.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong on the server. Your report was not confirmed. Please try again later.'**
  String get errUnexpected;

  /// No description provided for @errNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'This build of the app is not connected to a SafeSignal server, so nothing was sent.'**
  String get errNotConfigured;

  /// No description provided for @waitSeconds.
  ///
  /// In en, this message translates to:
  /// **'{n} seconds'**
  String waitSeconds(int n);

  /// No description provided for @waitMinutes.
  ///
  /// In en, this message translates to:
  /// **'{n} minutes'**
  String waitMinutes(int n);

  /// No description provided for @waitAWhile.
  ///
  /// In en, this message translates to:
  /// **'a while'**
  String get waitAWhile;

  /// No description provided for @confirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Report received'**
  String get confirmTitle;

  /// No description provided for @confirmBody.
  ///
  /// In en, this message translates to:
  /// **'The SafeSignal server accepted your report. In this prototype, reports are stored temporarily and may be cleared.'**
  String get confirmBody;

  /// No description provided for @refCode.
  ///
  /// In en, this message translates to:
  /// **'Reference code'**
  String get refCode;

  /// No description provided for @copyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get copyCode;

  /// No description provided for @codeNote.
  ///
  /// In en, this message translates to:
  /// **'You cannot look this code up yet, and it may stop being valid.'**
  String get codeNote;

  /// No description provided for @confirmNotice.
  ///
  /// In en, this message translates to:
  /// **'Nobody has been contacted. This report has not been verified, reviewed, or forwarded, and nothing is saved on your phone. SafeSignal is not an emergency service. If you are in immediate danger, call 999 or 112.'**
  String get confirmNotice;

  /// No description provided for @helplinesTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency and support numbers'**
  String get helplinesTitle;

  /// No description provided for @helplinesIntro.
  ///
  /// In en, this message translates to:
  /// **'Call these yourself. SafeSignal does not make calls.'**
  String get helplinesIntro;

  /// No description provided for @helplinePoliceName.
  ///
  /// In en, this message translates to:
  /// **'Police and emergency'**
  String get helplinePoliceName;

  /// No description provided for @helplinePoliceDetail.
  ///
  /// In en, this message translates to:
  /// **'If you are in immediate danger'**
  String get helplinePoliceDetail;

  /// No description provided for @helplineMobileName.
  ///
  /// In en, this message translates to:
  /// **'Emergency (mobile)'**
  String get helplineMobileName;

  /// No description provided for @helplineMobileDetail.
  ///
  /// In en, this message translates to:
  /// **'Works from any mobile network'**
  String get helplineMobileDetail;

  /// No description provided for @helplineGbvName.
  ///
  /// In en, this message translates to:
  /// **'National GBV helpline'**
  String get helplineGbvName;

  /// No description provided for @helplineGbvDetail.
  ///
  /// In en, this message translates to:
  /// **'Support after violence or harassment'**
  String get helplineGbvDetail;

  /// No description provided for @actionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get actionDone;

  /// No description provided for @quickExitLabel.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get quickExitLabel;

  /// No description provided for @quickExitSemantics.
  ///
  /// In en, this message translates to:
  /// **'Quick exit. Clears this report and closes SafeSignal.'**
  String get quickExitSemantics;

  /// No description provided for @restoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore report'**
  String get restoreTitle;

  /// No description provided for @restoreIntro.
  ///
  /// In en, this message translates to:
  /// **'You have a saved report.'**
  String get restoreIntro;

  /// No description provided for @restoreHasNotBeenSubmitted.
  ///
  /// In en, this message translates to:
  /// **'This report has not been submitted.'**
  String get restoreHasNotBeenSubmitted;

  /// No description provided for @restoreSavedAt.
  ///
  /// In en, this message translates to:
  /// **'Saved on {date}'**
  String restoreSavedAt(String date);

  /// No description provided for @restoreExpiredIntro.
  ///
  /// In en, this message translates to:
  /// **'Your saved report expired and was deleted.'**
  String get restoreExpiredIntro;

  /// No description provided for @startANewReport.
  ///
  /// In en, this message translates to:
  /// **'Start a new report'**
  String get startANewReport;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @keepSaved.
  ///
  /// In en, this message translates to:
  /// **'Keep saved'**
  String get keepSaved;

  /// No description provided for @restoreCorruptIntro.
  ///
  /// In en, this message translates to:
  /// **'Your saved report could not be read and was deleted.'**
  String get restoreCorruptIntro;

  /// No description provided for @restoreUnavailableIntro.
  ///
  /// In en, this message translates to:
  /// **'Could not read your saved report.'**
  String get restoreUnavailableIntro;

  /// No description provided for @restoreDeleteFailedIntro.
  ///
  /// In en, this message translates to:
  /// **'Your saved report could not be deleted.'**
  String get restoreDeleteFailedIntro;

  /// No description provided for @restoreDeleteFailedBody.
  ///
  /// In en, this message translates to:
  /// **'The report is still saved on this phone.'**
  String get restoreDeleteFailedBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'sw'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'sw':
      return AppLocalizationsSw();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
