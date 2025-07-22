import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:weather/weather.dart';
import 'package:geolocator/geolocator.dart';
import 'package:weather_app/data/my_data.dart';

part 'weather_event.dart';
part 'weather_state.dart';

final String errorMessage = '';

class WeatherBloc extends Bloc<WeatherBlocEvent, WeatherState> {
  WeatherBloc() : super(WeatherInitial()) {
    on<FetchWeather>((event, emit) async {
      emit(WeatherLoading());
      try{
        WeatherFactory wf = WeatherFactory(api_key, language: Language.ENGLISH);

        Weather weather = await wf.currentWeatherByLocation(
            event.position.latitude,
            event.position.longitude
        );
        emit(WeatherSuccess(weather));
      }catch(e){
        emit(WeatherFailure(errorMessage));
      }

      // TODO: implement event handler
    });
  }
}

class WeatherFailure extends WeatherState {
  @override
  final String errorMessage;

  const WeatherFailure(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}
