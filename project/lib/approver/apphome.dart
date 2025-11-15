import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class Room {
  final int roomId;
  final String name;
  final String imagePath;
  final String size;
  final Map<String, String> timeSlotStatus;

  Room({
    required this.roomId,
    required this.name,
    required this.imagePath,
    required this.size,
    required this.timeSlotStatus,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      roomId: json['room_id'] ?? 0,
      name: json['room_name']?.toString() ?? 'Unknown Room',
      imagePath: json['image']?.toString() ?? '',  // ใช้ค่าเริ่มต้นที่เป็นค่าว่าง
      size: json['size']?.toString() ?? 'Unknown',
      timeSlotStatus: {
        '08:00 - 10:00': json['slot_1']?.toString().toLowerCase() ?? 'unknown',
        '10:00 - 12:00': json['slot_2']?.toString().toLowerCase() ?? 'unknown',
        '13:00 - 15:00': json['slot_3']?.toString().toLowerCase() ?? 'unknown',
        '15:00 - 17:00': json['slot_4']?.toString().toLowerCase() ?? 'unknown',
      },
    );
  }

    String getSizeText() {
    switch (size) {
      case '1':
        return 'Small';
      case '2':
        return 'Medium';
      case '3':
        return 'Large';
      default:
        return 'Unknown';
    }
  }
}

class Apphome extends StatefulWidget {
  const Apphome({super.key});

  @override
  State<Apphome> createState() => _ApphomeState();
}

class _ApphomeState extends State<Apphome> {
  final List<Widget> _pages = [Listroom()];
  int _currentIndex = 0;

  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String todayDate = DateFormat('dd/MM/yyyy').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('TODAY: $todayDate'),
      ),
      body: _pages[_currentIndex],
    );
  }
}

class Listroom extends StatefulWidget {
  @override
  _ListroomState createState() => _ListroomState();
}

class _ListroomState extends State<Listroom> {
  List<Room> rooms = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchRooms();
  }

  Future<void> fetchRooms() async {
    const String apiUrl = 'http://192.168.31.90:5554/room'; // URL API
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> roomData = json.decode(response.body);
        print(roomData); // ตรวจสอบข้อมูล JSON ที่ได้รับ
        setState(() {
          rooms = roomData.map((data) => Room.fromJson(data)).toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load rooms');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString(); // เก็บข้อความผิดพลาด
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching rooms: $e')),
      );
    }
  }

  bool isRoomFull(Room room) {
    // ตรวจสอบว่า room เต็มหรือไม่
    return room.timeSlotStatus.values.every((status) {
      return status != 'free' && status != 'available';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(errorMessage, style: TextStyle(color: Colors.red)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: fetchRooms,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.all(10),
      children: rooms.map((room) => buildRoomBox(context, room)).toList(),
    );
  }

  Widget buildRoomBox(BuildContext context, Room room) {
    bool roomFull = isRoomFull(room);

    // ตรวจสอบ URL ของภาพใน log
    print('image URL: ${room.imagePath}');

    // Base URL สำหรับรวมกับ path ของรูป
    String imageUrl = 'http://192.168.31.90:5554${room.imagePath}';


    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Color(0xfff6f1eb),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 150, // ปรับขนาดให้พอดีกับการแสดงผล
              height: 150, // ปรับขนาดให้พอดีกับการแสดงผล
              child: room.imagePath.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl, // URL ที่สมบูรณ์
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => Image.asset('assets/images/room.png', fit: BoxFit.cover),
                    )
                  : Image.asset('assets/images/room.png', fit: BoxFit.cover), // ใช้รูปเริ่มต้นเมื่อไม่มีภาพ
            ),
          ),
          const SizedBox(width: 30),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ชื่อห้อง
                Text(
                  room.name,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                // ขนาดห้อง
                Text('Size: ${room.getSizeText()}',
                    style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 10),
                // ถ้าห้องเต็ม
                if (roomFull)
                  ElevatedButton(
                    onPressed: null,
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(150, 40),
                      disabledBackgroundColor: Colors.orange,
                    ),
                    child: const Text(
                      'Full',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                else
                  ElevatedButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (BuildContext alert) {
                          return Container(
                            
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // แสดงชื่อห้องใน modal
                                Text(
                                  room.name,
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 10),
                                // แสดงขนาดห้องใน modal
                                Text('Size: ${room.getSizeText()}'),
                                const SizedBox(height: 20),
                                const Text(
                                  'Available Time Slots:',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                // แสดงเวลาในช่องว่างที่มีสถานะ
                                ...room.timeSlotStatus.entries.map(
                                  (entry) =>
                                      Text('${entry.key}: ${entry.value}'),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(150, 40),
                      backgroundColor: Colors.green,
                    ),
                    child: const Text(
                      'View',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
