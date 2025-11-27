# 🌤️ Real Weather API Setup Guide

## Overview

The app now supports **real-time weather data** based on the farmer's location using the **OpenWeatherMap API** (100% FREE tier).

---

## 🆓 Get Your FREE API Key

### Step 1: Sign Up for OpenWeatherMap

1. Go to: https://openweathermap.org/api
2. Click **"Sign Up"** (top right)
3. Create a free account with your email
4. **Verify your email** (check spam folder)

### Step 2: Get Your API Key

1. Log in to your account
2. Go to: https://home.openweathermap.org/api_keys
3. Your API key will be displayed (looks like: `a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6`)
4. **Copy this key**

### Step 3: Add API Key to the App

1. Open: `lib/services/weather_service.dart`
2. Find line 30:
   ```dart
   static const String _apiKey = 'YOUR_API_KEY_HERE';
   ```
3. Replace `YOUR_API_KEY_HERE` with your actual API key:
   ```dart
   static const String _apiKey = 'a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6';
   ```
4. Save the file

---

## ✅ Free Tier Limits

- **60 calls per minute**
- **1,000,000 calls per month**
- **Perfect for development and small deployments**

---

## 🌍 Features Enabled

### ✅ Real-Time Weather Data

- **Temperature** (Celsius)
- **Weather Condition** (Clear, Cloudy, Rain, etc.)
- **Humidity** (%)
- **Rainfall** (mm)
- **Location Name** (City)

### ✅ Location-Based

- Automatically detects farmer's location using GPS
- Falls back to mock data if:
  - No API key is set
  - API quota exceeded
  - Location permission denied
  - No internet connection

### ✅ Manual City Selection (Optional)

You can also fetch weather by city name:

```dart
final weather = await weatherService.getWeatherByCity('Nairobi');
```

---

## 🔐 Location Permissions

### For Web (Chrome)

- Browser will ask for location permission
- Click **"Allow"** when prompted

### For Android

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

### For iOS

Add to `ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to show local weather conditions for your farm</string>
```

---

## 🧪 Testing Without API Key

The app includes a **Mock Weather Service** that provides demo data if:

- No API key is configured
- API request fails
- For testing/development

**Mock data includes:**

- Temperature: 28°C
- Condition: Partly Cloudy
- Humidity: 65%
- Rainfall: 2.3mm
- Location: Nairobi

---

## 📊 Weather Icons

The app displays appropriate icons based on weather conditions:

- ☀️ Clear/Sunny
- ☁️ Cloudy
- 🌧️ Rain
- ⛈️ Thunderstorm
- ❄️ Snow
- 🌫️ Fog/Mist

---

## 🔄 Refresh Weather

Users can tap the **"Refresh"** button in the weather widget to update the data in real-time.

---

## 🚀 Alternative FREE Weather APIs

If you prefer a different provider:

### 1. **WeatherAPI.com**

- Free tier: 1M calls/month
- https://www.weatherapi.com/

### 2. **Open-Meteo**

- Completely free, no API key needed!
- https://open-meteo.com/

### 3. **WeatherStack**

- Free tier: 250 calls/month
- https://weatherstack.com/

---

## 📝 Example Implementation

```dart
// In your app
import 'package:your_app/services/weather_service.dart';

final weatherService = WeatherService();

// Option 1: Get weather by current location
final weather = await weatherService.getCurrentLocationWeather();

// Option 2: Get weather by city
final nairobiWeather = await weatherService.getWeatherByCity('Nairobi');

// Use the data
print('Temperature: ${weather.temperature}°C');
print('Condition: ${weather.condition}');
print('Humidity: ${weather.humidity}%');
```

---

## 💡 Pro Tips

1. **API Key Security**: For production apps, store the API key securely (use environment variables or backend proxy)
2. **Caching**: Cache weather data locally to reduce API calls
3. **Error Handling**: The app gracefully falls back to mock data if the API fails
4. **Offline Mode**: Consider showing last fetched weather when offline

---

## 📞 Support

**OpenWeatherMap Documentation**: https://openweathermap.org/api
**FAQ**: https://openweathermap.org/faq

---

## ✅ Quick Start Checklist

- [ ] Sign up for OpenWeatherMap account
- [ ] Get your free API key
- [ ] Add API key to `lib/services/weather_service.dart`
- [ ] Run `flutter pub get`
- [ ] Test the app - weather should load automatically!

**That's it! Your app now has real-time weather! 🎉**

