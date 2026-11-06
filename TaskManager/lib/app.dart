   import 'package:flutter/material.dart';
   import 'screens/auth/register_screen.dart';

   class TaskManagerApp extends StatelessWidget {
     const TaskManagerApp({super.key});

     @override
     Widget build(BuildContext context) {
       return MaterialApp(
         title: 'Task Manager',
         debugShowCheckedModeBanner: false,
         theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
         home: const RegisterScreen(),
       );
     }
   }