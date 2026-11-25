import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../theme/app_theme.dart';

import '../../app/auth_state.dart';
import '../widgets/form_jump.dart';
import '../widgets/shop_ui.dart';

/// THE GATE
///
/// The app is sold to many shops, so signing in is a real account — an email
/// and a password against Firebase Auth. One screen does both sign-in and
/// sign-up, because the difference matters to us and not to the person
/// standing at the counter: they either have an account or they are making
/// one, and a separate screen for each is a decision they should not have to
/// take before they have read anything.
///
/// Where they land afterwards is not this screen's business. A new owner goes
/// to create a shop, somebody invited by a shop owner goes straight into that
/// shop, and the router decides which from what `AuthState` resolved.
///
/// **Local mode** keeps the old behaviour: with no Firebase behind it, the
/// screen offers a role picker so every admin-only rule can still be walked
/// offline and in tests.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();

  bool _signingUp = false;
  bool _busy = false;
  Role _role = Role.admin;

  /// Boxes left empty when Sign in was tapped, with what to say under each.
  Map<String, String> _missing = const {};

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthState auth) async {
    // An empty box is said under that box, with the cursor put in it —
    // not sent off to come back as a server error.
    final missing = {
      if (_email.text.trim().isEmpty) 'email': context.l10n.emailNeeded,
      if (_password.text.isEmpty) 'password': context.l10n.passwordNeeded,
    };
    setState(() => _missing = missing);
    if (missing.isNotEmpty) {
      await jumpToFirstError(context, missing.keys.map((k) => Key('login-$k')));
      return;
    }
    setState(() => _busy = true);
    if (_signingUp) {
      await auth.signUp(
        email: _email.text,
        password: _password.text,
        name: _name.text,
      );
    } else {
      await auth.signInWithPassword(
        email: _email.text,
        password: _password.text,
      );
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The app's name on forest, like Home's till card, so
          // the first thing anyone sees is the app they will be using.
          ColoredBox(
            color: AppTheme.primary,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppTheme.lime,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.storefront,
                        color: AppTheme.primary,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.appTitle,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            _signingUp
                                ? context.l10n.signUpSubtitle
                                : context.l10n.signInSubtitle,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: const Color(0xFFB9C2D8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(24),
                  children: [
                    if (auth.isLocal)
                      ..._localFields(auth, theme)
                    else
                      ..._accountFields(auth, theme),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _accountFields(AuthState auth, ThemeData theme) => [
    if (_signingUp) ...[
      TextField(
        textInputAction: TextInputAction.next,
        key: const Key('login-name'),
        controller: _name,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          labelText: context.l10n.yourName,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
      const SizedBox(height: 12),
    ],
    TextField(
      textInputAction: TextInputAction.next,
      key: const Key('login-email'),
      controller: _email,
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      decoration: InputDecoration(
        label: FieldLabel(context.l10n.email, required: true),
        border: const OutlineInputBorder(),
        isDense: true,
        errorText: _missing['email'],
      ),
      onChanged: (_) {
        auth.clearError();
        if (_missing.isNotEmpty) setState(() => _missing = const {});
      },
    ),
    const SizedBox(height: 12),
    TextField(
      key: const Key('login-password'),
      controller: _password,
      obscureText: true,
      decoration: InputDecoration(
        label: FieldLabel(context.l10n.password, required: true),
        border: const OutlineInputBorder(),
        isDense: true,
        helperText: _signingUp ? context.l10n.atLeastSixChars : null,
        errorText: _missing['password'],
      ),
      onChanged: (_) {
        auth.clearError();
        if (_missing.isNotEmpty) setState(() => _missing = const {});
      },
      onSubmitted: (_) => _submit(auth),
    ),

    if (auth.error != null) ...[
      const SizedBox(height: 12),
      Text(
        // Firebase's own wording is for developers. This is the shop's.
        auth.error!,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
    ],

    const SizedBox(height: 20),
    FilledButton(
      key: const Key('login-submit'),
      onPressed: _busy || auth.loading ? null : () => _submit(auth),
      child: _busy || auth.loading
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(_signingUp ? context.l10n.createAccount : context.l10n.signIn),
    ),
    const SizedBox(height: 8),
    TextButton(
      key: const Key('login-toggle'),
      onPressed: _busy
          ? null
          : () {
              auth.clearError();
              setState(() => _signingUp = !_signingUp);
            },
      child: Text(
        _signingUp ? context.l10n.haveAccount : context.l10n.setUpNewShop,
      ),
    ),
    if (!_signingUp)
      TextButton(
        onPressed: _email.text.trim().isEmpty
            ? null
            : () async {
                final messenger = ScaffoldMessenger.of(context);
                // Both read before the await: the widget may be gone by
                // the time Firebase answers.
                final sent = context.l10n.resetLinkSent(_email.text.trim());
                await auth.sendPasswordReset(_email.text);
                messenger.showSnackBar(SnackBar(content: Text(sent)));
              },
        child: Text(context.l10n.forgottenPassword),
      ),
  ];

  /// No Firebase behind this — tests, and a device that could not reach it.
  /// The role is picked here so both sides of every admin-only rule can still
  /// be walked.
  List<Widget> _localFields(AuthState auth, ThemeData theme) => [
    Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(context.l10n.offlineModeNote),
      ),
    ),
    const SizedBox(height: 16),
    TextField(
      textInputAction: TextInputAction.next,
      key: const Key('login-email'),
      controller: _email,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: context.l10n.email,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    ),
    const SizedBox(height: 16),
    SegmentedButton<Role>(
      segments: [
        ButtonSegment(value: Role.admin, label: Text(context.l10n.roleAdmin)),
        ButtonSegment(value: Role.staff, label: Text(context.l10n.roleStaff)),
      ],
      selected: {_role},
      onSelectionChanged: (s) => setState(() => _role = s.first),
    ),
    const SizedBox(height: 20),
    FilledButton(
      key: const Key('login-submit'),
      onPressed: () => auth.signInLocally(
        email: _email.text.trim().isEmpty
            ? 'you@frenchmobiles.local'
            : _email.text,
        role: _role,
      ),
      child: Text(context.l10n.continueLabel),
    ),
  ];
}
