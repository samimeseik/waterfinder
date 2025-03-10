import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class ErrorBoundary extends StatefulWidget {
  final Widget child;

  const ErrorBoundary({
    super.key,
    required this.child,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool _hasError = false;
  String _errorDetails = '';

  @override
  void initState() {
    super.initState();
    // Listen to Flutter errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      _handleError(details.exception, details.stack);
    };
  }

  void _handleError(dynamic error, StackTrace? stack) {
    FirebaseCrashlytics.instance.recordError(
      error,
      stack,
      reason: 'Flutter Error Boundary caught an error',
    );

    setState(() {
      _hasError = true;
      _errorDetails = error.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'عذراً، حدث خطأ غير متوقع',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorDetails,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontFamily: 'Cairo',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _hasError = false;
                      _errorDetails = '';
                    });
                  },
                  child: const Text(
                    'إعادة المحاولة',
                    style: TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Report the error to developers
                    FirebaseCrashlytics.instance.recordError(
                      _errorDetails,
                      null,
                      reason: 'User reported error',
                    );
                  },
                  child: const Text(
                    'الإبلاغ عن المشكلة',
                    style: TextStyle(
                      color: Colors.blue,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}