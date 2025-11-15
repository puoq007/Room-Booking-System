import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final String url = '192.168.31.90:5554';
  bool _isLoading = true;

  Map<String, dynamic> dashboard = {
    "totalRooms": 0,
    "totalSlots": 0,
    "freeSlots": 0,
    "pendingSlots": 0,
    "reservedSlots": 0,
    "disabledSlots": 0
  };

  @override
  void initState() {
    super.initState();
    getDashboard();
  }

  Future<void> getDashboard() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    setState(() {
      _isLoading = true;
    });

    try {
      final uri = Uri.http(url, '/dashboard');
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'authorization': 'Bearer $token',
      };

      final response =
          await http.get(uri, headers: headers).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          dashboard['totalRooms'] = int.tryParse(data['totalRooms'].toString()) ?? 0;
          dashboard['totalSlots'] = int.tryParse(data['totalSlots']?.toString() ?? '0') ?? 0;
          dashboard['freeSlots'] = int.tryParse(data['freeSlots'].toString()) ?? 0;
          dashboard['pendingSlots'] =
              int.tryParse(data['pendingSlots']?.toString() ?? '0') ?? 0;
          dashboard['reservedSlots'] = int.tryParse(data['reservedSlots'].toString()) ?? 0;
          dashboard['disabledSlots'] = int.tryParse(data['disabledSlots']?.toString() ?? '0') ?? 0;
          _isLoading = false;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Server Error: ${response.statusCode}')));
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Network Error: $e')));
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget buildInfoCard(String title, dynamic value, Color color) {
    return Expanded(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: color.withOpacity(0.15),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          child: Column(
            children: [
              Text(
                title,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                value.toString(),
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> buildChartSections() {
    final sections = [
      {"title": "Free Slot", "key": "freeSlots", "color": Colors.green},
      {"title": "Reserved", "key": "reservedSlots", "color": Colors.orange},
      {"title": "Disabled", "key": "disabledSlots", "color": Colors.red},
      {"title": "Pending", "key": "pendingSlots", "color": Colors.purple},
    ];

    return sections.map((s) {
      final value = double.tryParse(dashboard[s["key"]].toString()) ?? 0;
      return PieChartSectionData(
        color: s["color"] as Color,
        value: value, 
        title: value.toInt().toString(),
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        showTitle: true,
        titlePositionPercentageOffset: 0.55,
      );
    }).toList();
  }

  Widget buildLegend(String title, Color color, int value) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 8),
        Text('$title: $value', style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: getDashboard,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      buildInfoCard("Total Room", dashboard['totalRooms'], Colors.blue),
                      const SizedBox(width: 10),
                      buildInfoCard("Total Slot", dashboard['totalSlots'], Colors.teal),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      buildInfoCard("Free Slot", dashboard['freeSlots'], Colors.green),
                      const SizedBox(width: 10),
                      buildInfoCard("Reserved", dashboard['reservedSlots'], Colors.orange),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      buildInfoCard("Disabled", dashboard['disabledSlots'], Colors.red),
                      const SizedBox(width: 10),
                      buildInfoCard("Pending", dashboard['pendingSlots'], Colors.purple),
                    ],
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    height: 320,
                    child: PieChart(
                      PieChartData(
                        sections: buildChartSections(),
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        borderData: FlBorderData(show: false),
                        pieTouchData: PieTouchData(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildLegend("Free Slot", Colors.green, dashboard['freeSlots']),
                      buildLegend("Reserved", Colors.orange, dashboard['reservedSlots']),
                      buildLegend("Disabled", Colors.red, dashboard['disabledSlots']),
                      buildLegend("Pending", Colors.purple, dashboard['pendingSlots']),
                    ],
                  )
                ],
              ),
            ),
    );
  }
}