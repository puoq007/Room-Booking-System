import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class Room {
  int roomId;
  String roomName;
  String size;
  String image;
  String slot1;
  String slot2;
  String slot3;
  String slot4;

  Room({
    required this.roomId,
    required this.roomName,
    required this.size,
    required this.image,
    required this.slot1,
    required this.slot2,
    required this.slot3,
    required this.slot4,
  });

  Room copyWith({
    String? slot1,
    String? slot2,
    String? slot3,
    String? slot4,
  }) {
    return Room(
      roomId: roomId,
      roomName: roomName,
      size: size,
      image: image,
      slot1: slot1 ?? this.slot1,
      slot2: slot2 ?? this.slot2,
      slot3: slot3 ?? this.slot3,
      slot4: slot4 ?? this.slot4,
    );
  }

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      roomId: json['room_id'] ?? 0,
      roomName: json['room_name'] ?? '',
      size: json['size']?.toString() ?? '',
      image: json['image'] != null && json['image'] is String
          ? 'http://192.168.1.173:5554${json['image']}' // Full URL for the image
          : 'assets/images/room.png', // Default image
      slot1: json['slot_1']?.toString() ?? '',
      slot2: json['slot_2']?.toString() ?? '',
      slot3: json['slot_3']?.toString() ?? '',
      slot4: json['slot_4']?.toString() ?? '',
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

class Stuhome extends StatefulWidget {
  final int userId;

  const Stuhome({Key? key, required this.userId}) : super(key: key);

  @override
  State<Stuhome> createState() => _ListroomState();
}

class _ListroomState extends State<Stuhome> {
  List<Room> rooms = [];
  bool isLoading = true;

  Future<void> fetchRooms() async {
    final response = await http.get(Uri.parse('http://192.168.1.173:5554/room'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      setState(() {
        rooms = data.map((json) => Room.fromJson(json)).toList();
        isLoading = false;
      });
    } else {
      showErrorMessage('Failed to load rooms');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchRooms();
  }

  Future<void> reserveRoom(int roomId, String slot) async {
    final userId = widget.userId.toString();
    try {
      final response = await http.post(
        Uri.parse('http://192.163.1.173:5554/reserve'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'room_id': roomId,
          'slot': slot,
          'borrowed_by': userId,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          final index = rooms.indexWhere((room) => room.roomId == roomId);
          if (index != -1) {
            final room = rooms[index];
            rooms[index] = room.copyWith(
              slot1: slot == 'slot_1' ? 'pending' : room.slot1,
              slot2: slot == 'slot_2' ? 'pending' : room.slot2,
              slot3: slot == 'slot_3' ? 'pending' : room.slot3,
              slot4: slot == 'slot_4' ? 'pending' : room.slot4,
            );
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reservation successful')),
        );
      } else {
        final errorResponse = json.decode(response.body);
        showErrorMessage(errorResponse['error'] ?? 'Failed to reserve room');
      }
    } catch (e) {
      showErrorMessage('Error: $e');
    }
  }

  void showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void showRoomDetails(Room room) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(room.roomName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              room.image.isNotEmpty
                  ? Image.network(
                      room.image,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.image_not_supported, size: 100),
                    )
                  : Icon(Icons.image_not_supported, size: 100),
              SizedBox(height: 20),
              Text('Size: ${room.getSizeText()}'),
              Divider(),
              Text('Available Slots:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              _buildSlotTile(room, 'Slot 1', room.slot1, 'slot_1'),
              _buildSlotTile(room, 'Slot 2', room.slot2, 'slot_2'),
              _buildSlotTile(room, 'Slot 3', room.slot3, 'slot_3'),
              _buildSlotTile(room, 'Slot 4', room.slot4, 'slot_4'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotTile(
      Room room, String title, String status, String slotKey) {
    Color buttonColor;
    String buttonText;

    // กำหนดสีและข้อความของปุ่มตามสถานะ
    switch (status) {
      case 'free':
        buttonColor = Colors.green;
        buttonText = 'Free';
        break;
      case 'pending':
        buttonColor = const Color.fromARGB(255, 255, 170, 0);
        buttonText = 'Pending';
        break;
      case 'disable':
      default:
        buttonColor = const Color.fromARGB(255, 255, 0, 0);
        buttonText = 'Disable';
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: ElevatedButton(
        onPressed: status == 'free'
            ? () {
                // กดปุ่มเพื่อจองห้อง
                Navigator.of(context).pop();
                reserveRoom(room.roomId, slotKey);
              }
            : null, // ปิดการใช้งานปุ่มสำหรับสถานะอื่น
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          disabledBackgroundColor: buttonColor.withOpacity(0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 255, 255, 255),
              ),
            ),
            Text(
              buttonText,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 0, 0, 0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool isRoomFull(Room room) {
    return room.slot1 != 'free' &&
        room.slot2 != 'free' &&
        room.slot3 != 'free' &&
        room.slot4 != 'free';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text('TODAY: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: rooms.length,
              itemBuilder: (context, index) {
                final room = rooms[index];
                return buildRoomBox(context, room);
              },
            ),
    );
  }

  Widget buildRoomBox(BuildContext context, Room room) {
    bool roomFull = isRoomFull(room);

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xfff6f1eb),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 150,
              height: 150,
              child: room.image.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: room.image,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) =>
                          Icon(Icons.image_not_supported),
                    )
                  : Icon(Icons.image_not_supported),
            ),
          ),
          const SizedBox(width: 30),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.roomName,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                Text('Size: ${room.getSizeText()}'),
                SizedBox(height: 10),
                if (roomFull)
                  ElevatedButton(
                    onPressed: null,
                    style: ElevatedButton.styleFrom(
                      disabledBackgroundColor: Colors.orange,
                    ),
                    child: Text('Fully Booked'),
                  )
                else
                  ElevatedButton(
                    onPressed: () => showRoomDetails(room),
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
