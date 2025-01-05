import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:task_rq/task.dart';
import 'db_helper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const TaskManagerApp(),
    );
  }
}

class TaskManagerApp extends StatefulWidget {
  const TaskManagerApp({super.key});

  @override
  TaskManagerAppState createState() => TaskManagerAppState();
}

class TaskManagerAppState extends State<TaskManagerApp> {
  TextEditingController newTaskController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  DateTime startDate = DateTime.now().subtract(const Duration(days: 10));
  DateTime endDate = DateTime.now().add(const Duration(days: 11));
  late DateTime _selectedDate;
  FocusNode textFieldFocus = FocusNode();

  bool isEdit = false;
  Task? currentTask;

  @override
  void initState() {
    _loadTasks();
    _selectedDate = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(574);
    });
    super.initState();
  }

  List<Task> _tasks = [];

  Future<void> _loadTasks() async {
    final tasks = await TasksDBHelper.getTasks();
    setState(() {
      _tasks = tasks;
    });
  }

  Future<void> addTask(text, date) async {
    if (text.isNotEmpty) {
      final task = Task(
        title: text,
        date: date,
        orderIndex: _tasks.length + 1,
        isCompleted: false,
      );
      await TasksDBHelper.insertTask(task);
      _loadTasks();
    }
  }

  Future<void> updateTask(Task task) async {
    await TasksDBHelper.updateTask(task);
    _loadTasks();
  }

  Future<void> reOrder(int oldIndex, int newIndex) async {
    await TasksDBHelper.reOrder(oldIndex, newIndex, _tasks);
    _loadTasks();
  }

  Future<void> deleteTask(Task task) async {
    await TasksDBHelper.deleteTask(task);
    _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Task Manager',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        ),
        body: Column(
          children: [
            SizedBox(
              height: 88,
              child: ListView.builder(
                  controller: _scrollController,
                  itemCount: endDate.difference(startDate).inDays,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    DateTime day = DateTime.now()
                        .subtract(const Duration(days: 10))
                        .add(Duration(days: index));
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDate = day;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Utils.onlyDate(_selectedDate) ==
                                    Utils.onlyDate(day)
                                ? Colors.deepOrange
                                : Colors.transparent),
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 20),
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        child: Column(
                          children: [
                            Text(
                              DateFormat('MMM').format(day),
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                            Text(
                              DateFormat('d').format(day),
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              DateFormat('EEE').format(day).toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: [
                  const Text('Days Task',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                  Text(
                      _tasks
                              .where((task) =>
                                  Utils.onlyDate(task.date) ==
                                  Utils.onlyDate(_selectedDate))
                              .isNotEmpty
                          ? 'Swipe ⇋ to Update, Delete & Swipe ↕ to re-arrange'
                          : 'Add New Tasks',
                      textAlign: TextAlign.center,
                      style:
                          const TextStyle(fontSize: 18, fontWeight: FontWeight.w400)),
                ],
              ),
            ),
            Expanded(
              child: ReorderableListView.builder(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: _tasks.length,
                itemBuilder: (context, index) {
                  if (Utils.onlyDate(_tasks[index].date) ==
                      Utils.onlyDate(_selectedDate)) {
                    return Dismissible(
                        key: ValueKey(_tasks[index].id),
                        secondaryBackground: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20.0),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        background: Container(
                          color: _tasks[index].isCompleted
                              ? Colors.orange
                              : Colors.green,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 20.0),
                          child: Icon(
                              _tasks[index].isCompleted
                                  ? Icons.undo
                                  : Icons.done,
                              color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.startToEnd) {
                            setState(() {
                              _tasks[index].isCompleted =
                                  !_tasks[index].isCompleted;
                              updateTask(_tasks[index]);
                            });
                            return false;
                          } else if (direction == DismissDirection.endToStart) {
                            setState(() {
                              deleteTask(_tasks[index]);
                            });
                          }
                          return true;
                        },
                        child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                            ),
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      _tasks[index].isCompleted
                                          ? const Icon(
                                              Icons.check_circle_outline,
                                              color: Colors.green)
                                          : const SizedBox(),
                                      const SizedBox(height: 0, width: 10),
                                      InkWell(
                                        child: Row(
                                          children: [
                                            Text(_tasks[index].title),
                                            const Icon(Icons.edit_outlined,
                                                color: Colors.grey, size: 18),
                                          ],
                                        ),
                                        onTap: () {
                                          setState(() {
                                            isEdit = true;
                                            currentTask = _tasks[index];
                                            newTaskController.text =
                                                currentTask?.title ?? '';
                                          });
                                          FocusScope.of(context)
                                              .requestFocus(textFieldFocus);
                                        },
                                      )
                                    ],
                                  ),
                                ),
                                const Icon(Icons.reorder)
                              ],
                            )));
                  } else {
                    return Container(key: ValueKey(_tasks[index].id));
                  }
                },
                onReorder: (int oldIndex, int newIndex) {
                  reOrder(oldIndex, newIndex);
                },
              ),
            ),
            const SizedBox(height: 100)
          ],
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.all(20),
          child: TextField(
              controller: newTaskController,
              focusNode: textFieldFocus,
              decoration: InputDecoration(
                  labelText: isEdit ? 'Edit Task' : 'New task',
                  suffix: isEdit
                      ? IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              isEdit = false;
                              currentTask = null;
                              newTaskController.clear();
                            });
                            FocusScope.of(context).unfocus();
                          })
                      : const SizedBox()),
              onSubmitted: (text) {
                if (text != '') {
                  setState(() {
                    if (isEdit) {
                      currentTask?.title = newTaskController.text;
                      updateTask(currentTask!);
                    } else {
                      addTask(text, _selectedDate);
                    }
                    newTaskController.clear();
                    isEdit = false;
                    currentTask = null;
                  });
                }
              }),
        ),
        floatingActionButtonLocation:
            FloatingActionButtonLocation.centerDocked);
  }
}

class Utils {
  static DateTime onlyDate(date) {
    return DateTime(date.year, date.month, date.day);
  }
}
