import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:hava_kontrol/models/air_pollution_model.dart';
import 'package:intl/intl.dart';
import 'package:tuple/tuple.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Stream<AirPollution> airPollutionStream;
  double? previousVoltage;
  String city = "Şehir yükleniyor...";
  String district = "İlçe yükleniyor...";
  List<AirPollution> lastMeasurements = []; // Bu liste son ölçümleri saklayacak

  @override
  void initState() {
    super.initState();
    airPollutionStream = airPollutionDataStream();
    //airPollutionStream.listen(updateLastMeasurements);
    determinePosition();
  }

  void updateLastMeasurements(List<AirPollution> data) {
    setState(() {
      lastMeasurements = data;
    });
  }

  Future<void> determinePosition() async {
    Position position = await Geolocator.getCurrentPosition();
    getPlace(position);
  }

  Future<void> getPlace(Position position) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemarks[0];
      setState(() {
        city = place.administrativeArea ?? "Konya";
        district = place.subAdministrativeArea ??
            "Seydişehir"; // subAdministrativeArea yerine locality kullanılır.
      });
    } catch (e) {
      setState(() {
        city = "Konya";
        district = "Seydişehir";
      });
    }
  }

  Stream<AirPollution> airPollutionDataStream() {
    return FirebaseDatabase.instance.ref().child('sensor1').onValue.map(
      (event) {
        final snapshot = event.snapshot;
        if (snapshot.exists) {
          AirPollution airPollution = AirPollution.fromJson(
              Map<String, dynamic>.from(snapshot.value as Map));
          updateLastMeasurements(
              airPollution.son5); // Pass the last five measurements
          return airPollution;
        } else {
          throw Exception('No data available.');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF676BD0),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 30.0),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                StreamBuilder<AirPollution>(
                  stream: airPollutionStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator(
                          color: Colors.white);
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else if (snapshot.hasData) {
                      return Column(
                        children: [
                          buildWeatherInfo(snapshot.data!),
                          const Divider(),
                          buildMeasurementList(),
                        ],
                      );
                    } else {
                      return const Text('No data available');
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildMeasurementList() {
    return Column(
      children: [
        const Text('Son 5 Ölçüm',
            style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold)),
        ListView.builder(
          shrinkWrap: true,
          itemCount: lastMeasurements.length,
          itemBuilder: (context, index) {
            var measurement = lastMeasurements[index];
            return ListTile(
              title: Text(
                  DateFormat('d MMMM, yyyy HH:mm:ss', 'tr_TR').format(
                      DateTime.fromMillisecondsSinceEpoch(
                          measurement.zaman * 1000)),
                  style: const TextStyle(color: Colors.white)),
              trailing: Text('%${measurement.kalite.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            );
          },
        ),
      ],
    );
  }

  Widget buildWeatherInfo(AirPollution data) {
    String todayDate =
        DateFormat('d MMMM, yyyy', 'tr_TR').format(DateTime.now());
    var airQuality = getAirQualityDescription(data.kalite);
    Widget qualityChangeIndicator = getQualityChangeIndicator(data.kalite);

    return Center(
      child: Column(
        children: [
          Text(city, // Dinamik şehir bilgisi
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(district, // Dinamik ilçe bilgisi
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  letterSpacing: 1.3,
                  fontWeight: FontWeight.bold)),
          Text(todayDate, style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 20),
          const Image(
              image: AssetImage('assets/pollution.png'),
              height: 250,
              width: 250),
          const SizedBox(height: 20),
          buildWeatherDetail(
              "Hava Temizlik Derecesi",
              '%${data.kalite.toStringAsFixed(2)}',
              Colors.white,
              qualityChangeIndicator),
          buildWeatherDetail(
              "Hava Kalitesi", airQuality.item1, airQuality.item2, null),
          buildWeatherDetail(
              "En düşük ve yüksek Ölçüm",
              '%${data.dusuk.toStringAsFixed(2)}  -  %${data.yuksek.toStringAsFixed(2)}',
              Colors.white,
              null),
          // buildWeatherDetail("En düşük Ölçüm",
          //    '%${data.dusuk.toStringAsFixed(2)}', Colors.white, null),
          buildWeatherDetail(
              "Son Ölçüm Zamanı",
              DateFormat('d MMMM, yyyy HH:mm:ss', 'tr_TR').format(
                  DateTime.fromMillisecondsSinceEpoch(data.zaman * 1000)),
              Colors.white,
              null),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  bool showIndicator = true;
  Timer? _timer;

  Widget getQualityChangeIndicator(double currentVoltage) {
    if (previousVoltage == null) {
      previousVoltage = currentVoltage; // İlk değerini atama
      return const SizedBox(); // Değişiklik yoksa gösterme
    }

    Widget indicator;
    if (currentVoltage == previousVoltage) {
      return const SizedBox(); // Değişiklik yoksa gösterme
    }

    if (currentVoltage > previousVoltage!) {
      indicator = const Icon(Icons.arrow_upward, color: Colors.green);
    } else {
      indicator = const Icon(Icons.arrow_downward, color: Colors.red);
    }

    previousVoltage = currentVoltage; // Önceki voltajı güncelle

    // Zamanlayıcıyı sıfırla
    if (_timer != null) {
      _timer!.cancel(); // Eski zamanlayıcıyı iptal et
    }

    _timer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          showIndicator = false;
        });
      }
    });

    showIndicator = true; // Göstericiyi aktif et
    return showIndicator ? indicator : const SizedBox();
  }

  Tuple2<String, Color> getAirQualityDescription(double voltage) {
    if (voltage > 70) {
      return const Tuple2("Hava Kalitesi Güzel", Colors.green);
    } else if (voltage > 40) {
      return const Tuple2("Hava Kalitesi Orta", Colors.orange);
    } else {
      return const Tuple2("Hava Kalitesi Kötü", Colors.red);
    }
  }

  Widget buildWeatherDetail(
      String title, String value, Color valueColor, Widget? indicator) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Text(title,
              style: const TextStyle(color: Colors.white, fontSize: 17)),
          const SizedBox(height: 3),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value,
                  style: TextStyle(
                      color: valueColor,
                      fontSize: 21,
                      fontWeight: FontWeight.w700)),
              if (indicator != null)
                indicator, // Only add indicator if it's not null
            ],
          ),
        ],
      ),
    );
  }
}
