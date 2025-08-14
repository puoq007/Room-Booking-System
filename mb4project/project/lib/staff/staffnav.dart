import 'package:flutter/material.dart';
import 'package:project/dashboard.dart';
import 'package:project/staff/staffhome.dart';
import 'package:project/staff/staffprofile.dart';

class Staffnav extends StatefulWidget {
  final int initialIndex;
  final String token; // เพิ่ม token ที่ต้องส่งไปยังหน้าต่าง ๆ

  const Staffnav({Key? key, this.initialIndex = 0, required this.token})
      : super(key: key);

  @override
  State<Staffnav> createState() => _StaffnavState();
}

class _StaffnavState extends State<Staffnav> {
  late int _selectedIndex;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;

    // สร้างรายการหน้าพร้อมส่ง token ไปยัง Staffhome
    _pages = [
      Staffhome(token: widget.token), // ส่ง token ไปให้ Staffhome
      const Dashboard(),
      StaffProfile(),
    ];
  }

  void _navigateAndReset(BuildContext context, int index) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => Staffnav(
          initialIndex: index,
          token: widget.token, // ส่ง token ให้หน้าใหม่
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          _navigateAndReset(context, index);
        },
        selectedItemColor: Colors.black,
        unselectedItemColor: const Color(0xFF796C8A),
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
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
