import 'package:flutter/material.dart';
import '../models/task.dart';
import '../widgets/task_section.dart';


class HomePage extends StatefulWidget {

  @override
  State<HomePage> createState()=>_HomePageState();

}


class _HomePageState extends State<HomePage>{


List<Task> fixedTasks=[

 Task(
 id:"1",
 title:"月度资金计划",
 fixed:true
 ),

 Task(
 id:"2",
 title:"项目成本分析",
 fixed:true
 ),

];


List<Task> tempTasks=[

 Task(
 id:"3",
 title:"完成日报",
 deadline:DateTime.now()
 ),

 Task(
 id:"4",
 title:"整理合同",
 deadline:DateTime.now()
 ),

];



void completeTask(Task task){


 setState((){


   if(task.fixed){

     task.completed=!task.completed;

   }

   else{

     tempTasks.remove(task);

   }


 });


}



@override
Widget build(BuildContext context){


return Scaffold(


body:Center(

child:Container(

width:500,

padding:const EdgeInsets.all(20),


child:Column(

children:[


Row(

mainAxisAlignment:
MainAxisAlignment.spaceBetween,


children:[

const Text(
"Luna To-Do",
style:TextStyle(
fontSize:22,
fontWeight:FontWeight.bold
),
),


IconButton(

icon:const Icon(Icons.settings),

onPressed:(){},

)

],

),



Expanded(

child:Row(

children:[


Expanded(

child:TaskSection(

title:"固定事项",

tasks:fixedTasks,

onComplete:completeTask,

)

),


const SizedBox(width:20),


Expanded(

child:TaskSection(

title:"临时事项",

tasks:tempTasks,

onComplete:completeTask,

)

)


],

)

)


]

)

)

)


);


}


}