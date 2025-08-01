import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'registration_screen.dart';

class WelcomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          // Background Image covering the full screen
          Positioned.fill(
            child: Image.asset(
              'assets/fonts/logo1.png', // Background image that will cover the screen
              fit: BoxFit.cover, // Make sure the image covers the entire screen
            ),
          ),

          // Bottom Buttons - Login and Sign Up
          Positioned(
            bottom: 50, // Distance from the bottom of the screen
            left: 0,
            right: 0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo above the buttons with size adjusted to match login button width
                /*Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Image.asset(
                    'assets/fonts/llog.jpg', // Replace with the path to your logo image
                    width: screenWidth * 0.8, // Make the logo width same as the button
                    height: 50, // Adjust height as needed
                    fit: BoxFit.contain, // Make sure the logo maintains aspect ratio
                  ),
                ),*/

                // Login Button with a transparent background
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: InkWell(
                    onTap: () {
                      // Using PageRouteBuilder for smooth slide transition
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) {
                            return const LoginScreen();
                          },
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            const begin = Offset(1.0, 0.0); // Slide from right
                            const end = Offset.zero;
                            const curve = Curves.easeInOut;
                            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                            var offsetAnimation = animation.drive(tween);

                            return SlideTransition(position: offsetAnimation, child: child);
                          },
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      width: screenWidth * 0.8, // Button width 80% of screen width
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3), // Semi-transparent background
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(2, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          "Login",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 15),

                // Sign Up Button with a transparent background
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: InkWell(
                    onTap: () {
                      // Using PageRouteBuilder for smooth slide transition
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) {
                            return const RegistrationScreen();
                          },
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            const begin = Offset(1.0, 0.0); // Slide from right
                            const end = Offset.zero;
                            const curve = Curves.easeInOut;
                            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                            var offsetAnimation = animation.drive(tween);

                            return SlideTransition(position: offsetAnimation, child: child);
                          },
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      width: screenWidth * 0.8, // Button width 80% of screen width
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3), // Semi-transparent background
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(2, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          "Sign Up",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}