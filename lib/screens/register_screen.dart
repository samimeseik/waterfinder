import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:waterfinder/services/auth_service.dart';
import 'package:waterfinder/widgets/loading_indicator.dart';
import 'package:waterfinder/widgets/error_display.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();
  
  bool _isLoading = false;
  bool _isEmailSignup = false;
  bool _showOtpField = false;
  String? _verificationId;
  String? _error;

  Future<void> _handlePhoneSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = context.read<AuthService>();
      
      if (_showOtpField) {
        // Verify OTP
        final result = await authService.verifyOTP(
          _verificationId!,
          _otpController.text,
        );

        if (result != null) {
          // Update user profile with name
          await authService.updateUserProfile(
            displayName: _nameController.text,
          );
          
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/');
          }
        } else {
          setState(() {
            _error = 'رمز التحقق غير صحيح. الرجاء المحاولة مرة أخرى';
            _isLoading = false;
          });
        }
      } else {
        // Send verification code
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
              _error = 'حدث خطأ أثناء إرسال رمز التحقق. الرجاء التأكد من رقم الهاتف والمحاولة مرة أخرى';
              _isLoading = false;
            });
          },
        );
      }
    } catch (e) {
      setState(() {
        _error = _showOtpField 
            ? 'حدث خطأ أثناء التحقق من الرمز. الرجاء المحاولة مرة أخرى'
            : 'حدث خطأ أثناء إرسال رمز التحقق. الرجاء المحاولة مرة أخرى';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleEmailSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = context.read<AuthService>();
      final result = await authService.signUpWithEmail(
        _emailController.text,
        _passwordController.text,
      );

      if (result != null) {
        await authService.updateUserProfile(
          displayName: _nameController.text,
        );
        
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/');
        }
      } else {
        setState(() {
          _error = 'حدث خطأ أثناء إنشاء الحساب. الرجاء المحاولة مرة أخرى';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'حدث خطأ أثناء إنشاء الحساب. الرجاء التأكد من البيانات والمحاولة مرة أخرى';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'إنشاء حساب جديد',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'الاسم',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال الاسم';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                if (_error != null) ...[
                  ErrorDisplay(
                    message: _error!,
                    onRetry: _isEmailSignup ? _handleEmailSignup : _handlePhoneSignup,
                  ),
                  const SizedBox(height: 16),
                ],
                if (_isEmailSignup) ...[
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
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'تأكيد كلمة المرور',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء تأكيد كلمة المرور';
                      }
                      if (value != _passwordController.text) {
                        return 'كلمة المرور غير متطابقة';
                      }
                      return null;
                    },
                  ),
                ] else ...[
                  TextFormField(
                    controller: _phoneController,
                    enabled: !_showOtpField,
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
                    message: 'جاري إنشاء الحساب...',
                  )
                else ...[
                  ElevatedButton(
                    onPressed: _isEmailSignup ? _handleEmailSignup : _handlePhoneSignup,
                    child: Text(
                      _showOtpField
                          ? 'تأكيد رمز التحقق'
                          : _isEmailSignup
                              ? 'إنشاء حساب'
                              : 'إرسال رمز التحقق',
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!_showOtpField) ...[
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isEmailSignup = !_isEmailSignup;
                          _error = null;
                        });
                      },
                      child: Text(
                        _isEmailSignup
                            ? 'التسجيل برقم الهاتف'
                            : 'التسجيل بالبريد الإلكتروني',
                        style: const TextStyle(fontFamily: 'Cairo'),
                      ),
                    ),
                  ],
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: const Text(
                      'لديك حساب بالفعل؟ تسجيل الدخول',
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