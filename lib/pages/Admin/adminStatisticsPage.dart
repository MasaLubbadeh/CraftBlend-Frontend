import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../configuration/config.dart';

class AdminStatisticsPage extends StatefulWidget {
  const AdminStatisticsPage({super.key});

  @override
  _AdminStatisticsPageState createState() => _AdminStatisticsPageState();
}

class _AdminStatisticsPageState extends State<AdminStatisticsPage> {
  List<Map<String, dynamic>> cityData = [];
  Map<String, dynamic>? statisticsData;
  bool isLoadingCities = true;
  bool isLoadingStatistics = true;
  Map<String, dynamic>? topStoreData;

  @override
  void initState() {
    super.initState();
    fetchCityStatistics();
    fetchGeneralStatistics();
    fetchTopStore(); // Fetch top store
  }

  Future<void> fetchTopStore() async {
    try {
      final response = await http.get(Uri.parse(getMostRatedStore));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          topStoreData = data['data'];
        });
      } else {
        throw Exception('Failed to load top store');
      }
    } catch (e) {
      print('Error fetching top store: $e');
    }
  }

  Future<void> fetchCityStatistics() async {
    try {
      final response = await http.get(Uri.parse(getCityStatistics));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          cityData = List<Map<String, dynamic>>.from(data['data']);
          isLoadingCities = false;
        });
      } else {
        throw Exception('Failed to load city statistics');
      }
    } catch (e) {
      print('Error fetching city statistics: $e');
      setState(() {
        isLoadingCities = false;
      });
    }
  }

  Future<void> fetchGeneralStatistics() async {
    try {
      final response = await http.get(Uri.parse(getUserStoreStatistics));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          statisticsData = data['data'];
          isLoadingStatistics = false;
        });
      } else {
        throw Exception('Failed to load general statistics');
      }
    } catch (e) {
      print('Error fetching general statistics: $e');
      setState(() {
        isLoadingStatistics = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double appBarHeight = MediaQuery.of(context).size.height * 0.1;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: myColor,
        elevation: 0,
        toolbarHeight: appBarHeight,
        title: const Text(
          'Statistics',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoadingCities || isLoadingStatistics
          ? const Center(child: CircularProgressIndicator())
          : _buildStatisticsContent(),
    );
  }

  Widget _buildStatisticsContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Percentage of Stores by City',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: myColor),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200, // Fixed height for the chart
                      child: PieChart(
                        PieChartData(
                          sections: cityData
                              .map((city) => PieChartSectionData(
                                    value: double.parse(city['percentage']),
                                    title: '${city['percentage']}%',
                                    color: Colors.primaries[
                                        cityData.indexOf(city) %
                                            Colors.primaries.length],
                                    radius: 60,
                                    titleStyle: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                  ))
                              .toList(),
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildLegend(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              color: myColor2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'General Statistics',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: myColor),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatisticIcon(
                            Icons.person,
                            '${statisticsData?['totalUsers'] ?? 0}',
                            'Total Users'),
                        _buildStatisticIcon(
                            Icons.store,
                            '${statisticsData?['totalStores'] ?? 0}',
                            'Total Stores'),
                        _buildStatisticIcon(
                            Icons.star,
                            '${statisticsData?['topUser']?['numberOfOrders'] ?? 0}',
                            'Top User Orders'),
                      ],
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Top User',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: myColor),
                    ),
                    Divider(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.account_circle,
                            color: myColor, size: 30),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            ' ${statisticsData?['topUser']?['firstName'] ?? 'N/A'} ${statisticsData?['topUser']?['lastName'] ?? 'N/A'}',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: myColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.phone, color: myColor, size: 30),
                        const SizedBox(width: 8),
                        Text(
                          'Phone: ${statisticsData?['topUser']?['phoneNumber'] ?? 'N/A'}',
                          style:
                              const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.email, color: myColor, size: 30),
                        const SizedBox(width: 8),
                        Text(
                          'Email: ${statisticsData?['topUser']?['email'] ?? 'N/A'}',
                          style:
                              const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Top Store',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: myColor),
                    ),
                    Divider(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.store, color: myColor, size: 30),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${topStoreData?['storeName'] ?? 'N/A'}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: myColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.phone, color: myColor, size: 30),
                        const SizedBox(width: 8),
                        Text(
                          'Phone: ${topStoreData?['phoneNumber'] ?? 'N/A'}',
                          style:
                              const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.email, color: myColor, size: 30),
                        const SizedBox(width: 8),
                        Text(
                          'Email: ${topStoreData?['contactEmail'] ?? 'N/A'}',
                          style:
                              const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.receipt_long,
                            color: myColor, size: 30),
                        const SizedBox(width: 8),
                        Text(
                          'Received Orders: ${topStoreData?['numberOfReceivedOrders'] ?? 'N/A'}',
                          style:
                              const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'rating',
                          style: const TextStyle(fontSize: 14, color: myColor),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          children: List.generate(
                            (topStoreData?['rating']?['average'] ?? 0).toInt(),
                            (index) => const Icon(Icons.star,
                                color: Colors.amber, size: 20),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${topStoreData?['rating']?['average']?.toStringAsFixed(1) ?? 'N/A'})',
                          style:
                              const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: cityData.map((city) {
        final color =
            Colors.primaries[cityData.indexOf(city) % Colors.primaries.length];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                city['name'],
                style: const TextStyle(fontSize: 14, color: myColor),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatisticIcon(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: myColor, size: 40),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: myColor),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w400, color: Colors.grey),
        ),
      ],
    );
  }
}
