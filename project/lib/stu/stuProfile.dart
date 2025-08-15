import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:project/Logo.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Stuprofile extends StatefulWidget {
  const Stuprofile({Key? key}) : super(key: key);

  @override
  State<Stuprofile> createState() => _StuProfileScreenState();
}

class _StuProfileScreenState extends State<Stuprofile> {
  final String url = '192.168.1.173:5554'; // แก้ไข URL ตาม backend ของคุณ
  Map<String, String> profileData = {};
  List<Map<String, dynamic>> historyData = [];
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    getProfileAndHistory();
  }

  // ดึงข้อมูลโปรไฟล์และประวัติการจองจาก API
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
      Uri profileUri = Uri.http(url, '/profile');
      final profileResponse = await http.get(
        profileUri,
        headers: {'authorization': 'Bearer $token'},
      );

      if (profileResponse.statusCode == 200) {
        final profile = jsonDecode(profileResponse.body);
        setState(() {
          profileData['user_name'] = profile['user_name'];
          profileData['role'] = profile['role'] == 1
              ? 'student'
              : (profile['role'] == 2 ? 'approver' : 'staff');
        });
      } else {
        debugPrint('Error loading profile: ${profileResponse.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load profile data")),
        );
      }

      // ดึงข้อมูลประวัติการจอง
      Uri historyUri = Uri.http(url, '/information');
      final historyResponse = await http.get(
        historyUri,
        headers: {'authorization': 'Bearer $token'},
      );

      if (historyResponse.statusCode == 200) {
        final history = jsonDecode(historyResponse.body);

        setState(() {
          historyData = List<Map<String, dynamic>>.from(
            history.where((item) => item['status'] != 0).map((item) {
              String status;
              if (item['status'] == 1) {
                status = 'approve';
              } else if (item['status'] == 2) {
                status = 'disapprove';
              } else {
                status = 'pending';
              }

              String formattedDate = item['booking_date'] != null
                  ? DateFormat('yyyy-MM-dd').format(DateTime.parse(item['booking_date']))
                  : 'N/A';

              return {
                'dateTime': formattedDate,
                'room': item['room_name']?.toString() ?? 'N/A',
                'status': status,
                'approver': item['approver_by']?.toString() ?? 'N/A',
              };
            }),
          );
        });
      } else {
        debugPrint('Error loading history: ${historyResponse.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load history data")),
        );
      }
    } catch (e) {
      debugPrint('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  List<Map<String, dynamic>> get filteredHistoryData {
    if (searchQuery.isEmpty) return historyData;
    return historyData.where((history) {
      final searchLower = searchQuery.toLowerCase();
      return history['dateTime']!.toLowerCase().contains(searchLower) ||
          history['room']!.toLowerCase().contains(searchLower) ||
          history['status']!.toLowerCase().contains(searchLower) ||
          history['approver']!.toLowerCase().contains(searchLower);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
            ),
            const SizedBox(height: 20),
            const Text('History', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 35.0,
                  columns: const [
                    DataColumn(label: Text('Date-Time \nReservation')),
                    DataColumn(label: Text('Room')),
                    DataColumn(label: Text('Approver')),
                    DataColumn(label: Text('Status')),
                  ],
                  rows: filteredHistoryData.map((history) {
                    return DataRow(
                      cells: [
                        DataCell(Text(history['dateTime'] ?? 'N/A')),
                        DataCell(Text(history['room'] ?? 'N/A')),
                        DataCell(Text(history['approver'] ?? 'N/A')),
                        DataCell(Text(
                          history['status'] ?? 'N/A',
                          style: TextStyle(
                            color: history['status'] == 'approve'
                                ? Colors.green
                                : (history['status'] == 'disapprove' ? Colors.red : Colors.orange),
                          ),
                        )),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
