import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/auth_state.dart';
import '../../../data/shop_repository.dart';
import '../../../domain/shops/membership.dart';
import '../../../l10n/l10n.dart';
import '../../widgets/shop_ui.dart';

/// WHO IS ON THE JOB: A STAFF MEMBER, NOT A TYPED NAME
///
/// One sideways row: Nobody, then the shop's people. Picking one links the
/// job to their account, so their phone gets its reminders and alarms
/// (ReminderScheduler). A name typed before technicians were linked — or a
/// person since removed from the shop — still shows, marked "not linked",
/// until somebody is picked instead.
class TechnicianPicker extends StatefulWidget {
  const TechnicianPicker({
    super.key,
    required this.uid,
    required this.name,
    required this.onPicked,
  });

  final String uid;
  final String name;
  final void Function(String uid, String name) onPicked;

  @override
  State<TechnicianPicker> createState() => _TechnicianPickerState();
}

class _TechnicianPickerState extends State<TechnicianPicker> {
  Stream<List<ShopMember>>? _members;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_members != null) return;
    final shopId = context.read<AuthState>().shopId;
    ShopRepository? shops;
    try {
      shops = context.read<ShopRepository?>();
    } on ProviderNotFoundException {
      shops = null;
    }
    if (shops != null && shopId != null) {
      _members = shops.watchMembers(shopId);
    }
  }

  /// Without the shop's list (offline start, tests): whoever is signed in.
  List<ShopMember> _fallback() {
    final me = context.read<AuthState>().user;
    if (me == null) return const [];
    return [
      ShopMember(
        uid: me.uid,
        role: me.isAdmin ? ShopRole.admin : ShopRole.staff,
        email: me.email,
        name: me.name,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final stream = _members;
    if (stream == null) return _row(_fallback());
    return StreamBuilder<List<ShopMember>>(
      stream: stream,
      builder: (_, snap) => _row(
        snap.data == null || snap.data!.isEmpty ? _fallback() : snap.data!,
      ),
    );
  }

  static const _nobody = '';
  static const _typed = '\u0000typed';

  Widget _row(List<ShopMember> members) {
    final l10n = context.l10n;
    final byUid = {for (final m in members) m.uid: m};
    final linked = widget.uid.isNotEmpty && byUid.containsKey(widget.uid);
    final typed = !linked && widget.name.trim().isNotEmpty;
    final values = [_nobody, for (final m in members) m.uid, if (typed) _typed];
    return ChoiceRow<String>(
      values: values,
      selected: linked ? widget.uid : (typed ? _typed : _nobody),
      keyOf: (v) => Key(
        v == _nobody
            ? 'technician-none'
            : v == _typed
            ? 'technician-typed'
            : 'technician-$v',
      ),
      labelOf: (v) => v == _nobody
          ? l10n.technicianNobody
          : v == _typed
          ? l10n.technicianNotLinked(widget.name.trim())
          : byUid[v]!.label,
      onPicked: (v) {
        if (v == _typed) return;
        if (v == _nobody) {
          widget.onPicked('', '');
        } else {
          widget.onPicked(v, byUid[v]!.label);
        }
      },
    );
  }
}
