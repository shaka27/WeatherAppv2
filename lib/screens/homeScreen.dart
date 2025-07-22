import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:weather/weather.dart';
import 'package:weather_app/bloc/weather_bloc.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    final weatherBloc = context.read<WeatherBloc>();
    weatherBloc.add(WeatherLoading() as WeatherBlocEvent);

    try {
      final position = await _getCurrentPosition();
      weatherBloc.add(FetchWeather(position));
    } catch (e) {
      weatherBloc.add(WeatherFailure(e.toString()) as WeatherBlocEvent);
    }
  }

  Future<Position> _getCurrentPosition() async {
    final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isServiceEnabled) {
      throw Exception('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions permanently denied');
    }

    return await Geolocator.getCurrentPosition();
  }

  Widget _buildErrorWidget(String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 50),
          const SizedBox(height: 20),
          Text(
            'Failed to load weather',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _fetchWeather,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );
  }

  Widget _getWeatherIcon(int? conditionCode) {
    const defaultIcon = 'lib/assets/sun.png';
    if (conditionCode == null) return Image.asset(defaultIcon);

    if (conditionCode >= 200 && conditionCode < 300) {
      return Image.asset('lib/assets/1.png');
    } else if (conditionCode >= 300 && conditionCode < 500) {
      return Image.asset('lib/assets/5.png');
    } else if (conditionCode >= 600 && conditionCode < 700) {
      return Image.asset('lib/assets/7.png');
    } else if (conditionCode >= 700 && conditionCode < 800) {
      return Image.asset('lib/assets/windy.png');
    } else if (conditionCode == 800) {
      return Image.asset(defaultIcon);
    } else if (conditionCode > 800 && conditionCode <= 804) {
      return Image.asset('lib/assets/8.png');
    }
    return Image.asset(defaultIcon);
  }

  Widget _buildWeatherData(WeatherSuccess state) {
    final weather = state.weather;
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Stack(
        children: [
          // Background elements
         Column(
           children: [ Align(
             alignment: const AlignmentDirectional(0, -0.3),
             child: Container(
               height: 300,
               width: 300,
               decoration: const BoxDecoration(
                 shape: BoxShape.rectangle,
                 color: Colors.orangeAccent,
               ),
             ),
           ),

           ],
         ),
          Align(
            alignment: const AlignmentDirectional(9, -0.3),
            child: Container(
              height: 300,
              width: 300,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.deepPurple,
              ),
            ),
          ),
          Align(
            alignment: const AlignmentDirectional(-9, -0.3),
            child: Container(
              height: 300,
              width: 300,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.deepPurple,
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 100.0, sigmaY: 100.0),
            child: Container(color: Colors.transparent),
          ),

          // Weather content
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "📍 ${weather.areaName ?? 'Unknown location'}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "Good ${_getTimeOfDayGreeting()}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: SizedBox(
                    width: 250,
                    height: 250,
                    child: _getWeatherIcon(weather.weatherConditionCode),
                  ),
                ),
                Center(
                  child: Text(
                    '${weather.temperature?.celsius?.round() ?? '--'}°C',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 50,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    weather.weatherMain?.toUpperCase() ?? '--',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Center(
                  child: Text(
                    weather.date != null
                        ? DateFormat("EEEE dd - ").add_jm().format(weather.date!)
                        : '--',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                _buildSunriseSunsetRow(weather),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 5.0),
                  child: Divider(color: Colors.grey),
                ),
                _buildTemperatureRow(weather),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeOfDayGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  Widget _buildSunriseSunsetRow(Weather weather) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildWeatherInfoItem(
          icon: 'lib/assets/3.png',
          label: 'Sunrise',
          value: weather.sunrise != null
              ? DateFormat().add_jm().format(weather.sunrise!)
              : '--',
        ),
        _buildWeatherInfoItem(
          icon: 'lib/assets/4.png',
          label: 'Sunset',
          value: weather.sunset != null
              ? DateFormat().add_jm().format(weather.sunset!)
              : '--',
        ),
      ],
    );
  }

  Widget _buildTemperatureRow(Weather weather) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildWeatherInfoItem(
          icon: 'lib/assets/6.png',
          label: 'Max Temp',
          value: '${weather.tempMax?.celsius?.round() ?? '--'}°C',
        ),
        _buildWeatherInfoItem(
          icon: 'lib/assets/temperature.png',
          label: 'Min Temp',
          value: "${weather.tempMin!.celsius!.round()} °C",
        ),
      ],
    );
  }

  Widget _buildWeatherInfoItem({
    required String icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Image.asset(icon, scale: 9),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.dark,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(40, 1.2 * kToolbarHeight, 40, 20),
        child: BlocBuilder<WeatherBloc, WeatherState>(
          builder: (context, state) {
            if (state is WeatherLoading) return _buildLoadingWidget();
            if (state is WeatherSuccess) return _buildWeatherData(state);
            if (state is WeatherFailure) return _buildErrorWidget(state.errorMessage);
            return _buildLoadingWidget();
          },
        ),
      ),
    );
  }
}