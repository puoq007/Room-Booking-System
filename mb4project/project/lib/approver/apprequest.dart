import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // นำเข้า intl package
import 'package:shared_preferences/shared_preferences.dart';

class Reservation {
  String dateTime;
  String room;
  String username;
  String status;
  int id;

  Reservation({
    required this.id,
    required this.dateTime,
    required this.room,
    required this.username,
    required this.status,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    // จัดรูปแบบวันที่โดยใช้ DateFormat
    String formattedDate = json['booking_date'] != null
        ? DateFormat('yyyy-MM-dd').format(DateTime.parse(json['booking_date']))
        : 'N/A';

    return Reservation(
      id: json['id'],
      dateTime: formattedDate, // ใช้วันที่ที่จัดรูปแบบแล้ว
      room: json['room_name'],
      username: json['booked_by'],
      status: _getStatusText(json['status']),
    );
  }

  static String _getStatusText(int status) {
    switch (status) {
      case 1:
        return 'Approved';
      case 2:
        return 'Disapproved';
      default:
        return 'Pending';
    }
  }
}

class Apprequest extends StatefulWidget {
  const Apprequest({super.key});

  @override
  State<Apprequest> createState() => _ApprequestState();
}

class _ApprequestState extends State<Apprequest> {
  List<Reservation> reservations = [];

  @override
  void initState() {
    super.initState();
    _fetchPendingReservations();
  }

  // Fetch Pending Reservations from the API
  Future<void> _fetchPendingReservations() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    // ตรวจสอบว่า token มีค่าหรือไม่
    if (token.isEmpty) {
      print('No token found. User might not be logged in.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in or session expired')),
      );
      return;
    }

    print('Fetching reservations with token: $token'); // Debug: print token

    final response = await http.get(
      Uri.parse('http://192.168.1.173:5554/pending'),
      headers: {
        'Authorization': 'Bearer $token', // ส่ง token ไปใน header
      },
    );

    // Debug: print response status and body
    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      print('Fetched data: $data'); // Debug: print fetched data

      setState(() {
        reservations = data.map((e) => Reservation.fromJson(e)).toList();
      });
    } else {
      print('Failed to load reservations: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception('Failed to load reservations');
    }
  }

  // Update the reservation status (Approve/Disapprove)
  Future<void> _changeStatus(Reservation reservation, String newStatus) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    // ดึง user_id จาก SharedPreferences หรือจากข้อมูลที่จำเป็น
    final userId =
        prefs.getInt('user_id'); // สมมติว่าเก็บ user_id ไว้ใน SharedPreferences

    if (userId == null) {
      print('User not logged in or user_id not found');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in or session expired')),
      );
      return;
    }

    // แปลงค่าของ newStatus เป็น "approve" หรือ "deny"
    final status = newStatus.toLowerCase(); // "approve" หรือ "deny"

    final response = await http.put(
      Uri.parse('http://192.168.1.173:5554/approve/${reservation.id}'),
      body: json.encode({
        'user_id': userId, // ส่ง user_id ไปที่ API
        'action': status, // ส่ง action ที่ต้องการ
      }),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // เพิ่ม token ใน header
      },
    );

    if (response.statusCode == 200) {
      print('Status changed successfully to: $newStatus');
      _fetchPendingReservations();
    } else {
      print('Failed to update status: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception('Failed to update status');
    }
  }

  // Function to get status color for the reservation status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approve':
        return Colors.green;
      case 'Disapprove':
        return Colors.red;
      case 'Pending':
        return Colors.orange;
      default:
        return const Color.fromRGBO(158, 158, 158, 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Padding(
          padding: EdgeInsets.all(15.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
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
      body: reservations.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: DataTable(
                columnSpacing: 25.0, // Reduced spacing between columns
                columns: const [
                  DataColumn(
                    label: Text(
                      'Date-Time \nReservation',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Room',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Username',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Confirmation',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                rows: reservations.map((reservation) {
                  return DataRow(cells: [
                    DataCell(Text(reservation.dateTime)),
                    DataCell(Text(reservation.room)),
                    DataCell(Text(reservation.username)),
                    DataCell(
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: reservation.status,
                          onChanged: (String? newValue) {
                            _changeStatus(reservation, newValue!);
                          },
                          dropdownColor: Colors.white,
                          items: <String>['Approve', 'Pending', 'Disapprove']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: _getStatusColor(value),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 5.0),
                                child: Text(
                                  value,
                                  style: const TextStyle(color: Colors.black),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          }).toList(),
                          style: const TextStyle(color: Colors.black),
                          iconSize: 20,
                          isExpanded: true,
                        ),
                      ),
                    ),
                  ]);
                }).toList(),
              ),
            ),
    );
  }
}
