import 'dart:ui'; // Import for BackdropFilter
import 'package:flutter/material.dart';
import 'esewa_qr_screen.dart'; // Import eSewa QR Screen
import 'khalti_qr_screen.dart'; // Import Khalti QR Screen

class WalletPaymentScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Wallet Payment",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.purple.shade700,
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/fonts/ride.jpg'), // Background image
            fit: BoxFit.cover, // Make the image cover the whole screen
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Transparent frosted background for buttons
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20), // Rounded corners
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0), // Frosted glass effect
                  child: Container(
                    width: 300,
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2), // Transparent box
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3)), // Slight border
                    ),
                    child: Column(
                      children: [
                        // 🟢 Pay via eSewa
                        AnimatedWalletButton(
                          text: "Pay via eSewa",
                          icon: Icons.payment,
                          color: const Color.fromARGB(255, 23, 180, 49),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => EsewaQRScreen()),
                            );
                          },
                        ),
                        SizedBox(height: 20),

                        // 🔵 Pay via Khalti
                        AnimatedWalletButton(
                          text: "Pay via Khalti",
                          icon: Icons.account_balance_wallet,
                          color: Colors.blue,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => KhaltiQRScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 🎨 Custom Animated Button
class AnimatedWalletButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const AnimatedWalletButton({
    required this.text,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  _AnimatedWalletButtonState createState() => _AnimatedWalletButtonState();
}

class _AnimatedWalletButtonState extends State<AnimatedWalletButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 100),
        transform: Matrix4.identity()..scale(_isPressed ? 0.95 : 1.0),
        child: Container(
          width: 250,
          height: 60,
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.8), // Background color with some transparency
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isPressed
                ? []
                : [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(2, 4),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: Colors.white, size: 28),
              SizedBox(width: 10),
              Text(
                widget.text,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}