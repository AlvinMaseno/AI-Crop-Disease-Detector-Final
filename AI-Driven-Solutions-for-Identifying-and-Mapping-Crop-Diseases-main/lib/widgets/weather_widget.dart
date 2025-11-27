import 'package:flutter/material.dart';

class WeatherWidget extends StatelessWidget {
  final String temperature;
  final String condition;
  final String humidity;
  final String rainfall;
  final IconData weatherIcon;

  const WeatherWidget({
    super.key,
    required this.temperature,
    required this.condition,
    required this.humidity,
    required this.rainfall,
    required this.weatherIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
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
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weather Today',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(
                weatherIcon,
                color: Colors.white,
                size: 32,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                temperature,
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                condition,
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
                child: _buildWeatherInfo(
                  context,
                  Icons.water_drop,
                  'Humidity',
                  humidity,
                ),
              ),
              Expanded(
                child: _buildWeatherInfo(
                  context,
                  Icons.cloudy_snowing,
                  'Rainfall',
                  rainfall,
                ),
              ),
            ],
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
}

class MockWeatherWidget extends StatelessWidget {
  const MockWeatherWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const WeatherWidget(
      temperature: '28°C',
      condition: 'Partly Cloudy',
      humidity: '65%',
      rainfall: '2.3mm',
      weatherIcon: Icons.wb_cloudy,
    );
  }
}


