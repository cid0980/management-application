import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/input_rules.dart';
import '../../../app/auth_state.dart';
import '../../../data/settings_repository.dart';
import '../../../domain/settings/languages.dart';
import '../../../l10n/l10n.dart';
import '../../widgets/language_picker.dart';
import '../../../data/shop_repository.dart';
import '../../../domain/shops/shop.dart';
import '../../../l10n/rule_messages.dart';
import '../../widgets/form_jump.dart';
import '../../widgets/shop_ui.dart';

/// SETTING UP A SHOP
///
/// Where somebody lands the first time they sign up: they have an account and
/// belong to no shop, so there is nothing in the app to show them yet.
///
/// Short on purpose. The name is the only thing that cannot be filled in
/// later, because it goes on every bill the shop prints — everything else is
/// editable from Settings afterwards, and a long form in front of somebody
/// who has not seen the app yet is a reason to close it.
class CreateShopScreen extends StatefulWidget {
  const CreateShopScreen({super.key});

  @override
  State<CreateShopScreen> createState() => _CreateShopScreenState();
}

class _CreateShopScreenState extends State<CreateShopScreen> {
  /// Picked at the end of setting the shop up, and written with it. The
  /// device's own language is the first guess — a phone in Tamil usually
  /// belongs to a shop that works in Tamil — and it is only a guess, which is
  /// why the picker is on the page rather than being decided silently.
  late ShopLanguage _language = resolveLanguage(
    device: WidgetsBinding.instance.platformDispatcher.locale.languageCode,
  );

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _gstin = TextEditingController();

  bool _busy = false;
  String? _error;

  /// Each box's own error, once Create was tried.
  Map<String, String> _fieldErrors = const {};

  @override
  void dispose() {
    for (final c in [_name, _phone, _address, _gstin]) {
      c.dispose();
    }
    super.dispose();
  }

  Shop get _asShop => Shop(
    id: 'new',
    name: _name.text,
    phone: _phone.text,
    address: _address.text,
    gstin: _gstin.text,
  );

  Future<void> _create() async {
    final auth = context.read<AuthState>();
    final shops = context.read<ShopRepository>();
    final user = auth.user;
    if (user == null) return;

    final validation = validateShop(_asShop);
    if (!validation.isValid) {
      setState(() {
        _error = ruleText(context, validation.errors.values.first);
        _fieldErrors = ruleTexts(context, validation.errors);
      });
      // To the box that needs something.
      await jumpToFirstError(
        context,
        validation.errors.keys.map((rule) => Key('shop-$rule')),
      );
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final result = await shops.createShop(
      shop: _asShop,
      ownerUid: user.uid,
      ownerEmail: user.email,
      ownerName: user.name,
    );

    if (!mounted) return;
    if (result.ok) {
      // Filed against the new shop before anybody is sent into it, so the
      // first screen they see is already in the language they just picked.
      // Not awaited into the failure path: a shop that exists but whose
      // language did not save is a settings page away from being right, and
      // refusing to open it would be worse.
      unawaited(
        context.read<SettingsRepository>().setLanguage(codeOf(_language)),
      );
    }
    if (!result.ok) {
      setState(() {
        _busy = false;
        _error = result.message;
      });
      return;
    }

    // Told to AuthState directly rather than waiting for another round trip,
    // so the router moves on the moment the shop exists.
    auth.attachShop(shopId: result.shop!.id, shopName: result.shop!.name);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthState>();
    final validation = validateShop(_asShop);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.createShopTitle),
        actions: [
          // White on the navy bar; the theme's navy text would vanish here.
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            onPressed: () => context.read<AuthState>().signOut(),
            child: Text(context.l10n.signOut),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                context.l10n.signedInAs(auth.user?.email ?? ''),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.everythingBelongsToShop,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              TextField(
                key: const Key('shop-name'),
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  label: FieldLabel(context.l10n.shopName, required: true),
                  border: const OutlineInputBorder(),
                  isDense: true,
                  helperText: context.l10n.goesOnEveryBill,
                  errorText: _fieldErrors['name'],
                ),
                onChanged: (_) => setState(() {
                  _error = null;
                  _fieldErrors = const {};
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('shop-phone'),
                controller: _phone,
                keyboardType: TextInputType.phone,
                inputFormatters: phoneInput(),
                maxLength: kPhoneDigits,
                decoration: InputDecoration(
                  labelText: context.l10n.shopPhone,
                  border: const OutlineInputBorder(),
                  isDense: true,
                  errorText: _fieldErrors['phone'],
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('shop-address'),
                controller: _address,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: context.l10n.address,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('shop-gstin'),
                controller: _gstin,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: context.l10n.shopGstin,
                  border: const OutlineInputBorder(),
                  isDense: true,
                  helperText: context.l10n.gstinOptional,
                ),
                onChanged: (_) => setState(() {}),
              ),

              const SizedBox(height: 24),
              Text(context.l10n.language, style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              LanguagePicker(
                selected: _language,
                enabled: !_busy,
                onChanged: (language) => setState(() => _language = language),
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],

              // Warnings never block: a shop with no phone number is a real
              // shop, it just gets bills without one.
              if (validation.hasWarnings && _name.text.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Card(
                  margin: EdgeInsets.zero,
                  color: theme.colorScheme.secondaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.worthALook,
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        for (final w in validation.warnings.values)
                          Text('• ${ruleText(context, w)}'),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),
              FilledButton(
                key: const Key('shop-create'),
                onPressed: _busy ? null : _create,
                child: _busy
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(context.l10n.createTheShop),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.changeLaterInSettings,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
