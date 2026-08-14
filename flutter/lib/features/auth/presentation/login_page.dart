import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _email = TextEditingController(text: 'demo@vectorflow.dev');
  final _password = TextEditingController(text: 'Password123!');

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);

    ref.listen(authControllerProvider, (previous, next) {
      if (next.valueOrNull == true) context.go('/dashboard');
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error.toString())),
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.hub_outlined, size: 72),
                  const SizedBox(height: 16),
                  Text(
                    'VectorFlow',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Production-oriented task package processing',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: auth.isLoading
                        ? null
                        : () => ref.read(authControllerProvider.notifier).login(
                              _email.text.trim(),
                              _password.text,
                            ),
                    child: auth.isLoading
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Login'),
                  ),
                  TextButton(
                    onPressed: () => context.go('/register'),
                    child: const Text('Create account'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
