import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

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

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      roomId: json['room_id'] ?? 0,
      roomName: json['room_name'] ?? '',
      size: json['size']?.toString() ?? '',
      image: json['image'] != null && json['image'] is String
          ? 'http://192.168.1.173:5554${json['image']}' // Full URL for the image
          : 'assets/images/room.png', // Default image
      slot1: json['slot_1'].toString(),
      slot2: json['slot_2'].toString(),
      slot3: json['slot_3'].toString(),
      slot4: json['slot_4'].toString(),
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

class Staffhome extends StatefulWidget {
  final String token;

  const Staffhome({Key? key, required this.token}) : super(key: key);

  @override
  State<Staffhome> createState() => _StaffHomeState();
}

class _StaffHomeState extends State<Staffhome> {
  List<Room> rooms = [];
  bool isLoading = true;

  Future<void> fetchRooms() async {
    try {
      print('Fetching rooms...');
      final response = await http.get(
        Uri.parse('http://192.168.1.173:5554/room'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      print('Fetch rooms response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        print('Rooms fetched successfully: ${data.length} rooms');

        setState(() {
          rooms = data.map((json) => Room.fromJson(json)).toList();
          isLoading = false;
        });
      } else {
        final errorBody = response.body;
        print('Failed to fetch rooms: $errorBody');
        showErrorMessage('Failed to load rooms: $errorBody');
      }
    } catch (e) {
      print('Error occurred while fetching rooms: $e');
      showErrorMessage('An error occurred while loading rooms: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchRooms();
  }

  void showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void addRoom() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddRoomDialog(token: widget.token);
      },
    ).then((_) {
      print('Dialog closed. Refreshing rooms...');
      fetchRooms(); // Refresh rooms after adding a new one
    });
  }

  void editRoom(Room room) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EditRoomDialog(room: room);
      },
    ).then((_) {
      fetchRooms(); // รีเฟรชข้อมูลห้องหลังจากแก้ไขห้องสำเร็จ
    });
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
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: addRoom,
            tooltip: 'Add Room',
          ),
        ],
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
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.roomName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  'Size: ${room.getSizeText()}',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                if (roomFull)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      'No Slots Available',
                      style: TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: ElevatedButton(
                      onPressed: () => editRoom(room),
                      child: Text('Edit Room'),
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

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

class EditRoomDialog extends StatefulWidget {
  final Room room;

  const EditRoomDialog({Key? key, required this.room}) : super(key: key);

  @override
  _EditRoomDialogState createState() => _EditRoomDialogState();
}

class _EditRoomDialogState extends State<EditRoomDialog> {
  late Room room;
  late TextEditingController _roomNameController;
  String? _token;

  @override
  void initState() {
    super.initState();
    room = widget.room; // ดึงข้อมูลห้องที่ส่งมา
    _roomNameController = TextEditingController(
        text: room.roomName); // สร้าง controller สำหรับ roomName
    print(
        "Initial room data: ${room.roomName}, ${room.slot1}, ${room.slot2}"); // Debugging print
    _loadToken(); // โหลดโทเค็นจาก SharedPreferences
  }

  @override
  void dispose() {
    _roomNameController.dispose(); // ทำลาย controller เมื่อไม่ใช้
    super.dispose();
  }

  // ฟังก์ชันเพื่อโหลดโทเค็นจาก SharedPreferences
  Future<void> _loadToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token'); // ดึงโทเค็นจาก SharedPreferences
    print("Loaded token: $_token");
  }

  // ฟังก์ชันเพื่อบันทึกการแก้ไขข้อมูล
  Future<void> saveChanges() async {
    try {
      print("Saving changes for room: ${room.roomName}");

      // ตรวจสอบว่าโทเค็นมีค่าหรือไม่
      if (_token == null || _token!.isEmpty) {
        showErrorMessage('No valid token found. Please login again.');
        return;
      }

      final response = await http.put(
        Uri.parse('http://192.168.1.173:5554/room/${room.roomId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token', // ส่งโทเค็นใน headers
        },
        body: json.encode({
          'room_name': room.roomName,
          'size': room.size,
          'image': room.image, // ส่งค่า image กลับไปในคำขอ
          'slot_1': room.slot1,
          'slot_2': room.slot2,
          'slot_3': room.slot3,
          'slot_4': room.slot4,
        }),
      );

      print("API Response status code: ${response.statusCode}");

      if (response.statusCode == 200) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Room updated successfully')),
        );
      } else if (response.statusCode == 401) {
        showErrorMessage('Unauthorized: Please log in again.');
        Navigator.pushReplacementNamed(
            context, '/login'); // เปลี่ยนเส้นทางไปที่หน้าล็อกอิน
      } else {
        showErrorMessage(
            'Failed to update room. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print("Error while saving room: $e");
      showErrorMessage('Error: $e');
    }
  }

  // ฟังก์ชันแสดง error message
  void showErrorMessage(String message) {
    print("Error message: $message"); // Debugging print
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ฟังก์ชันในการสร้างรายการ dropdown สำหรับ slot
  List<DropdownMenuItem<String>> buildSlotDropdown(String slot) {
    print("Building dropdown for slot: $slot"); // Debugging print

    // กรณีที่ slot เป็น "pending" หรือ "reserve" จะไม่ให้แสดง dropdown
    if (slot == 'pending' || slot == 'reserve') {
      return [
        DropdownMenuItem<String>(
          value: slot,
          child: Text(
            slot,
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
        ),
      ];
    }

    return [
      DropdownMenuItem<String>(
        value: 'free',
        child: Text(
          'free',
          style: TextStyle(
            color: Colors.green, // เปลี่ยนสีข้อความเป็นสีเขียว
            fontWeight: FontWeight.bold, // ทำให้ข้อความหนาขึ้น
          ),
        ),
      ),
      DropdownMenuItem<String>(
        value: 'disable',
        child: Text(
          'disable',
          style: TextStyle(
            color: Colors.red, // เปลี่ยนสีข้อความเป็นสีแดง
            fontWeight: FontWeight.bold, // ทำให้ข้อความหนาขึ้น
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    print(
        "Building EditRoomDialog UI for room: ${room.roomName}"); // Debugging print
    return AlertDialog(
      title: Text('Edit Room: ${room.roomName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // TextField สำหรับชื่อห้อง
            TextField(
              controller: _roomNameController,
              onChanged: (value) {
                setState(() {
                  room.roomName = value;
                  print(
                      "Updated room name: ${room.roomName}"); // Debugging print
                });
              },
              decoration: InputDecoration(labelText: 'Room Name'),
            ),
            // Dropdown สำหรับเลือก slot1
            DropdownButton<String>(
              value: room.slot1,
              onChanged: (newValue) {
                setState(() {
                  room.slot1 = newValue!;
                  print("Updated slot1: ${room.slot1}"); // Debugging print
                });
              },
              items: buildSlotDropdown(room.slot1),
            ),
            // Dropdown สำหรับเลือก slot2
            DropdownButton<String>(
              value: room.slot2,
              onChanged: (newValue) {
                setState(() {
                  room.slot2 = newValue!;
                  print("Updated slot2: ${room.slot2}"); // Debugging print
                });
              },
              items: buildSlotDropdown(room.slot2),
            ),
            // Dropdown สำหรับเลือก slot3
            DropdownButton<String>(
              value: room.slot3,
              onChanged: (newValue) {
                setState(() {
                  room.slot3 = newValue!;
                  print("Updated slot3: ${room.slot3}"); // Debugging print
                });
              },
              items: buildSlotDropdown(room.slot3),
            ),
            // Dropdown สำหรับเลือก slot4
            DropdownButton<String>(
              value: room.slot4,
              onChanged: (newValue) {
                setState(() {
                  room.slot4 = newValue!;
                  print("Updated slot4: ${room.slot4}"); // Debugging print
                });
              },
              items: buildSlotDropdown(room.slot4),
            ),
          ],
        ),
      ),
      actions: [
        // ปุ่ม Cancel
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            print("Dialog closed without saving"); // Debugging print
          },
          child: Text('Cancel'),
          style: TextButton.styleFrom(
            foregroundColor: const Color.fromARGB(
                200, 244, 67, 54), // เปลี่ยนสีข้อความของปุ่มเป็นสีแดง
          ),
        ),
        // ปุ่ม Save Changes
        ElevatedButton(
          onPressed: saveChanges,
          child: Text('Save Changes'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.blue, // กำหนดสีของข้อความเป็นสีขาว
          ),
        )
      ],
    );
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

class AddRoomDialog extends StatefulWidget {
  final String token;

  const AddRoomDialog({Key? key, required this.token}) : super(key: key);

  @override
  State<AddRoomDialog> createState() => _AddRoomDialogState();
}

class _AddRoomDialogState extends State<AddRoomDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _roomNameController = TextEditingController();
  String _selectedSize = '1'; // Default to Small
  Map<String, String> _slots = {
    'slot1': 'free',
    'slot2': 'free',
    'slot3': 'free',
    'slot4': 'free',
  };
  XFile? _image;

  // ฟังก์ชันสำหรับการเลือกรูปภาพ
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      setState(() {
        _image = pickedImage;
      });
      print('Image selected: ${_image!.path}');
    } else {
      print('No image selected');
    }
  }

  // ฟังก์ชันสำหรับการส่งฟอร์ม
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (widget.token.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Authentication token is missing. Please log in again.')),
        );
        return;
      }

      if (_image == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('กรุณาเลือกรูปภาพ')),
        );
        return;
      }

      try {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('http://192.168.1.173:5554/add-room'),
        );

        request.headers.addAll({
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'multipart/form-data',
        });

        // ส่งข้อมูลฟิลด์ room_name และ size
        request.fields['room_name'] = _roomNameController.text;
        request.fields['size'] = _selectedSize;

        // **ส่งค่าของ slot_1 ถึง slot_4 ไปใน request**
        request.fields['slot_1'] =
            _slots['slot1'] ?? 'free'; // กำหนดค่า default หากเป็น null
        request.fields['slot_2'] = _slots['slot2'] ?? 'free';
        request.fields['slot_3'] = _slots['slot3'] ?? 'free';
        request.fields['slot_4'] = _slots['slot4'] ?? 'free';

        // เพิ่มรูปภาพลงใน request
        request.files
            .add(await http.MultipartFile.fromPath('image', _image!.path));
        print(request.fields);
        print(request.files);

        final response = await request.send();

        if (response.statusCode == 200) {
          final responseBody = await response.stream.bytesToString();
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เพิ่มห้องสำเร็จ!')),
          );
        } else {
          final errorBody = await response.stream.bytesToString();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $errorBody')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    // ตั้งค่าเริ่มต้นให้กับ slot_1, slot_2, slot_3, และ slot_4
    _slots = {
      'slot_1': 'free',
      'slot_2': 'free',
      'slot_3': 'free',
      'slot_4': 'free',
    };
    print(_slots); // ดูค่าที่เก็บใน _slots

    return AlertDialog(
        title: Text('Add New Room'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _roomNameController,
                  decoration: InputDecoration(labelText: 'Room Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a room name';
                    }
                    return null;
                  },
                ),
                DropdownButtonFormField<String>(
                  value: _selectedSize,
                  decoration: InputDecoration(labelText: 'Room Size'),
                  items: [
                    DropdownMenuItem(value: '1', child: Text('Small')),
                    DropdownMenuItem(value: '2', child: Text('Medium')),
                    DropdownMenuItem(value: '3', child: Text('Large')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedSize = value!;
                    });
                  },
                ),
                Column(
                  children: _slots.keys.map((slotKey) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(slotKey.toUpperCase().replaceAll('_', ': ')),
                        DropdownButton<String>(
                          value: _slots[slotKey],
                          items: [
                            DropdownMenuItem(
                                value: 'free', child: Text('Free')),
                            DropdownMenuItem(
                                value: 'disable', child: Text('Disable')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _slots[slotKey] = value!;
                            });
                          },
                        ),
                      ],
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                _image == null
                    ? TextButton(
                        onPressed: _pickImage, child: Text('Upload Image'))
                    : Image.file(File(_image!.path), height: 100, width: 100),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red, // เปลี่ยนสีข้อความของปุ่มเป็นสีแดง
            ),
          ),
          ElevatedButton(
            onPressed: _submitForm,
            child: Text('Add Room'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.blue, // เปลี่ยนสีข้อความของปุ่มเป็นสีขาว
            ),
          ),
        ]);
  }
}
