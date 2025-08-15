import 'package:flutter/material.dart';
import 'package:project/dashboard.dart';
import 'package:project/approver/apphome.dart';
import 'package:project/approver/appprofile.dart';
import 'package:project/approver/apprequest.dart';

class Appnavbar extends StatefulWidget {
  const Appnavbar({super.key});

  @override
  State<Appnavbar> createState() => _AppnavbarState();
}

class _AppnavbarState extends State<Appnavbar> {

    int _selectedIndex = 0;

  final List<Widget> _pages = const [
    Apphome(),
    Apprequest(),
    Dashboard(),
    Appprofile(),
  ];

  @override
  Widget build(BuildContext context) {
     return Scaffold(
      body: _pages[_selectedIndex],
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