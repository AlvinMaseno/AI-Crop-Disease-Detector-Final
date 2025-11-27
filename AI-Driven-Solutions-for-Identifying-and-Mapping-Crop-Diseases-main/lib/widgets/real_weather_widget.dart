import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/weather_service.dart';
import '../providers/app_provider.dart';

class RealWeatherWidget extends StatefulWidget {
  const RealWeatherWidget({super.key});

  @override
  State<RealWeatherWidget> createState() => _RealWeatherWidgetState();
}

class _RealWeatherWidgetState extends State<RealWeatherWidget> {
  WeatherData? _weatherData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get smart weather data (no API required)
      final weatherService = WeatherService();
      final weather = await weatherService.getCurrentLocationWeather();
      
      if (weather != null) {
        setState(() {
          _weatherData = weather;
          _isLoading = false;
        });
      } else {
        // Fallback to mock data
        _loadMockWeather();
      }
    } catch (e) {
      print('Error loading weather: $e');
      // Fallback to mock data
      _loadMockWeather();
    }
  }

  Future<void> _loadMockWeather() async {
    final mockService = MockWeatherService();
    final weather = await mockService.getMockWeather();
    
    setState(() {
      _weatherData = weather;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    if (_weatherData == null) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              'Unable to load weather',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1B5E20),
            Color(0xFF2E7D32),
            Color(0xFF388E3C),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Consumer<AppProvider>(
                    builder: (context, appProvider, child) {
                      return Text(
                        appProvider.translate('weatherToday'),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                  Text(
                    _weatherData!.locationName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
              Icon(
                _getWeatherIcon(_weatherData!.condition),
                color: Colors.white,
                size: 32,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '${_weatherData!.temperature.round()}°C',
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _weatherData!.condition,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Consumer<AppProvider>(
                  builder: (context, appProvider, child) {
                    return _buildWeatherInfo(
                      context,
                      Icons.water_drop,
                      appProvider.translate('humidity'),
                      '${_weatherData!.humidity}%',
                    );
                  },
                ),
              ),
              Expanded(
                child: Consumer<AppProvider>(
                  builder: (context, appProvider, child) {
                    return _buildWeatherInfo(
                      context,
                      Icons.cloudy_snowing,
                      appProvider.translate('rainfall'),
                      '${_weatherData!.rainfall.toStringAsFixed(1)}mm',
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Weather recommendation for farmers
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getFarmRecommendationIcon(),
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getFarmRecommendation(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: _loadWeather,
              icon: const Icon(Icons.refresh, color: Colors.white, size: 16),
              label: Consumer<AppProvider>(
                builder: (context, appProvider, child) {
                  return Text(
                    appProvider.translate('refresh'),
                    style: TextStyle(color: Colors.white.withOpacity(0.9)),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherInfo(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: Colors.white.withOpacity(0.8),
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny;
      case 'clouds':
      case 'partly cloudy':
        return Icons.wb_cloudy;
      case 'rain':
      case 'drizzle':
        return Icons.water_drop;
      case 'thunderstorm':
        return Icons.thunderstorm;
      case 'snow':
        return Icons.ac_unit;
      case 'mist':
      case 'fog':
        return Icons.foggy;
      default:
        return Icons.wb_cloudy;
    }
  }

  String _getFarmRecommendation() {
    if (_weatherData == null) return 'Weather data unavailable';
    
    final temp = _weatherData!.temperature;
    final humidity = _weatherData!.humidity;
    final rainfall = _weatherData!.rainfall;
    final condition = _weatherData!.condition.toLowerCase();
    
    // Temperature-based recommendations
    if (temp > 35) {
      return 'Hot weather - Consider early morning watering and shade for crops';
    } else if (temp < 15) {
      return 'Cool weather - Protect young plants and consider greenhouse options';
    }
    
    // Rainfall-based recommendations
    if (rainfall > 10) {
      return 'Heavy rainfall - Check drainage and avoid overwatering';
    } else if (rainfall > 5) {
      return 'Good rainfall - Reduce irrigation and monitor soil moisture';
    } else if (rainfall == 0 && humidity < 40) {
      return 'Dry conditions - Increase irrigation and check soil moisture';
    }
    
    // Humidity-based recommendations
    if (humidity > 80) {
      return 'High humidity - Watch for fungal diseases and ensure good air circulation';
    } else if (humidity < 30) {
      return 'Low humidity - Increase watering frequency and consider mulching';
    }
    
    // Condition-based recommendations
    if (condition.contains('rain')) {
      return 'Rainy weather - Avoid fertilizer application and check field drainage';
    } else if (condition.contains('sunny') || condition.contains('clear')) {
      return 'Sunny weather - Good day for planting and field work';
    } else if (condition.contains('cloudy')) {
      return 'Cloudy weather - Suitable for transplanting and light field work';
    }
    
    return 'Good weather for general farming activities';
  }

  IconData _getFarmRecommendationIcon() {
    if (_weatherData == null) return Icons.help_outline;
    
    final temp = _weatherData!.temperature;
    final humidity = _weatherData!.humidity;
    final rainfall = _weatherData!.rainfall;
    final condition = _weatherData!.condition.toLowerCase();
    
    if (temp > 35 || temp < 15) {
      return Icons.warning_amber_rounded;
    } else if (rainfall > 10 || humidity > 80) {
      return Icons.water_drop;
    } else if (rainfall == 0 && humidity < 40) {
      return Icons.water_drop_outlined;
    } else if (condition.contains('sunny') || condition.contains('clear')) {
      return Icons.wb_sunny;
    } else {
      return Icons.agriculture;
    }
  }
}
