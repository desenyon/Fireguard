import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<void> requestStartupPermissions(BuildContext context) async {
    await Future.wait([
      _requestLocationPermission(context),
      _requestNotificationPermission(context),
    ]);
  }

  static Future<void> _requestLocationPermission(BuildContext context) async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await _showLocationServiceDialog(context);
        return;
      }

      // Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        // Show explanation dialog before requesting permission
        bool shouldRequest = await _showLocationPermissionDialog(context);
        if (shouldRequest) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            await _showLocationDeniedDialog(context);
            return;
          }
        }
      }

      if (permission == LocationPermission.deniedForever) {
        await _showLocationSettingsDialog(context);
        return;
      }

      print('✅ Location permission granted');
    } catch (e) {
      print('❌ Error requesting location permission: $e');
    }
  }

  static Future<void> _requestNotificationPermission(BuildContext context) async {
    try {
      final FirebaseMessaging messaging = FirebaseMessaging.instance;
      
      // Check current permission status
      final NotificationSettings settings = await messaging.getNotificationSettings();
      
      if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
        // Show explanation dialog before requesting permission
        bool shouldRequest = await _showNotificationPermissionDialog(context);
        if (shouldRequest) {
          final NotificationSettings newSettings = await messaging.requestPermission(
            alert: true,
            badge: true,
            sound: true,
            announcement: false,
            carPlay: false,
            criticalAlert: false,
            provisional: false,
          );
          
          if (newSettings.authorizationStatus == AuthorizationStatus.denied) {
            await _showNotificationDeniedDialog(context);
            return;
          }
        }
      } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
        await _showNotificationSettingsDialog(context);
        return;
      }

      print('✅ Notification permission granted');
    } catch (e) {
      print('❌ Error requesting notification permission: $e');
    }
  }

  // Location Service Disabled Dialog
  static Future<void> _showLocationServiceDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.location_off, color: Colors.orange),
              SizedBox(width: 8),
              Text('Location Services Disabled'),
            ],
          ),
          content: const Text(
            'FireGuard needs location access to show nearby fires and provide safety alerts. Please enable location services in your device settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Geolocator.openLocationSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  // Location Permission Request Dialog
  static Future<bool> _showLocationPermissionDialog(BuildContext context) async {
    bool shouldRequest = false;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.location_on, color: Colors.blue),
              SizedBox(width: 8),
              Text('Location Access Required'),
            ],
          ),
          content: const Text(
            'FireGuard needs access to your location to:\n\n'
            '• Show fires near you\n'
            '• Calculate distances to fires\n'
            '• Provide evacuation directions\n'
            '• Send location-based alerts\n\n'
            'Your location data stays private and secure.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                shouldRequest = false;
                Navigator.of(context).pop();
              },
              child: const Text('Not Now'),
            ),
            ElevatedButton(
              onPressed: () {
                shouldRequest = true;
                Navigator.of(context).pop();
              },
              child: const Text('Allow Location'),
            ),
          ],
        );
      },
    );
    return shouldRequest;
  }

  // Location Permission Denied Dialog
  static Future<void> _showLocationDeniedDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.location_off, color: Colors.red),
              SizedBox(width: 8),
              Text('Location Access Denied'),
            ],
          ),
          content: const Text(
            'Without location access, FireGuard cannot show nearby fires or provide safety alerts. You can enable it later in settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Continue Without Location'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Geolocator.openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  // Location Settings Dialog
  static Future<void> _showLocationSettingsDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.settings, color: Colors.orange),
              SizedBox(width: 8),
              Text('Enable Location Access'),
            ],
          ),
          content: const Text(
            'Location access was permanently denied. Please enable it in your device settings to use FireGuard\'s safety features.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Continue Without Location'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Geolocator.openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  // Notification Permission Request Dialog
  static Future<bool> _showNotificationPermissionDialog(BuildContext context) async {
    bool shouldRequest = false;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.notifications, color: Colors.blue),
              SizedBox(width: 8),
              Text('Fire Alerts Required'),
            ],
          ),
          content: const Text(
            'FireGuard needs to send you notifications to:\n\n'
            '• Alert you about nearby fires\n'
            '• Warn about dangerous conditions\n'
            '• Provide evacuation updates\n'
            '• Send safety reminders\n\n'
            'You can customize notification settings later.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                shouldRequest = false;
                Navigator.of(context).pop();
              },
              child: const Text('Not Now'),
            ),
            ElevatedButton(
              onPressed: () {
                shouldRequest = true;
                Navigator.of(context).pop();
              },
              child: const Text('Allow Notifications'),
            ),
          ],
        );
      },
    );
    return shouldRequest;
  }

  // Notification Permission Denied Dialog
  static Future<void> _showNotificationDeniedDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.notifications_off, color: Colors.red),
              SizedBox(width: 8),
              Text('Notifications Denied'),
            ],
          ),
          content: const Text(
            'Without notifications, you won\'t receive fire alerts or safety warnings. You can enable them later in settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Continue Without Notifications'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  // Notification Settings Dialog
  static Future<void> _showNotificationSettingsDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.settings, color: Colors.orange),
              SizedBox(width: 8),
              Text('Enable Notifications'),
            ],
          ),
          content: const Text(
            'Notifications were disabled. Please enable them in your device settings to receive fire alerts and safety warnings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Continue Without Notifications'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }
}
