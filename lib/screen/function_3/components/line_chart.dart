import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class HeartbeatChart extends StatefulWidget {
  final String petId;

  HeartbeatChart({required this.petId});

  @override
  _HeartbeatChartState createState() => _HeartbeatChartState();
}

class _HeartbeatChartState extends State<HeartbeatChart> {
  List<_HeartbeatData> data = [];
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    setupRealTimeListener();
  }

  void setupRealTimeListener() {
    final dbRef = FirebaseDatabase.instance
        .ref()
        .child(widget.petId)
        .child('collar_data');

    dbRef.onValue.listen((event) async {
      final collarData = event.snapshot.value as Map<dynamic, dynamic>?;

      if (collarData != null) {
        await processCollarData(collarData);
      } else {
        setState(() {
          isLoading = false;
          hasError = true;
        });
      }
    }).onError((error) {
      setState(() {
        isLoading = false;
        hasError = true;
      });
      print('Error listening to data: $error');
    });
  }

  Future<void> processCollarData(Map<dynamic, dynamic> collarData) async {
    Map<DateTime, List<double>> dailyHeartRates = {};
    List<double> accelXValues = [];
    List<double> accelYValues = [];
    List<double> accelZValues = [];

    try {
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(Duration(days: 7));

      collarData.forEach((node, minuteData) {
        try {
          if (node != 'battery_level') {
            final DateTime timestamp = _parseCustomDateTime(node.toString());

            if (timestamp.isAfter(sevenDaysAgo) && timestamp.isBefore(now)) {
              final dateKey =
                  DateTime(timestamp.year, timestamp.month, timestamp.day);
              final List<dynamic>? secondDataList =
                  minuteData as List<dynamic>?;

              if (secondDataList != null) {
                for (var secondData in secondDataList) {
                  final List<dynamic>? secondDataValues =
                      secondData as List<dynamic>?;
                  if (secondDataValues != null && secondDataValues.isNotEmpty) {
                    final double? heartbeat =
                        double.tryParse(secondDataValues[1].toString());
                    if (heartbeat != null) {
                      dailyHeartRates
                          .putIfAbsent(dateKey, () => [])
                          .add(heartbeat);
                    }

                    if (secondDataValues.length > 4) {
                      final double? accelX =
                          double.tryParse(secondDataValues[2].toString());
                      final double? accelY =
                          double.tryParse(secondDataValues[3].toString());
                      final double? accelZ =
                          double.tryParse(secondDataValues[4].toString());

                      if (accelX != null && accelY != null && accelZ != null) {
                        accelXValues.add(accelX);
                        accelYValues.add(accelY);
                        accelZValues.add(accelZ);
                      }
                    }
                  }
                }
              }
            }
          }
        } catch (e) {
          print('Error parsing node key as DateTime: $node, Error: $e');
        }
      });

      List<_HeartbeatData> tempData = [];
      dailyHeartRates.forEach((date, heartRates) {
        if (heartRates.isNotEmpty) {
          double averageHeartRate =
              heartRates.reduce((a, b) => a + b) / heartRates.length;
          tempData.add(_HeartbeatData(date, averageHeartRate));
        }
      });

      tempData.sort((a, b) => a.dateTime.compareTo(b.dateTime));

      setState(() {
        data = tempData;
        isLoading = false;
        hasError = false;
      });
    } catch (error) {
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  DateTime _parseCustomDateTime(String dateTimeString) {
    try {
      final dateFormat = DateFormat("yyyy-MM-dd HH-mm-ss");
      return dateFormat.parse(dateTimeString);
    } catch (e) {
      return DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(Duration(days: 7));

    return isLoading
        ? Center(child: CircularProgressIndicator())
        : hasError
            ? _errorUI()
            : _chartUI(sevenDaysAgo, now);
  }

  Widget _errorUI() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Select a dog to view its heartbeat data.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  isLoading = true;
                  setupRealTimeListener();
                });
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                primary: Colors.white.withOpacity(0.3),
                elevation: 0,
                shadowColor: Colors.transparent,
              ),
              child: Text(
                'Show the chart',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartUI(DateTime sevenDaysAgo, DateTime now) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SfCartesianChart(
        primaryXAxis: DateTimeAxis(
          minimum: sevenDaysAgo,
          maximum: now,
          intervalType: DateTimeIntervalType.days,
          dateFormat: DateFormat('MM/dd'),
          labelStyle: TextStyle(
            fontFamily: 'Poppins',
            color: Colors.grey[700],
          ),
          majorGridLines: MajorGridLines(width: 0),
        ),
        primaryYAxis: NumericAxis(
          minimum: 0,
          maximum: 250,
          interval: 50,
          labelStyle: TextStyle(
            fontFamily: 'Poppins',
            color: Colors.grey[700],
          ),
          majorGridLines: MajorGridLines(width: 0.5),
        ),
        title: ChartTitle(
          text: 'Heartbeat Over Last 7 Days',
          textStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        legend: Legend(isVisible: true),
        tooltipBehavior: TooltipBehavior(enable: true),
        series: <CartesianSeries<_HeartbeatData, DateTime>>[
          LineSeries<_HeartbeatData, DateTime>(
            dataSource: data,
            xValueMapper: (_HeartbeatData data, _) => data.dateTime,
            yValueMapper: (_HeartbeatData data, _) => data.heartbeat,
            name: 'Heartbeat',
            color: Color(0xFF4A00E0),
            dataLabelSettings: DataLabelSettings(isVisible: false),
            markerSettings: MarkerSettings(isVisible: true),
            enableTooltip: true,
          ),
        ],
      ),
    );
  }
}

class _HeartbeatData {
  _HeartbeatData(this.dateTime, this.heartbeat);

  final DateTime dateTime;
  final double heartbeat;
}
