import 'package:flutter/material.dart';
import '../models/task.dart';
import 'task_item.dart';


class TaskSection extends StatelessWidget{


final String title;

final List<Task> tasks;

final Function(Task) onComplete;


const TaskSection({

super.key,

required this.title,

required this.tasks,

required this.onComplete,

});



@override
Widget build(BuildContext context){


return Container(

padding:const EdgeInsets.all(15),

decoration:BoxDecoration(

border:Border.all(
color:Colors.grey
),

borderRadius:
BorderRadius.circular(12)

),


child:Column(

crossAxisAlignment:
CrossAxisAlignment.start,


children:[


Text(

title,

style:
const TextStyle(

fontSize:18,

fontWeight:
FontWeight.bold

),

),


const Divider(),


Expanded(

child:ListView(

children:

tasks.map(

(task)=>

TaskItem(

task:task,

onComplete:onComplete,

)

).toList(),

),

)

]


)

);


}



}