import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_controller.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);

    ref.listen(authControllerProvider, (previous, next) {
      if (next.valueOrNull == true) context.go('/dashboard');
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Full name'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _email,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: auth.isLoading
                ? null
                : () => ref.read(authControllerProvider.notifier).register(
                      _name.text.trim(),
                      _email.text.trim(),
                      _password.text,
                    ),
            child: const Text('Register'),
          ),
        ],
      ),
    );
  }
}
