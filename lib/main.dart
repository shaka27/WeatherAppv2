import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:weather_app/bloc/weather_bloc.dart';
import 'package:weather_app/screens/homeScreen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const weather_app());
}

class weather_app extends StatelessWidget {
  const weather_app({super.key});


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: FutureBuilder(
          future: _determinePosition(),
          builder: (context, snap) {
            if(snap.hasData)
              {
                return BlocProvider<WeatherBloc>(
                  create: (context) => WeatherBloc()..add(
                      FetchWeather(snap.data as Position)),
                  child: const HomeScreen(),
                );
              }
            else
              {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
          }
        )
    );
  }

  Future<Position> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception("Location services are disabled.");
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception("Location permission denied.");
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception("Location permission permanently denied.");
      }

      return await Geolocator.getCurrentPosition();
    } catch (e) {
      debugPrint("Error determining position: $e");
      rethrow;
    }
  }

}


