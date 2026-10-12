import 'package:flutter/material.dart';
import 'login_selection_screen.dart';
import 'register_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFA),

      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),

            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,

              children: [
                // Medical Icon
                Container(
                  height: 130,
                  width: 130,

                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F5F4),
                    borderRadius: BorderRadius.circular(65),
                  ),

                  child: const Icon(
                    Icons.medical_services,
                    size: 70,
                    color: Color(0xFF0E9F9A),
                  ),
                ),

                const SizedBox(height: 30),

                // MediCare
                const Text(
                  "MediCare",
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0E9F9A),
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  "Your Health, Our Priority",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 60),

                // LOGIN BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 55,

                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginSelectionScreen(),
                        ),
                      );
                    },

                    icon: const Icon(Icons.login),

                    label: const Text(
                      "LOGIN",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0E9F9A),
                      foregroundColor: Colors.white,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // REGISTER BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 55,

                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterScreen(),
                        ),
                      );
                    },

                    icon: const Icon(Icons.person_add),

                    label: const Text(
                      "REGISTER",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0E9F9A),

                      side: const BorderSide(
                        color: Color(0xFF0E9F9A),
                        width: 1.5,
                      ),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                const Text(
                  "Book appointments with trusted doctors",
                  textAlign: TextAlign.center,

                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}