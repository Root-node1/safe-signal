import 'package:flutter/material.dart';

import '../models/report_draft.dart';
import '../widgets/quick_exit_button.dart';
import '../navigation.dart';
import '../theme.dart';
import 'support_screen.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key, required this.draft});

  final ReportDraft draft;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  late final TextEditingController _route;
  late final TextEditingController _vehicle;
  late final TextEditingController _sacco;
  late final TextEditingController _area;
  bool _showIncidentError = false;

  ReportDraft get _d => widget.draft;

  @override
  void initState() {
    super.initState();
    _route = TextEditingController(text: _d.route);
    _vehicle = TextEditingController(text: _d.vehicle);
    _sacco = TextEditingController(text: _d.sacco);
    _area = TextEditingController(text: _d.area);
  }

  @override
  void dispose() {
    _route.dispose();
    _vehicle.dispose();
    _sacco.dispose();
    _area.dispose();
    super.dispose();
  }

  void _saveFields() {
    _d.route = _route.text;
    _d.vehicle = _vehicle.text;
    _d.sacco = _sacco.text;
    _d.area = _area.text;
  }

  void _continue() {
    _saveFields();
    if (_d.incident == null) {
      setState(() => _showIncidentError = true);
      return;
    }
    Navigator.of(context).push(
      appRoute<void>(context, (_) => SupportScreen(draft: _d)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SafeSignal'),
        actions: [QuickExitButton(draft: _d)],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(24),
              children: [
                Text('Step 1 of 3', style: text.labelLarge),
                const SizedBox(height: 8),
                Semantics(
                  header: true,
                  child: Text('What happened?', style: text.headlineMedium),
                ),
                const SizedBox(height: 16),
                SegmentedButton<Timing>(
                  style: SegmentedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                  ),
                  segments: const [
                    ButtonSegment(
                        value: Timing.now, label: Text('Happening now')),
                    ButtonSegment(
                        value: Timing.after, label: Text('Already happened')),
                  ],
                  selected: {_d.timing},
                  onSelectionChanged: (s) => setState(() => _d.timing = s.first),
                ),
                if (_d.timing == Timing.now) ...[
                  const SizedBox(height: 12),
                  Text(
                    'If you are in immediate danger, call 999 or 112. '
                    'SafeSignal cannot send help.',
                    style: text.bodyMedium?.copyWith(
                      color: SafeSignalColors.coral,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                for (final type in IncidentType.values)
                  _IncidentTile(
                    type: type,
                    selected: _d.incident == type,
                    onTap: () => setState(() {
                      _d.incident = type;
                      _showIncidentError = false;
                    }),
                  ),
                if (_showIncidentError)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        'Choose what happened to continue.',
                        style: text.bodyMedium?.copyWith(
                          color: SafeSignalColors.coral,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                Text('Details (optional)', style: text.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'Add only what you noticed. Please do not enter names or '
                  'phone numbers.',
                  style: text.bodyMedium,
                ),
                const SizedBox(height: 12),
                _field(_route, 'Route or corridor', 'e.g. Ruiru to CBD', maxRoute),
                _field(_vehicle, 'Number plate or matatu name', 'e.g. KDA 123A',
                    maxVehicle,
                    capitalization: TextCapitalization.characters),
                _field(_sacco, 'SACCO or operator', 'e.g. Super Metro', maxSacco),
                _field(_area, 'Where did it happen?',
                    'e.g. near Githurai 45 stage', maxArea,
                    last: true),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _continue,
                  child: const Text('Continue'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: () {
                    _saveFields();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Back'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    String hint,
    int maxLength, {
    TextCapitalization capitalization = TextCapitalization.sentences,
    bool last = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLength: maxLength,
        textCapitalization: capitalization,
        textInputAction: last ? TextInputAction.done : TextInputAction.next,
        autocorrect: false,
        enableSuggestions: false,
        onChanged: (_) => _saveFields(),
        decoration: InputDecoration(labelText: label, hintText: hint),
      ),
    );
  }
}

class _IncidentTile extends StatelessWidget {
  const _IncidentTile({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final IncidentType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        inMutuallyExclusiveGroup: true,
        checked: selected,
        button: true,
        label: '${type.label}. ${type.description}',
        excludeSemantics: true,
        onTap: onTap,
        child: Material(
          color: selected ? SafeSignalColors.tealSubtle : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: selected
                  ? SafeSignalColors.teal
                  : SafeSignalColors.border,
              width: selected ? 2.5 : 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: selected
                          ? SafeSignalColors.teal
                          : SafeSignalColors.border,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(type.label, style: text.titleMedium),
                          const SizedBox(height: 2),
                          Text(type.description, style: text.bodyMedium),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
