import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticating = false;
  String _authMessage = 'Unlock your wallet';

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    if (!mounted) return;
    setState(() {
      _isAuthenticating = true;
      _authMessage = 'Authenticating...';
    });

    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      if (!canAuthenticate) {
        setState(() {
          _isAuthenticating = false;
          _authMessage = 'Device authentication not supported';
        });
        // Fallback or just let them enter if no security? 
        // For "Secure" apps, maybe block? But for now, let's provide a button to retry or proceed if really stuck.
        // Or strictly require it. Let's assume strict but with a manual button if it fails to try again.
        return;
      }

      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to access your cards',
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: true,
          biometricOnly: false, // Allow PIN/Pattern
        ),
      );

      if (didAuthenticate) {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        setState(() {
          _isAuthenticating = false;
          _authMessage = 'Authentication failed';
        });
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() {
        _isAuthenticating = false;
        _authMessage = 'Error: ${e.message}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAuthenticating = false;
        _authMessage = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isAuthenticating ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
              size: 80,
              color: Colors.white70,
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
             const SizedBox(height: 8),
            Text(
              _authMessage,
              style: const TextStyle(color: Colors.white60),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (!_isAuthenticating)
              ElevatedButton.icon(
                onPressed: _authenticate,
                icon: const Icon(Icons.fingerprint),
                label: const Text('Unlock Wallet'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            if (_isAuthenticating)
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: CircularProgressIndicator(color: Colors.white70),
              ),
          ],
        ),
      ),
    );
  }
}
