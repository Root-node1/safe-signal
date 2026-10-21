import 'package:flutter/material.dart';

import '../api/submission_controller.dart';
import '../design_tokens.dart';
import '../l10n/l10n.dart';
import '../models/report_draft.dart';
import '../navigation.dart';
import '../widgets/widgets.dart';
import 'support_screen.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key, required this.controller});

  final SubmissionController controller;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  late final TextEditingController _route;
  late final TextEditingController _vehicle;
  late final TextEditingController _sacco;
  late final TextEditingController _area;
  bool _showIncidentError = false;

  ReportDraft get _d => widget.controller.draft;

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
      appRoute<void>(context, (_) => SupportScreen(controller: widget.controller)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final l = context.l10n;
    final errorColor = Theme.of(context).colorScheme.error;
    // The secondary action mirrors the height of the primary one, which the
    // shared theme defines, rather than repeating a literal in this screen.
    final secondaryButtonHeight =
        Theme.of(context).filledButtonTheme.style?.minimumSize?.resolve({})?.height ??
            kTouchMin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SafeSignal'),
        actions: [QuickExitButton(controller: widget.controller)],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(kSpace6),
              children: [
                StepHeader(
                  stepLabel: l.stepOf(1, 3),
                  title: l.whatHappenedTitle,
                ),
                SegmentedButton<Timing>(
                  style: SegmentedButton.styleFrom(
                    minimumSize: const Size(0, kTouchMin),
                  ),
                  segments: [
                    ButtonSegment(value: Timing.now, label: Text(l.timingNow)),
                    ButtonSegment(value: Timing.after, label: Text(l.timingAfter)),
                  ],
                  selected: {_d.timing},
                  onSelectionChanged: (s) => setState(() => _d.timing = s.first),
                ),
                if (_d.timing == Timing.now) ...[
                  const SizedBox(height: kSpace3),
                  SafeSignalBanner(
                    variant: SafeSignalBannerVariant.warning,
                    title: '',
                    body: l.dangerNote,
                  ),
                ],
                const SizedBox(height: kSpace5),
                for (final type in IncidentType.values)
                  SafeSignalTile(
                    title: l.incidentLabel(type),
                    subtitle: l.incidentDescription(type),
                    selected: _d.incident == type,
                    onTap: () => setState(() {
                      _d.incident = type;
                      _showIncidentError = false;
                    }),
                  ),
                if (_showIncidentError)
                  Padding(
                    padding: const EdgeInsets.only(top: kSpace1),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        l.chooseIncidentError,
                        style: text.bodyMedium?.copyWith(
                          color: errorColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: kSpace6),
                Text(l.detailsTitle, style: text.titleLarge),
                const SizedBox(height: kSpace1),
                Text(l.detailsHint, style: text.bodyMedium),
                const SizedBox(height: kSpace3),
                _field(_route, l.fieldRoute, l.hintRoute, maxRoute),
                _field(_vehicle, l.fieldVehicle, l.hintVehicle, maxVehicle,
                    capitalization: TextCapitalization.characters),
                _field(_sacco, l.fieldSacco, l.hintSacco, maxSacco),
                _field(_area, l.fieldArea, l.hintArea, maxArea, last: true),
                const SizedBox(height: kSpace2),
                FilledButton(
                  onPressed: _continue,
                  child: Text(l.actionContinue),
                ),
                const SizedBox(height: kSpace2),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size.fromHeight(secondaryButtonHeight),
                  ),
                  onPressed: () {
                    _saveFields();
                    Navigator.of(context).pop();
                  },
                  child: Text(l.actionBack),
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
      padding: const EdgeInsets.only(bottom: kSpace4),
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
