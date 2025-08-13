import 'dart:async';
import 'package:flutter/material.dart';

class InAppNotification {
  final String title;
  final String message;
  final Color color;
  final DateTime timestamp;

  InAppNotification({
    required this.title,
    required this.message,
    this.color = Colors.deepPurple,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _controller = StreamController<InAppNotification>.broadcast();
  Stream<InAppNotification> get stream => _controller.stream;

  void push({required String title, required String message, Color color = Colors.deepPurple}) {
    _controller.add(InAppNotification(title: title, message: message, color: color));
  }

  void dispose() {
    _controller.close();
  }
}
