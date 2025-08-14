import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  String url = '192.168.1.173:5554';
  Map? dashboard = {
    "totalRoom": 0,
    "totalSlot": 0,
    "freeSlot": "0",
    "pendingRequest": "0",
    "reservedSlot": "0",
    "disableSlot": "0"
  };

  @override
  void initState() {
    super.initState();
    getDashboard();
  }

  Future<void> getDashboard() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    try {
      Uri uri = Uri.http(url, '/dashboard');
      http.Response response = await http.get(
        uri,
        headers: {'authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        setState(() {
          dashboard = jsonDecode(response.body);
        });
        debugPrint(dashboard?['totalRoom'].toString());
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ดึงขนาดหน้าจอ
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    // กำหนดขนาดตัวอักษร
    double titleFontSize = screenWidth * 0.06; // ขนาดตัวอักษรหัวข้อ (Dashboard)
    double valueFontSize = screenWidth * 0.04; // ขนาดตัวอักษรของค่า
    double rowTitleFontSize =
        screenWidth * 0.045; // ขนาดตัวอักษรของข้อความใน Row อื่นๆ

    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                'Dashboard',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: titleFontSize, // ปรับขนาดตัวอักษรของ "Dashboard"
                ),
              ),
            ],
          ),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Total Room',
                  style: TextStyle(
                      fontSize:
                          rowTitleFontSize), // ขนาดตัวอักษรของข้อความใน Row
                ),
                Spacer(),
                Text(
                  '${dashboard?['totalRoom'] ?? 0}',
                  textAlign: TextAlign.right,
                  style:
                      TextStyle(fontSize: valueFontSize), // ขนาดตัวอักษรของค่า
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  'Total Slot',
                  style: TextStyle(
                      fontSize:
                          rowTitleFontSize), // ขนาดตัวอักษรของข้อความใน Row
                ),
                Spacer(),
                Text(
                  '${dashboard?['totalSlot'] ?? 0}',
                  textAlign: TextAlign.right,
                  style:
                      TextStyle(fontSize: valueFontSize), // ขนาดตัวอักษรของค่า
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  'Free Slot',
                  style: TextStyle(
                      fontSize:
                          rowTitleFontSize), // ขนาดตัวอักษรของข้อความใน Row
                ),
                Spacer(),
                Text(
                  '${dashboard?['freeSlot'] ?? 0}',
                  textAlign: TextAlign.right,
                  style:
                      TextStyle(fontSize: valueFontSize), // ขนาดตัวอักษรของค่า
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  'Pending Request',
                  style: TextStyle(
                      fontSize:
                          rowTitleFontSize), // ขนาดตัวอักษรของข้อความใน Row
                ),
                Spacer(),
                Text(
                  '${dashboard?['pendingRequest'] ?? 0}',
                  textAlign: TextAlign.right,
                  style:
                      TextStyle(fontSize: valueFontSize), // ขนาดตัวอักษรของค่า
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  'Reserved Slot',
                  style: TextStyle(
                      fontSize:
                          rowTitleFontSize), // ขนาดตัวอักษรของข้อความใน Row
                ),
                Spacer(),
                Text(
                  '${dashboard?['reservedSlot'] ?? 0}',
                  textAlign: TextAlign.right,
                  style:
                      TextStyle(fontSize: valueFontSize), // ขนาดตัวอักษรของค่า
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  'Disabled Slot Today',
                  style: TextStyle(
                      fontSize:
                          rowTitleFontSize), // ขนาดตัวอักษรของข้อความใน Row
                ),
                Spacer(),
                Text(
                  '${dashboard?['disableSlot'] ?? 0}',
                  textAlign: TextAlign.right,
                  style:
                      TextStyle(fontSize: valueFontSize), // ขนาดตัวอักษรของค่า
                ),
              ],
            ),

            // Chart
            const SizedBox(height: 90),
            Center(
              child: SizedBox(
                height: 320,
                child: PieChart(
                  PieChartData(
                    sections: [
                      // Free Slot
                      PieChartSectionData(
                        color: const Color.fromARGB(184, 67, 169, 72),
                        value: (double.tryParse(dashboard?['freeSlot']) ?? 1),
                        title: 'Free Slot',
                        radius: 75,
                        titleStyle: TextStyle(
                          fontSize:
                              screenWidth * 0.03, // ขนาดตัวอักษรใน Pie Chart
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      // Reserved Slot
                      PieChartSectionData(
                        color: const Color.fromARGB(255, 244, 171, 135),
                        value:
                            (double.tryParse(dashboard?['reservedSlot']) ?? 1),
                        title: 'Reserved',
                        radius: 75,
                        titleStyle: TextStyle(
                          fontSize:
                              screenWidth * 0.03, // ขนาดตัวอักษรใน Pie Chart
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      // Disabled Slot Today
                      PieChartSectionData(
                        color: const Color.fromARGB(255, 226, 104, 95),
                        value:
                            (double.tryParse(dashboard?['disableSlot']) ?? 1),
                        title: 'Disabled',
                        radius: 75,
                        titleStyle: TextStyle(
                          fontSize:
                              screenWidth * 0.03, // ขนาดตัวอักษรใน Pie Chart
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      // Pending Request
                      PieChartSectionData(
                        color: const Color.fromARGB(255, 161, 104, 242),
                        value: (double.tryParse(dashboard?['pendingRequest']) ??
                            1),
                        title: 'Pending',
                        radius: 75,
                        titleStyle: TextStyle(
                          fontSize:
                              screenWidth * 0.03, // ขนาดตัวอักษรใน Pie Chart
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
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
