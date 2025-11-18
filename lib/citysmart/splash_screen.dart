import 'dart:math';
import 'package:flutter/material.dart';
class SplashScreen extends StatefulWidget { const SplashScreen({super.key}); @override State<SplashScreen> createState()=>_SplashState(); }
class _SplashState extends State<SplashScreen>{
  late bool showSpinner;
  @override void initState(){ super.initState(); showSpinner = Random().nextBool();
    Future.delayed(const Duration(seconds: 2), ()=> Navigator.pushReplacementNamed(context, '/home')); }
  @override Widget build(BuildContext context){
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors:[Color(0xFF7CA726), Color(0xFF5E8A45)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('CitySmart', style: TextStyle(fontSize: 32, color: Color(0xFFE0B000), fontWeight: FontWeight.w700)),
          const SizedBox(height: 24),
          if (showSpinner) const CircularProgressIndicator(color: Color(0xFFE0B000), strokeWidth: 3)
          else Container(width: 140, height: 6, color: Colors.white24, alignment: Alignment.centerLeft,
            child: Container(width: 120, height: 6, color: const Color(0xFFE0B000))),
        ])),
      ),
    );
  }
}
