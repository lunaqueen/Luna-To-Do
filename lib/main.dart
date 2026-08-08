import 'package:flutter/material.dart';
import 'pages/home_page.dart';


void main() {

  runApp(const LunaTodo());

}


class LunaTodo extends StatelessWidget {

  const LunaTodo({super.key});


  @override
  Widget build(BuildContext context){

    return MaterialApp(

      debugShowCheckedModeBanner:false,

      title:"Luna To-Do",

      theme:ThemeData(

        useMaterial3:true,

      ),

      home:HomePage(),

    );

  }

}