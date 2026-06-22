import 'package:flutter/material.dart';
import '../../services/google_auth_service.dart';

// ─────────────────────────────────────────────────────────────
// GoogleSignInButton — Drop-in widget for any screen
//
// Usage:
//   GoogleSignInButton(
//     role: 'reporter',
//     onSuccess: (user) {
//       Navigator.pushReplacementNamed(context, '/reporter-home');
//     },
//   )
// ─────────────────────────────────────────────────────────────
class GoogleSignInButton extends StatefulWidget {
  final String role;
  final void Function(GoogleAuthUser user)? onSuccess;
  final void Function(String error)? onError;
  final String label;

  const GoogleSignInButton({
    super.key,
    this.role = 'reporter',
    this.onSuccess,
    this.onError,
    this.label = 'Sign in with Google',
  });

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  bool _isLoading = false;
  final _googleAuth = GoogleAuthService();

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      final user = await _googleAuth.signInWithGoogle(role: widget.role);
      widget.onSuccess?.call(user);
    } catch (e) {
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      widget.onError?.call(errorMsg);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _handleGoogleSignIn,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFDADADA), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Google "G" logo
                  _GoogleLogo(),
                  const SizedBox(width: 12),
                  Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Painted Google "G" logo (no asset needed)
// ─────────────────────────────────────────────────────────────
class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(24, 24),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Blue
    final blue = Paint()..color = const Color(0xFF4285F4);
    // Red
    final red = Paint()..color = const Color(0xFFEA4335);
    // Yellow
    final yellow = Paint()..color = const Color(0xFFFBBC05);
    // Green
    final green = Paint()..color = const Color(0xFF34A853);
    // White
    final white = Paint()..color = Colors.white;

    // Background circle
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2,
      white,
    );

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    // Draw the four coloured arcs
    canvas.drawArc(rect, -1.57, 3.14, true, blue); // top-right blue
    canvas.drawArc(rect, 1.57, 1.57, true, green); // bottom-right green
    canvas.drawArc(rect, 3.14, 1.57, true, yellow); // bottom-left yellow
    canvas.drawArc(rect, -1.57, -1.57, true, red); // top-left red

    // White inner circle
    canvas.drawCircle(
      Offset(cx, cy),
      r * 0.6,
      white,
    );

    // Blue horizontal bar
    final barPaint = Paint()..color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(cx, cy - r * 0.18, r, r * 0.36),
      barPaint,
    );

    // Inner white circle again (clean up)
    canvas.drawCircle(
      Offset(cx, cy),
      r * 0.5,
      white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
