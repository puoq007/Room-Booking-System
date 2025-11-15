import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:project/Login.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  String url = '192.168.31.90:5554';

  void register() async {
    // Check if any required field is empty
    if (nameController.text.isEmpty || usernameController.text.isEmpty || passwordController.text.isEmpty || confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    // Check if passwords match
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    Uri uri = Uri.http(url, '/register');
    http.Response response = await http.post(
      uri,
      body: jsonEncode({
        "user_name": nameController.text,
        "username": usernameController.text,
        "password": passwordController.text,
      }),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration successful')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Row(
                children: [
                  Text(
                    'Create account',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              // Name TextField
              SizedBox(
                width: 400,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xffcdc0de),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              // Username TextField
              SizedBox(
                width: 400,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xffcdc0de),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              // Password TextField
              SizedBox(
                width: 400,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xffcdc0de),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              // Confirm Password TextField
              SizedBox(
                width: 400,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xffcdc0de),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TextField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm password',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE0C9D1),
                      padding: const EdgeInsets.symmetric(
                        vertical: 15,
                      ),
                    ),
                    child: const Text(
                      'Back',
                      style: TextStyle(
                        color: Color(0xFF796C8A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF796C8A),
                      padding: const EdgeInsets.symmetric(
                        vertical: 15,
                      ),
                    ),
                    child: const Text(
                      'Register',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}