import 'dart:convert';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

void main()=>
  runApp(WeatherApp());


class WeatherApp extends StatefulWidget {
  @override
  _WeatherAppState createState() => _WeatherAppState();
}

class _WeatherAppState extends State<WeatherApp> {
  int temperature;
  int woeid = 2487956;
  String location = "San Francisco";
  String weather = "snow";
  String abbrevation = "";
  String errorMessage = "";
  final Geolocator geolocator = Geolocator()..forceAndroidLocationManager;
  String locationUrlApi = "https://www.metaweather.com/api/location/";
  Position _currentPosition;
  String _currentAddress;
  var minTemperatureForecast = new List(7);
  var maxTemperatureForecast = new List(7);
  var abbrevationForecast = new List(7);

  @override
  void initState() {
    super.initState();
    fetch_location();
    fetchLocationDay();
  }

  void fetch_search(String input) async {
    try {
      String searchUrlApi =
          "https://www.metaweather.com/api/location/search/?query=";
      var searchResult = await http.get(searchUrlApi + input);
      var result = json.decode(searchResult.body)[0];
      setState(() {
        location = result["title"];
        woeid = result["woeid"];
        errorMessage = '';
      });
    } catch (error) {
      errorMessage = "We don't have about your city. Try another one";
    }
  }

  void fetch_location() async {
    String locationUrlApi = "https://www.metaweather.com/api/location/";
    var location_result = await http.get(locationUrlApi + woeid.toString());
    var result = json.decode(location_result.body);
    var consolidated_weather = result["consolidated_weather"];
    var data = consolidated_weather[0];
    setState(() {
      temperature = data["the_temp"].round();
      weather = data["weather_state_name"].replaceAll(' ', '').toLowerCase();
      abbrevation = data["weather_state_abbr"];
    });
  }

  void fetchLocationDay() async {
    var today = new DateTime.now();
    for (var i = 0; i < 7; i++) {
      var locationDayResult = await http.get(locationUrlApi +
          woeid.toString() +
          '/' +
          new DateFormat('y/M/d')
              .format(today.add(new Duration(days: i + 1)))
              .toString());
      var result = json.decode(locationDayResult.body);
      var data = result[0];
      setState(() {
        minTemperatureForecast[i] = data["min_temp"].round();
        maxTemperatureForecast[i] = data["max_temp"].round();
        abbrevationForecast[i] = data["weather_state_abbr"];
      });
    }
  }

  void onTextFieldSubmitted(String input) async {
    await fetch_search(input);
    await fetch_location();
    await fetchLocationDay();
  }

  _getCurrentLocation() {
    geolocator
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
        .then((Position position) {
      setState(() {
        _currentPosition = position;
      });
      _getAddressFromLatLng();
    }).catchError((e) {
      print(e);
    });
  }

  _getAddressFromLatLng() async {
    try {
      List<Placemark> p = await geolocator.placemarkFromCoordinates(
          _currentPosition.latitude, _currentPosition.longitude);
      Placemark place = p[0];
      setState(() {
        _currentAddress =
            "${place.locality}, ${place.postalCode}, ${place.country}";
      });
      onTextFieldSubmitted(place.locality);
      print(place.locality);
      onTextFieldSubmitted(place.locality);
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('hinh/$weather.png'),
              fit: BoxFit.cover,
              colorFilter: new ColorFilter.mode(Colors.black.withOpacity(0.6),BlendMode.dstATop),
            ),
          ),
          child: temperature == null
              ? Center(child: CircularProgressIndicator())
              : Scaffold(
                  resizeToAvoidBottomInset: false,
                  appBar: AppBar(
                    actions: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: GestureDetector(
                          onTap: () {
                            _getCurrentLocation();
                          },
                          child: Icon(
                            Icons.location_city,
                            size: 36,
                          ),
                        ),
                      )
                    ],
                    backgroundColor: Colors.transparent,
                    elevation: 0.0,
                  ),
                  backgroundColor: Colors.transparent,
                  body: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Column(
                        children: [
                          Center(
                            child: Image.network(
                              "https://www.metaweather.com//static/img/weather/png/" +
                                  abbrevation +
                                  ".png",
                              width: 100,
                            ),
                          ),
                          Center(
                            child: Text(
                              temperature.toString() + "°C",
                              style: TextStyle(
                                  color: Colors.white, fontSize: 60.0),
                            ),
                          ),
                          Center(
                              child: Text(
                            location,
                            style:
                                TextStyle(color: Colors.white, fontSize: 40.0),
                          ))
                        ],
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: <Widget>[
                            forecastElement(
                                1,
                                abbrevationForecast[0],
                                maxTemperatureForecast[0],
                                minTemperatureForecast[0]),
                            forecastElement(
                                2,
                                abbrevationForecast[1],
                                maxTemperatureForecast[1],
                                minTemperatureForecast[1]),
                            forecastElement(
                                3,
                                abbrevationForecast[2],
                                maxTemperatureForecast[2],
                                minTemperatureForecast[2]),
                            forecastElement(
                                4,
                                abbrevationForecast[3],
                                maxTemperatureForecast[3],
                                minTemperatureForecast[3]),
                            forecastElement(
                                5,
                                abbrevationForecast[4],
                                maxTemperatureForecast[4],
                                minTemperatureForecast[4]),
                            forecastElement(
                                6,
                                abbrevationForecast[5],
                                maxTemperatureForecast[5],
                                minTemperatureForecast[5]),
                            forecastElement(
                                7,
                                abbrevationForecast[6],
                                maxTemperatureForecast[6],
                                minTemperatureForecast[6]),
                          ],
                        ),
                      ),
                      Column(
                        children: <Widget>[
                          Container(
                            width: 300,
                            child: TextField(
                              onSubmitted: (String input) {
                                onTextFieldSubmitted(input);
                              },
                              style: TextStyle(
                                  color: Colors.white, fontSize: 25.0),
                              decoration: InputDecoration(
                                  hintText: "Search location",
                                  hintStyle: TextStyle(
                                      color: Colors.white, fontSize: 18.0),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: Colors.white,
                                  )),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Text(
                              errorMessage,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: Platform.isAndroid ? 16.0 : 20.0),
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                ),
      ),
    );
  }
}

Widget forecastElement(
    dateFormNow, abbrevation, maxTemperature, minTemperature) {
  var now = new DateTime.now();
  var oneDayFromNow = now.add(new Duration(days: dateFormNow));
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Container(
      decoration: BoxDecoration(
        color: Color.fromRGBO(205, 212, 228, 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Column(
          children: <Widget>[
            Center(
              child: Text(
                new DateFormat.E().format(oneDayFromNow),
                style: TextStyle(color: Colors.white, fontSize: 25),
              ),
            ),
            Center(
              child: Text(
                new DateFormat.MMMd().format(oneDayFromNow),
                style: TextStyle(color: Colors.white, fontSize: 25),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 16),
              child: Image.network(
                ("https://www.metaweather.com//static/img/weather/png/" +
                    abbrevation +
                    ".png"),
                width: 50,
              ),
            ),
            Text(
              "High" + maxTemperature.toString() + "°C",
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            Text(
              "Low" + minTemperature.toString() + "°C",
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ],
        ),
      ),
    ),
  );
}
