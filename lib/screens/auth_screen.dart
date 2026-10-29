import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../session.dart';
import '../support.dart';
import '../ui/common.dart';
import '../ui/theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();

  bool _register = false;
  bool _busy = false;
  Object? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final session = SessionScope.read(context);
    try {
      final email = _email.text.trim();
      if (_register) {
        await session.register(email, _password.text, _name.text.trim());
      } else {
        await session.login(email, _password.text);
      }
      // Успех: _Root сам переключится на список групп.
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _form,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Splitly', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(context.l10n.appTagline, style: const TextStyle(color: Palette.muted)),
                      const SizedBox(height: 28),
                      ErrorBox(_error),
                      if (_register) ...[
                        TextFormField(
                          controller: _name,
                          decoration: InputDecoration(labelText: context.l10n.authName),
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.name],
                          maxLength: 100,
                          validator: (v) => (v ?? '').trim().isEmpty ? context.l10n.authNameRequired : null,
                        ),
                        const SizedBox(height: 4),
                      ],
                      TextFormField(
                        controller: _email,
                        decoration: InputDecoration(labelText: context.l10n.authEmail),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        autofillHints: const [AutofillHints.email],
                        validator: (v) => (v ?? '').contains('@') ? null : context.l10n.authEmailInvalid,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _password,
                        decoration: InputDecoration(labelText: context.l10n.authPassword),
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        autofillHints: [_register ? AutofillHints.newPassword : AutofillHints.password],
                        onFieldSubmitted: (_) => _submit(),
                        validator: (v) => (v ?? '').length < 8 ? context.l10n.authPasswordShort : null,
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _busy ? null : _submit,
                        child: _busy
                            ? const ButtonProgress()
                            : Text(_register ? context.l10n.authSignUp : context.l10n.authSignIn),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(context.l10n.authOr, style: const TextStyle(color: Palette.muted)),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: _busy ? null : () => SessionScope.read(context).startDemo(context.l10n),
                        child: Text(context.l10n.authDemo),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => setState(() {
                                _register = !_register;
                                _error = null;
                              }),
                        child: Text(_register ? context.l10n.authToSignIn : context.l10n.authToSignUp),
                      ),
                      TextButton(
                        onPressed: () => launchUrl(privacyPolicyUrl, mode: LaunchMode.externalApplication),
                        style: TextButton.styleFrom(foregroundColor: Palette.muted),
                        child: Text(context.l10n.privacyPolicy, style: const TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
