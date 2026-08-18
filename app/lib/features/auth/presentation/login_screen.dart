import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authControllerProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState is AuthLoading;
    final errorMessage = authState is AuthUnauthenticated ? authState.errorMessage : null;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '로그인',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: '이메일'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => (value == null || value.isEmpty) ? '이메일을 입력해주세요.' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: '비밀번호'),
                    obscureText: true,
                    validator: (value) => (value == null || value.isEmpty) ? '비밀번호를 입력해주세요.' : null,
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorMessage,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: isLoading ? null : _submit,
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('로그인'),
                  ),
                  TextButton(
                    onPressed: () => context.go('/signup'),
                    child: const Text('계정이 없으신가요? 회원가입'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: Divider(color: Theme.of(context).colorScheme.outlineVariant)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('또는'),
                      ),
                      Expanded(child: Divider(color: Theme.of(context).colorScheme.outlineVariant)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: isLoading
                        ? null
                        : () => ref.read(authControllerProvider.notifier).loginWithKakao(),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFFFEE500),
                      foregroundColor: const Color(0xFF191919),
                      side: BorderSide.none,
                    ),
                    icon: const Icon(Icons.chat_bubble, size: 18),
                    label: const Text('카카오로 로그인'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: isLoading
                        ? null
                        : () => ref.read(authControllerProvider.notifier).loginWithGoogle(),
                    icon: const Icon(Icons.g_mobiledata, size: 24),
                    label: const Text('Google로 로그인'),
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
