import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../constants/constants.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({Key? key}) : super(key: key);

  @override
  _LanguageSelectionScreenState createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {


  String selectedLanguage = 'English'; // Set Greek as the default language
  String userCountry = 'Detecting...'; // Default text for user country
  double? latitude;
  double? longitude;
  // Updated language list
  final List<String> languages = ['English', 'Spanish', 'French', 'German', 'Chinese', 'Greek'];

  @override
  void initState() {
    super.initState();
    _loadSavedLanguage();
    _checkAndRequestLocationPermissions();
  }

  Future<void> _loadSavedLanguage() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String savedLanguage = prefs.getString('selectedLanguage') ?? 'English';
    setState(() {
      selectedLanguage = savedLanguage;
    });
  }


  Future<void> _saveLanguageSelection(String language) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedLanguage', language);
  }

  // Call this method when a new country is selected
  void _onLanguageChanged(String newLanguage) {
    setState(() {
      selectedLanguage = newLanguage;
    });
    _saveLanguageSelection(newLanguage);
  }

  Future<void> _checkAndRequestLocationPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          userCountry = 'Location permission denied';
        });
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      setState(() {
        userCountry = 'Location permissions are permanently denied';
      });
      return;
    }
    _detectUserCountry();
  }

  Future<void> _detectUserCountry() async {
  try {
  Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  _detectCountryUsingCoordinates(position.latitude, position.longitude);
  } catch (e) {
  // Fallback to IP detection
  _detectCountryUsingIP();
  }
  }


  Future<void> _detectCountryUsingCoordinates(double latitude, double longitude) async {
    try {
      final response = await http.get(Uri.parse('https://api.ipgeolocation.io/ipgeo?apiKey=06b538dbb7c746069f6b9160dc5cf1c2&lat=$latitude&long=$longitude'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          userCountry = data['country_name'];
          this.latitude = latitude;
          this.longitude = longitude;
        });
      } else {
        // Fallback to IP detection
        _detectCountryUsingIP();
      }
    } catch (e) {
      // Fallback to IP detection
      _detectCountryUsingIP();
    }
  }

  Future<void> _detectCountryUsingIP() async {
    try {
      final response = await http.get(Uri.parse('https://api.ipgeolocation.io/ipgeo?apiKey=06b538dbb7c746069f6b9160dc5cf1c2'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          userCountry = data['country_name'];
        });
      } else {
        setState(() {
          userCountry = 'Country detection failed';
        });
      }
    } catch (e) {
      setState(() {
        userCountry = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: themeColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('Select Language:', style: TextStyle(fontSize: 20)),
            DropdownButton<String>(
              value: selectedLanguage,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    selectedLanguage = newValue;
                  });
                  _onLanguageChanged(newValue);
                }

              },
              items: languages.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: TextStyle(fontSize: 18)),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            Text('Detected Country: $userCountry', style: TextStyle(fontSize: 18)),
            if (latitude != null && longitude != null)
              SizedBox(height: 8), // Add space between the lines if you like
              Text('Latitude: $latitude', style: TextStyle(fontSize: 18)),
              SizedBox(height: 4), // Optional space between latitude and longitude
            Text('Longitude: $longitude', style: TextStyle(fontSize: 18)),
            Spacer(),
            Divider(),
            InkWell(
              onTap: () => _launchURL('https://www.daskalakispiros.com/'),
              child: const Text(
                'Spyros Daskalakis',
                style: TextStyle(fontSize: 14, color: Colors.blue, decoration: TextDecoration.underline),
                textAlign: TextAlign.center,
              ),
            ),
            // ... rest of your widget here
          ],
        ),
      ),
    );
  }
  void _launchURL(String url) async {
    if (!await canLaunchUrl(Uri.parse(url))) {
      print('Could not launch $url');
      return;
    }
    await launchUrl(Uri.parse(url));
  }


}
