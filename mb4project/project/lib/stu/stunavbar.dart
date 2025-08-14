import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project/stu/stuHome.dart';
import 'package:project/stu/stuProfile.dart';
import 'package:project/stu/stuRequest.dart';

class Stunavbar extends StatefulWidget {
  const Stunavbar({super.key});

  @override
  State<Stunavbar> createState() => _StunavbarState();
}

class _StunavbarState extends State<Stunavbar> {
  int _selectedIndex = 0;
  int? _userId;  // ใช้เก็บ user_id ที่ได้จาก SharedPreferences

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  // ฟังก์ชันสำหรับโหลด user_id จาก SharedPreferences
  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt('user_id');  // ดึง user_id จาก SharedPreferences
    setState(() {
      _userId = userId;
      // กรณีที่ดึง user_id สำเร็จ เราจะสร้าง _pages ใหม่
      if (_userId != null) {
        _pages.add(Stuhome(userId: _userId!));
        _pages.add(const Sturequest());
        _pages.add(const Stuprofile());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _userId == null
          ? const Center(child: CircularProgressIndicator())  // แสดง spinner ขณะโหลด user_id
          : _pages.isEmpty
              ? const SizedBox()
              : _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: Colors.black,
        showUnselectedLabels: true,
        unselectedItemColor: const Color(0xFF796C8A),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            label: 'Request Status',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
