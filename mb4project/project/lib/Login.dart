import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart'; // Import JWT package

import 'package:project/Logo.dart';
import 'package:project/approver/appnavbar.dart';
import 'package:project/staff/staffnav.dart';
import 'package:project/stu/stunavbar.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  String url = '192.168.1.173:5554';

void login() async {
  String username = usernameController.text;
  String password = passwordController.text;
  Uri uri = Uri.http(url, '/login');
  debugPrint('login');

  http.Response response = await http.post(uri,
      body: jsonEncode({"username": username, "password": password}),
      headers: {'Content-Type': 'application/json'});

  if (response.statusCode == 200) {
    // ตรวจสอบว่า response body เป็น JSON ที่มี key 'token'
    try {
      Map<String, dynamic> jsonResponse = jsonDecode(response.body); // แปลง JSON response
      String token = jsonResponse['token'];  // ดึง token จาก response
      debugPrint('Received Token: $token');

      // ตรวจสอบว่า token มีค่าและเป็น JWT
      if (token.isNotEmpty) {
        // ตรวจสอบรูปแบบของ token
        List<String> tokenParts = token.split('.');
        if (tokenParts.length == 3) {
          // Token มี 3 ส่วนเป็นไปตามมาตรฐาน JWT
          final jwt = JWT.decode(token); // Decode JWT token
          Map<String, dynamic> payload = jwt.payload;

          // ดึง user_id จาก payload
          int userId = payload['user_id']; // ดึง user_id จาก payload ของ token

          // เก็บ token และ user_id ใน SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token);
          await prefs.setInt('user_id', userId); // เก็บ user_id ไว้ใน SharedPreferences

          // ใช้ role เพื่อตัดสินใจว่าผู้ใช้มีบทบาทอะไร
          if (payload['role'] == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Stunavbar()),
            );
          } else if (payload['role'] == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Appnavbar()),
            );
          } else if (payload['role'] == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => Staffnav(token: token,)),
            );
          }
        } else {
          throw Exception('Token format is incorrect');
        }
      } else {
        throw Exception('Token is empty or invalid');
      }
    } catch (e) {
      debugPrint('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error decoding the token')),
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invalid username or password')),
    );
  }

  debugPrint('Username: $username');
  debugPrint('Password: $password');
  debugPrint('Response Code: ${response.statusCode}');
  debugPrint('Response Body: ${response.body}');
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
                    'Log in',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 30),
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
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const Logo()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE0C9D1),
                      padding: const EdgeInsets.symmetric(vertical: 15),
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
                    onPressed: login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF796C8A),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text(
                      'Next',
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
