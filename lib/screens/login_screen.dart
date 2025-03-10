import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:waterfinder/services/auth_service.dart';
import 'package:waterfinder/widgets/loading_indicator.dart';
import 'package:waterfinder/widgets/error_display.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  
  bool _isLoading = false;
  bool _isEmailLogin = false;
  bool _showOtpField = false;
  String? _verificationId;
  String? _error;

  Future<void> _handlePhoneLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = context.read<AuthService>();
      await authService.verifyPhoneNumber(
        phoneNumber: _phoneController.text,
        onCodeSent: (String verificationId) {
          setState(() {
            _verificationId = verificationId;
            _showOtpField = true;
            _isLoading = false;
          });
        },
        onError: (String message) {
          setState(() {
            _error = message;
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _error = 'حدث خطأ أثناء إرسال رمز التحقق';
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyOtp() async {
    if (_verificationId == null || _otpController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = context.read<AuthService>();
      final result = await authService.verifyOTP(
        _verificationId!,
        _otpController.text,
      );

      if (result != null) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/');
        }
      } else {
        setState(() {
          _error = 'رمز التحقق غير صحيح';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'حدث خطأ أثناء التحقق من الرمز';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleEmailLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = context.read<AuthService>();
      final result = await authService.signInWithEmail(
        _emailController.text,
        _passwordController.text,
      );

      if (result != null) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/');
        }
      } else {
        setState(() {
          _error = 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'حدث خطأ أثناء تسجيل الدخول. الرجاء المحاولة مرة أخرى';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),
                const Icon(
                  Icons.water_drop,
                  size: 64,
                  color: Colors.blue,
                ),
                const SizedBox(height: 24),
                const Text(
                  'مرحباً بك في Water Finder',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'سجل دخولك للمساهمة في مساعدة مجتمعك',
                  style: TextStyle(
                    color: Colors.grey,
                    fontFamily: 'Cairo',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (_error != null) ...[
                  ErrorDisplay(
                    message: _error!,
                    onRetry: _isEmailLogin ? _handleEmailLogin : _handlePhoneLogin,
                  ),
                  const SizedBox(height: 16),
                ],
                if (_isEmailLogin) ...[
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'البريد الإلكتروني',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال البريد الإلكتروني';
                      }
                      if (!value.contains('@')) {
                        return 'البريد الإلكتروني غير صحيح';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'كلمة المرور',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال كلمة المرور';
                      }
                      if (value.length < 6) {
                        return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                      }
                      return null;
                    },
                  ),
                ] else ...[
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'رقم الهاتف',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                      hintText: '+249XXXXXXXXX',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال رقم الهاتف';
                      }
                      if (!value.startsWith('+')) {
                        return 'الرجاء إدخال رمز البلد';
                      }
                      return null;
                    },
                  ),
                  if (_showOtpField) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'رمز التحقق',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock_clock),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال رمز التحقق';
                        }
                        if (value.length != 6) {
                          return 'رمز التحقق يجب أن يكون 6 أرقام';
                        }
                        return null;
                      },
                    ),
                  ],
                ],
                const SizedBox(height: 24),
                if (_isLoading)
                  const LoadingIndicator(
                    message: 'جاري تسجيل الدخول...',
                  )
                else ...[
                  ElevatedButton(
                    onPressed: _showOtpField ? _verifyOtp : 
                      _isEmailLogin ? _handleEmailLogin : _handlePhoneLogin,
                    child: Text(
                      _showOtpField ? 'تحقق من الرمز' :
                      _isEmailLogin ? 'تسجيل الدخول' : 'إرسال رمز التحقق',
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isEmailLogin = !_isEmailLogin;
                        _error = null;
                      });
                    },
                    child: Text(
                      _isEmailLogin
                          ? 'تسجيل الدخول برقم الهاتف'
                          : 'تسجيل الدخول بالبريد الإلكتروني',
                      style: const TextStyle(fontFamily: 'Cairo'),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/register');
                    },
                    child: const Text(
                      'إنشاء حساب جديد',
                      style: TextStyle(fontFamily: 'Cairo'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}