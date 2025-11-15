import 'dart:convert';
import 'dart:io'; // สำหรับ File
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart'; // เพิ่มสำหรับเลือกรูป

class Reservation {
  String dateTime;
  String room;
  String username;
  String status;
  int id;
  File? profileImage; // เพิ่มตัวแปรเก็บรูป

  Reservation({
    required this.id,
    required this.dateTime,
    required this.room,
    required this.username,
    required this.status,
    this.profileImage,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    String formattedDate = json['booking_date'] != null
        ? DateFormat('yyyy-MM-dd').format(DateTime.parse(json['booking_date']))
        : 'N/A';

    return Reservation(
      id: json['id'],
      dateTime: formattedDate,
      room: json['room_name'],
      username: json['booked_by'],
      status: _getStatusText(json['status']),
    );
  }

  static String _getStatusText(int status) {
    switch (status) {
      case 1:
        return 'Approve';
      case 2:
        return 'Disapprove';
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

  Future<void> _fetchPendingReservations() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in or session expired')),
      );
      return;
    }

    final response = await http.get(
      Uri.parse('http://192.168.31.90:5554/pending'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);

      setState(() {
        reservations = data.map((e) => Reservation.fromJson(e)).toList();
      });
    } else {
      throw Exception('Failed to load reservations');
    }
  }

  Future<void> _changeStatus(Reservation reservation, String newStatus) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final userId = prefs.getInt('user_id');

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in or session expired')),
      );
      return;
    }

    final status = newStatus.toLowerCase();

    final response = await http.put(
      Uri.parse('http://192.168.31.90:5554/approve/${reservation.id}'),
      body: json.encode({
        'user_id': userId,
        'action': status,
      }),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      _fetchPendingReservations();
    } else {
      throw Exception('Failed to update status');
    }
  }

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

  // ฟังก์ชันเลือกรูปจากเครื่อง
  Future<void> _pickImage(Reservation reservation) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        reservation.profileImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading:false,
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
              scrollDirection: Axis.horizontal, // กันตารางล้นจอ
              child: DataTable(
                columnSpacing: 25.0,
                columns: const [
                  DataColumn(
                    label: Text(
                      'Profile',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Date-Time \nReservation',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Room',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Username',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Confirmation',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                rows: reservations.map((reservation) {
                  return DataRow(cells: [
                    DataCell(
                      GestureDetector(
                        onTap: () => _pickImage(reservation),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundImage: reservation.profileImage != null
                              ? FileImage(reservation.profileImage!)
                              : null,
                          child: reservation.profileImage == null
                              ? const Icon(Icons.add_a_photo, size: 18)
                              : null,
                        ),
                      ),
                    ),
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