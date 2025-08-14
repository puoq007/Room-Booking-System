import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:project/Logo.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StaffProfile extends StatefulWidget {
  const StaffProfile({Key? key}) : super(key: key);

  @override
  State<StaffProfile> createState() => _StaffProfileState();
}

class _StaffProfileState extends State<StaffProfile> {
  final String url = '192.168.1.173:5554'; // URL สำหรับ backend
  Map<String, String> profileData = {}; // ข้อมูลโปรไฟล์
  List<Map<String, dynamic>> historyData = []; // ข้อมูลประวัติการจอง
  String searchQuery = ''; // ข้อความค้นหา

  @override
  void initState() {
    super.initState();
    getProfileAndHistory();
  }

  // ฟังก์ชันดึงข้อมูลโปรไฟล์และประวัติการจอง
  Future<void> getProfileAndHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in")),
      );
      return;
    }

    try {
      // ดึงข้อมูลโปรไฟล์
      final profileUri = Uri.http(url, '/profile');
      final profileResponse = await http.get(
        profileUri,
        headers: {'authorization': 'Bearer $token'},
      );

      if (profileResponse.statusCode == 200) {
        final profile = jsonDecode(profileResponse.body);
        setState(() {
          profileData['user_name'] = profile['user_name'];
          profileData['role'] = _getRoleName(profile['role']);
        });
      } else {
        _showSnackBar("Failed to load profile data");
      }

      // ดึงข้อมูลประวัติการจอง
      final historyUri = Uri.http(url, '/information');
      final historyResponse = await http.get(
        historyUri,
        headers: {'authorization': 'Bearer $token'},
      );

      if (historyResponse.statusCode == 200) {
        final history = jsonDecode(historyResponse.body);

        setState(() {
          historyData = _parseHistoryData(history);
        });
      } else {
        _showSnackBar("Failed to load history data");
      }
    } catch (e) {
      debugPrint('Error: $e');
      _showSnackBar(e.toString());
    }
  }

  // ฟังก์ชันช่วยแปลง role เป็นข้อความ
  String _getRoleName(int role) {
    switch (role) {
      case 1:
        return 'Student';
      case 2:
        return 'Approver';
      case 3:
        return 'Staff';
      default:
        return 'Unknown';
    }
  }

  // ฟังก์ชันช่วยแปลงข้อมูลประวัติการจอง
  List<Map<String, dynamic>> _parseHistoryData(List<dynamic> data) {
    return List<Map<String, dynamic>>.from(data.map((item) {
      String status;
      if (item['status'] == 1) {
        status = 'Approve';
      } else if (item['status'] == 2) {
        status = 'Disapprove';
      } else {
        status = 'Pending';
      }

      String formattedDate = item['booking_date'] != null
          ? DateFormat('yyyy-MM-dd').format(DateTime.parse(item['booking_date']))
          : 'N/A';

      return {
        'dateTime': formattedDate,
        'room': item['room_name'] ?? 'N/A',
        'status': status,
        'borrowed_by': item['booked_by'] ?? 'Unknown',
        'approved_by': item['approved_by'] ?? 'N/A',
      };
    }));
  }

  // ฟังก์ชันแสดง Snackbar
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ดึงข้อมูลที่กรองตามคำค้นหา
  List<Map<String, dynamic>> get filteredHistoryData {
    if (searchQuery.isEmpty) return historyData;
    return historyData.where((history) {
      final searchLower = searchQuery.toLowerCase();
      return history.values.any((value) =>
          value.toString().toLowerCase().contains(searchLower));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Staff Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileSection(),
            const SizedBox(height: 20),
            _buildSearchBar(),
            const SizedBox(height: 16),
            _buildHistoryTable(),
          ],
        ),
      ),
    );
  }

  // ส่วนแสดงข้อมูลโปรไฟล์
  Widget _buildProfileSection() {
    return Row(
      children: [
        CircleAvatar(radius: 40, backgroundColor: Colors.grey[200]),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(profileData['user_name'] ?? '',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(profileData['role'] ?? ''),
          ],
        ),
        const Spacer(),
        ElevatedButton(
          onPressed: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.clear();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Logo()),
            );
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE0C9D1)),
          child: const Text('Logout', style: TextStyle(color: Colors.black)),
        ),
      ],
    );
  }

  // ส่วนแสดงช่องค้นหา
  Widget _buildSearchBar() {
    return TextField(
      onChanged: (value) => setState(() => searchQuery = value),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: 'Search',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
    );
  }

  // ส่วนแสดงตารางประวัติการจอง
  Widget _buildHistoryTable() {
    return Expanded(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 35.0,
          columns: const [
            DataColumn(label: Text('Date-Time\nReservation')),
            DataColumn(label: Text('Room')),
            DataColumn(label: Text('Students')),
            DataColumn(label: Text('Approved By')),
            DataColumn(label: Text('Status')),
          ],
          rows: filteredHistoryData.map((history) {
            return DataRow(
              cells: [
                DataCell(Text(history['dateTime'] ?? 'N/A')),
                DataCell(Text(history['room'] ?? 'N/A')),
                DataCell(Text(history['borrowed_by'] ?? 'N/A')),
                DataCell(Text(history['approved_by'] ?? 'N/A')),
                DataCell(Text(
                  history['status'] ?? 'N/A',
                  style: TextStyle(
                    color: history['status'] == 'Approve'
                        ? Colors.green
                        : (history['status'] == 'Disapprove'
                            ? Colors.red
                            : Colors.orange),
                  ),
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
