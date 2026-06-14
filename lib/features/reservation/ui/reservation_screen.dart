import 'package:flutter/material.dart';

class ReservationScreen extends StatelessWidget {
  final String id;
  const ReservationScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reservation')),
      body: Center(child: Text('Reservation ID: $id')),
    );
  }
}