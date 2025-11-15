import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:project/Logo.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

class Appprofile extends StatefulWidget {
  const Appprofile({Key? key}) : super(key: key);

  @override
  State<Appprofile> createState() => _AppProfileScreenState();
}

class _AppProfileScreenState extends State<Appprofile> {
  final String baseUrl = 'http://192.168.31.90:5554'; // ✅ backend URL
  Map<String, dynamic> profileData = {};
  List<Map<String, dynamic>> historyData = [];
  String searchQuery = '';
  File? profileImage;

  @override
  void initState() {
    super.initState();
    getProfileAndHistory();
  }

  // ✅ เลือกรูปใหม่
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        profileImage = File(pickedFile.path);
      });
      await uploadProfileImage(profileImage!);
    }
  }

  // ✅ อัพโหลดรูปไป backend
  Future<void> uploadProfileImage(File image) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    var request = http.MultipartRequest(
      'POST',
      Uri.parse("$baseUrl/profile/upload"),
    );
    request.headers['authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('profile_image', image.path));

    var response = await request.send();

    if (response.statusCode == 200) {
      var respStr = await response.stream.bytesToString();
      var data = jsonDecode(respStr);
      setState(() {
        profileData['profile_image'] = data['profile_image'];
      });
    } else {
      debugPrint("Upload failed: ${response.statusCode}");
    }
  }

  // ✅ ดึงโปรไฟล์ + history
  Future<void> getProfileAndHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    try {
      // ดึงโปรไฟล์
      Uri profileUri = Uri.parse("$baseUrl/profile");
      final profileResponse = await http.get(
        profileUri,
        headers: {'authorization': 'Bearer $token'},
      );

      if (profileResponse.statusCode == 200) {
        final profile = jsonDecode(profileResponse.body);
        setState(() {
          profileData = profile;
          profileData['role'] = profile['role'] == 1
              ? 'student'
              : (profile['role'] == 2 ? 'approver' : 'staff');
        });
      }

      // ดึง history (ตรงนี้คุณเขียน endpoint เองได้นะ)
      Uri historyUri = Uri.parse("$baseUrl/information");
      final historyResponse = await http.get(
        historyUri,
        headers: {'authorization': 'Bearer $token'},
      );

      if (historyResponse.statusCode == 200) {
        final history = jsonDecode(historyResponse.body);
        setState(() {
          historyData = List<Map<String, dynamic>>.from(
            history.map((item) {
              String status = item['status'] == 1
                  ? 'approve'
                  : (item['status'] == 2 ? 'disapprove' : 'pending');

              String formattedDate = item['booking_date'] != null
                  ? DateFormat('yyyy-MM-dd').format(DateTime.parse(item['booking_date']))
                  : 'N/A';

              return {
                'dateTime': formattedDate,
                'room': item['room_name'] ?? 'N/A',
                'status': status,
                'borrowed_by': item['booked_by'] ?? 'Unknown',
              };
            }),
          );
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  List<Map<String, dynamic>> get filteredHistoryData {
    if (searchQuery.isEmpty) return historyData;
    return historyData.where((history) {
      final searchLower = searchQuery.toLowerCase();
      return history['dateTime']!.toLowerCase().contains(searchLower) ||
          history['room']!.toLowerCase().contains(searchLower) ||
          history['status']!.toLowerCase().contains(searchLower) ||
          history['borrowed_by']!.toLowerCase().contains(searchLower);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final profileImageUrl = profileData['profile_image'] != null
        ? "$baseUrl/profilePictures/${profileData['profile_image']}"
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: profileImageUrl != null
                        ? NetworkImage(profileImageUrl)
                        : null,
                    child: profileImageUrl == null
                        ? const Icon(Icons.add_a_photo, size: 28, color: Colors.grey)
                        : null,
                  ),
                ),
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
                    DataColumn(label: Text('Students')),
                    DataColumn(label: Text('Status')),
                  ],
                  rows: filteredHistoryData.map((history) {
                    return DataRow(
                      cells: [
                        DataCell(Text(history['dateTime'] ?? 'N/A')),
                        DataCell(Text(history['room'] ?? 'N/A')),
                        DataCell(Text(history['borrowed_by'] ?? 'N/A')),
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