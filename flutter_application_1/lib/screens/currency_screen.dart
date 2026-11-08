import 'package:flutter/material.dart';

class CurrencyScreen extends StatelessWidget {
  const CurrencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('صرف العملات')),
      body: Center(child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text('واجهة صرف العملات وتحويل العملات (قيد التطوير)', style: TextStyle(fontSize: 16), textAlign: TextAlign.center),
      )),
    );
  }
}
