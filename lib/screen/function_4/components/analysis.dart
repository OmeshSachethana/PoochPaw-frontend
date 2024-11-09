import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:poochpaw/core/utils/app_bar.dart';
import 'package:poochpaw/screen/common/components/blur_bg.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  _AnalysisScreenState createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _dogs = [];
  bool _isLoading = true;
  bool _isEmpty = false;

  int maleCount = 0;
  int femaleCount = 0;
  Map<String, int> breedCount = {};
  Map<String, int> locationCount = {};

  @override
  void initState() {
    super.initState();
    _fetchDogs();
  }

  Future<void> _fetchDogs() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('strayDogs').get();
      setState(() {
        _dogs = snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
        _isEmpty = _dogs.isEmpty;
        if (!_isEmpty) _analyzeData();
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching dogs: $e");
      setState(() {
        _isLoading = false;
        _isEmpty = true; // Treat fetch error as no data
      });
    }
  }

  void _analyzeData() {
    maleCount = _dogs.where((dog) => dog['gender'] == 'Male').length;
    femaleCount = _dogs.length - maleCount;

    for (var dog in _dogs) {
      // String breed = dog['breed'] ?? 'Unknown';
      String location = dog['location'] ?? 'Unknown';

      // breedCount[breed] = (breedCount[breed] ?? 0) + 1;
      locationCount[location] = (locationCount[location] ?? 0) + 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Dog Analysis',
        leadingImage: 'assets/icons/Back.png',
        onLeadingPressed: () => Navigator.of(context).pop(),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          BackgroundWithBlur(child: SizedBox.expand()),
          Container(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _isEmpty
                    ? _buildEmptyState()
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 90,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle('Gender Distribution'),
                            _buildCard(_buildGenderDistributionChart()),
                            // const SizedBox(height: 24),
                            // _buildSectionTitle('Top 5 Breeds'),
                            // _buildCard(_buildTopBreedsChart()),
                            const SizedBox(height: 24),
                            _buildSectionTitle('Dogs by Location'),
                            _buildCard(_buildLocationData()),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // Widget for empty state.
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pets, size: 100, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No data available for stray dogs.',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Try adding some records to the collection.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildCard(Widget child) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white.withOpacity(0.9),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: child,
      ),
    );
  }

  Widget _buildGenderDistributionChart() {
    return SizedBox(
      height: 220,
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(
              value: maleCount.toDouble(),
              title: 'Male',
              color: Colors.blueAccent,
              radius: 60,
              titleStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            PieChartSectionData(
              value: femaleCount.toDouble(),
              title: 'Female',
              color: Colors.pinkAccent,
              radius: 60,
              titleStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          sectionsSpace: 2,
          centerSpaceRadius: 40,
        ),
      ),
    );
  }

  Widget _buildTopBreedsChart() {
    List<BarChartGroupData> barGroups =
        breedCount.entries.take(5).toList().asMap().entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value.value.toDouble(),
            color: Colors.teal,
            width: 20,
            borderRadius: BorderRadius.circular(8),
          ),
        ],
      );
    }).toList();

    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          barGroups: barGroups,
          gridData: FlGridData(show: true),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, _) => Text(
                  value.toInt().toString(),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, _) {
                  String breed = breedCount.keys.elementAt(value.toInt());
                  String truncatedBreed = breed.length > 10
                      ? '${breed.substring(0, 10)}...'
                      : breed;

                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Transform.rotate(
                      angle: -0.45,
                      child: Text(
                        truncatedBreed,
                        style: const TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationData() {
    return Column(
      children: locationCount.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                entry.key,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${entry.value}',
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
