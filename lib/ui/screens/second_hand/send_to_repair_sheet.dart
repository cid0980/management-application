import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/settings_repository.dart';
import '../../../domain/settings/shop_settings.dart';
import '../../../l10n/l10n.dart';
import '../../widgets/date_sheet.dart';
import '../../widgets/input_sheet.dart';
import '../../widgets/shop_ui.dart';
import '../service/technician_picker.dart';

/// What the shop's own phone goes to the bench with.
class StockRepairRequest {
  const StockRepairRequest({
    required this.complaints,
    required this.technicianUid,
    required this.technician,
    required this.promisedAt,
  });

  final List<String> complaints;
  final String technicianUid;
  final String technician;
  final DateTime promisedAt;
}

/// SEND THE SHOP'S PHONE TO REPAIR
///
/// Taps only: what is wrong (the shop's complaint list), who fixes it, and
/// by when. The phone becomes a job in Repairs, where the technician is told
/// and the checklist is ticked like any other job.
class SendToRepairSheet extends StatefulWidget {
  const SendToRepairSheet({super.key});

  @override
  State<SendToRepairSheet> createState() => _SendToRepairSheetState();
}

class _SendToRepairSheetState extends State<SendToRepairSheet> {
  final _picked = <String>{};
  String _techUid = '';
  String _tech = '';
  late DateTime _promised = _tomorrowAt6();
  String? _error;

  static DateTime _tomorrowAt6() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1, 18);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = context.watch<SettingsRepository>().settings;
    final now = DateTime.now();
    return InputSheet(
      title: Text(l10n.sendToRepairTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FieldLabel(l10n.sendToRepairWhat, required: true),
          const SizedBox(height: 6),
          ToggleRow(
            keyPrefix: 'stock-complaint',
            values: settings.list(OptionKind.complaintTypes).values,
            picked: _picked,
            onToggle: (c, on) => setState(() {
              on ? _picked.add(c) : _picked.remove(c);
              _error = null;
            }),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 12),
          TechnicianPicker(
            key: const Key('stock-technician'),
            uid: _techUid,
            name: _tech,
            onPicked: (uid, name) => setState(() {
              _techUid = uid;
              _tech = name;
            }),
          ),
          const SizedBox(height: 12),
          DayTimeField(
            label: FieldLabel(l10n.sendToRepairBy, required: true),
            fieldKey: 'stock-promised',
            value: _promised,
            onPicked: (d) => setState(() => _promised = d),
            first: DateTime(now.year, now.month, now.day),
            last: DateTime(now.year + 1),
          ),
        ],
      ),
      actions: [
        FilledButton.icon(
          key: const Key('stock-send'),
          onPressed: () {
            if (_picked.isEmpty) {
              setState(() => _error = l10n.sendToRepairNeedWhat);
              return;
            }
            Navigator.of(context).pop(
              StockRepairRequest(
                complaints: _picked.toList(),
                technicianUid: _techUid,
                technician: _tech,
                promisedAt: _promised,
              ),
            );
          },
          icon: const Icon(Icons.build_outlined),
          label: Text(l10n.sendToRepairSave),
        ),
      ],
    );
  }
}
