import 'package:flutter/widgets.dart';

import '../models/report_draft.dart';
import 'app_localizations.dart';

export 'app_localizations.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Maps model enums to translated text. Enum `apiValue`s are never translated.
extension ModelText on AppLocalizations {
  String incidentLabel(IncidentType t) => switch (t) {
        IncidentType.harassment => incidentHarassmentLabel,
        IncidentType.threats => incidentThreatsLabel,
        IncidentType.touching => incidentTouchingLabel,
        IncidentType.followed => incidentFollowedLabel,
        IncidentType.dangerousDriving => incidentDrivingLabel,
        IncidentType.unsure => incidentUnsureLabel,
      };

  String incidentDescription(IncidentType t) => switch (t) {
        IncidentType.harassment => incidentHarassmentDesc,
        IncidentType.threats => incidentThreatsDesc,
        IncidentType.touching => incidentTouchingDesc,
        IncidentType.followed => incidentFollowedDesc,
        IncidentType.dangerousDriving => incidentDrivingDesc,
        IncidentType.unsure => incidentUnsureDesc,
      };

  String timingLabel(Timing t) => t == Timing.now ? timingNow : timingAfter;

  String supportTitle(SupportOption o) => switch (o) {
        SupportOption.private => supportPrivateTitle,
        SupportOption.support => supportNumbersTitle,
        SupportOption.trustedContact => supportTrustedTitle,
        SupportOption.checkIn => supportCheckInTitle,
      };

  String supportHint(SupportOption o) => switch (o) {
        SupportOption.private => supportPrivateHint,
        SupportOption.support => supportNumbersHint,
        SupportOption.trustedContact => supportTrustedHint,
        SupportOption.checkIn => supportCheckInHint,
      };

  String helplineName(Helpline h) => switch (h) {
        Helpline.police => helplinePoliceName,
        Helpline.mobile => helplineMobileName,
        Helpline.gbv => helplineGbvName,
      };

  String helplineDetail(Helpline h) => switch (h) {
        Helpline.police => helplinePoliceDetail,
        Helpline.mobile => helplineMobileDetail,
        Helpline.gbv => helplineGbvDetail,
      };
}
