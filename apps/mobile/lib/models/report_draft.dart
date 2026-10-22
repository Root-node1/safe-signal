/// Vocabulary and limits mirror the web app and API (`apps/frontend/src/types.ts`,
/// `apps/backend/schemas.py`). Held in memory only; never written to disk or logs.
enum Timing {
  now('now'),
  after('after');

  const Timing(this.apiValue);
  final String apiValue;
}

/// Display text lives in the ARB files (lib/l10n); only the API values are fixed here.
enum IncidentType {
  harassment('harassment'),
  threats('threats'),
  touching('touching'),
  followed('followed'),
  dangerousDriving('dangerous-driving'),
  unsure('unsure');

  const IncidentType(this.apiValue);
  final String apiValue;
}

/// Values match the API's `support` field. Only the first two work today, as on the web.
/// Titles and hints are localized in lib/l10n.
enum SupportOption {
  private('private', available: true),
  support('support', available: true),
  trustedContact('trusted-contact', available: false),
  checkIn('check-in', available: false);

  const SupportOption(this.apiValue, {required this.available});
  final String apiValue;
  final bool available;
}

/// Same numbers as the web app (`apps/frontend/src/lib/support.ts`). Never translated;
/// verify before launch.
enum Helpline {
  police('999'),
  mobile('112'),
  gbv('1195');

  const Helpline(this.tel);
  final String tel;
}

/// Field limits from the API schema.
const int maxRoute = 120;
const int maxArea = 120;
const int maxVehicle = 20;
const int maxSacco = 80;

class ReportDraft {
  Timing timing = Timing.after;
  IncidentType? incident;
  SupportOption? support;
  String route = '';
  String area = '';
  String vehicle = '';
  String sacco = '';

  void clear() {
    timing = Timing.after;
    incident = null;
    support = null;
    route = '';
    area = '';
    vehicle = '';
    sacco = '';
  }
}

/// Restores a draft from a stored payload.
///
/// The payload is the canonical map `ReportApi.payload` produced, so restoring
/// it and building the payload again yields the same map — and therefore the
/// same signature, so the stored idempotency key is reused (FR-2.2, FR-2.3,
/// RR-2.3).
///
/// Values that are missing or not understood are ignored rather than fatal: a
/// record written by another version must not crash the app (SR-4.2, SR-4.3).
extension ReportDraftRestore on ReportDraft {
  /// Populates the draft from a stored [payload].
  void restoreFrom(Map<String, Object?> payload) {
    timing = _timingFrom(payload['timing']) ?? timing;
    incident = _incidentFrom(payload['incident']);
    support = _supportFrom(payload['support']);
    route = _textFrom(payload['route']) ?? route;
    area = _textFrom(payload['area']) ?? area;
    vehicle = _textFrom(payload['vehicle']) ?? vehicle;
    sacco = _textFrom(payload['sacco']) ?? sacco;
  }
}

Timing? _timingFrom(Object? value) {
  if (value is! String) return null;
  for (final timing in Timing.values) {
    if (timing.apiValue == value) return timing;
  }
  return null;
}

IncidentType? _incidentFrom(Object? value) {
  if (value is! String) return null;
  for (final incident in IncidentType.values) {
    if (incident.apiValue == value) return incident;
  }
  return null;
}

SupportOption? _supportFrom(Object? value) {
  if (value is! String) return null;
  for (final support in SupportOption.values) {
    if (support.apiValue == value) return support;
  }
  return null;
}

String? _textFrom(Object? value) => value is String ? value : null;
