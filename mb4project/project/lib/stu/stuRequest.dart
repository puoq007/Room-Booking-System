import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Sturequest extends StatefulWidget {
  const Sturequest({super.key});

  @override
  State<Sturequest> createState() => _SturequestState();
}

class _SturequestState extends State<Sturequest> {
  List<Map<String, dynamic>> reservations = [];
  bool isLoading = true;
  String userId = ''; // ตัวแปรเก็บ user_id จาก SharedPreferences

  // ฟังก์ชันดึง user_id จาก SharedPreferences
Future<void> fetchUserIdAndData() async {
  setState(() {
    isLoading = true; // เริ่มโหลดข้อมูล
  });

  try {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id'); // ดึง user_id จาก SharedPreferences

    if (userId != null) {
      // เรียก API เพื่อนำข้อมูลการจอง
      await fetchReservationData();
    } else {
      throw Exception('User ID not found in SharedPreferences');
    }
  } catch (e) {
    debugPrint('Error: $e'); // ใช้ debugPrint แทน print
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to fetch user data: ${e.toString()}')),
    );
  } finally {
    setState(() {
      isLoading = false; // โหลดข้อมูลเสร็จ
    });
  }
}

  // ฟังก์ชันดึงข้อมูลการจอง
  Future<void> fetchReservationData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token'); // ดึง token จาก SharedPreferences

      if (token == null) {
        throw Exception('Token not found');
      }

      final response = await http.get(
        Uri.parse('http://192.168.1.173:5554/information'),
        headers: {'Authorization': 'Bearer $token'}, // ใช้ token ใน header
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // กรองข้อมูลสถานะ 'pending' และแปลงให้อยู่ในรูปแบบที่ใช้ใน Widget ได้
        setState(() {
          reservations = List<Map<String, dynamic>>.from(data.map((item) {
            String status;
            if (item['status'] == 1) {
              status = 'approve';
            } else if (item['status'] == 2) {
              status = 'disapprove';
            } else {
              status = 'pending';
            }

            String approver = item['approver_name'] != null
                ? item['approver_name'].toString()
                : 'N/A';

            if (status == 'pending') {
              return {
                'dateTime': item['booking_date']?.toString() ?? 'N/A',
                'room': item['room_name']?.toString() ?? 'N/A',
                'status': status,
                'approver': approver,
              };
            } else {
              return null;
            }
          }).where((item) => item != null).toList());

          isLoading = false;
        });
      } else {
        throw Exception('Failed to load reservation data');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching data: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUserIdAndData(); // ดึง user_id และข้อมูลการจองใน initState
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Padding(
          padding: EdgeInsets.all(15.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Request Status',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(1),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : reservations.isEmpty
                ? const Center(child: Text('No data available.'))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Table(
                        columnWidths: const {
                          0: FlexColumnWidth(1.5),
                          1: FlexColumnWidth(1),
                          2: FlexColumnWidth(1),
                          3: FlexColumnWidth(1),
                        },
                        children: [
                          _buildTableRow(
                              ['Date-Time \nReservation', 'Room', 'Status', 'Approver'],
                              isHeader: true),
                          for (var reservation in reservations)
                            _buildTableRow([
                              reservation['dateTime']?.toString() ?? 'N/A',
                              reservation['room']?.toString() ?? 'N/A',
                              reservation['status']?.toString() ?? 'N/A',
                              reservation['approver']?.toString() ?? 'N/A',
                            ]),
                        ],
                      ),
                    ],
                  ),
      ),
    );
  }

  TableRow _buildTableRow(List<String> cells, {bool isHeader = false}) {
    return TableRow(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey,
            width: 1.0,
          ),
        ),
      ),
      children: cells.map((cell) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            cell,
            style: TextStyle(
              fontSize: isHeader ? 14 : 12,
              fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
              color: _getCellColor(cell, isHeader),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getCellColor(String status, bool isHeader) {
    if (isHeader) return Colors.black;
    switch (status) {
      case 'approve':
        return Colors.green;
      case 'disapprove':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.black;
    }
  }
}
