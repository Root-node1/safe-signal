/// Vocabulary and limits mirror the web app and API (`apps/frontend/src/types.ts`,
/// `apps/backend/schemas.py`). Held in memory only; never written to disk or logs.
enum Timing { now, after }

enum IncidentType {
  harassment('Someone is harassing me',
      'Persistent verbal remarks, intimidation, or aggressive behavior.'),
  threats('Someone is threatening me',
      'Direct verbal or physical threats of harm or extortion.'),
  touching('Unwanted touching',
      'Non-consensual physical contact, crowding, or invasion of space.'),
  followed("I think I'm being followed",
      'Someone tailing you at a stage, terminal, or after alighting.'),
  dangerousDriving('The driver is driving dangerously',
      'Excessive speeding, overlapping, reckless overtaking, or impaired driving.'),
  unsure('Something else / not sure',
      'Unusual disturbance, theft, baggage interference, or other safety concern.');

  const IncidentType(this.label, this.description);
  final String label;
  final String description;
}

/// Values match the API's `support` field. Only the first two work today, as on the web.
enum SupportOption {
  private('private', 'Submit without contacting anyone',
      'Nobody would be contacted. Sending reports is not available in this '
          'version of the app yet.',
      available: true),
  support('support', 'Show emergency and support phone numbers',
      'Shows official national helplines for you to dial yourself. '
          'SafeSignal does not make calls for you.',
      available: true),
  trustedContact('trusted-contact', 'Alert someone I trust',
      'Automated SMS to a person you choose is in development and not '
          'available.',
      available: false),
  checkIn('check-in', 'Ask for a partner check-in',
      'Follow-up safety check-in calls by a partner organization are in '
          'development and not available.',
      available: false);

  const SupportOption(this.apiValue, this.title, this.hint,
      {required this.available});
  final String apiValue;
  final String title;
  final String hint;
  final bool available;
}

/// Same list as the web app (`apps/frontend/src/lib/support.ts`). Verify before launch.
const supportResources = <({String name, String detail, String tel})>[
  (name: 'Police and emergency', detail: 'If you are in immediate danger', tel: '999'),
  (name: 'Emergency (mobile)', detail: 'Works from any mobile network', tel: '112'),
  (name: 'National GBV helpline', detail: 'Support after violence or harassment', tel: '1195'),
];

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
