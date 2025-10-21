import 'package:flutter/material.dart';
import 'database_helper.dart';

// Here we are using a global variable. You can use something like
// get_it in a production app.
final dbHelper = DatabaseHelper();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // initialize the database
  await dbHelper.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SQFlite Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _completedController = TextEditingController();
  List<Map<String, dynamic>> tasks = [];

  @override
  void initState() {
    super.initState();
    _collectData();
  }

  void _collectData() async {
    final data = await dbHelper.getItemsAsList();
    setState(() {
      tasks = data;
    });
  }


  void _showAlert(String title, String content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }
  void _add() {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController textController = TextEditingController();

        return AlertDialog(
          title: const Text('Enter Task'),
          content: TextField(
            controller: textController,
            decoration: const InputDecoration(hintText: 'Type your task here'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final taskName = textController.text.trim();
                if (taskName.isNotEmpty) {
                  await dbHelper.insert({
                    DatabaseHelper.columnName: taskName,
                    DatabaseHelper.completed: 0,
                  });

                  _collectData();
                }

                Navigator.of(context).pop(); 
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }


  void _insert() async {
    Map<String, dynamic> row = {
      DatabaseHelper.columnName: _nameController.text,
      DatabaseHelper.completed: int.parse(_completedController.text),
    };
    final id = await dbHelper.insert(row);
    debugPrint('inserted row id: $id');
    _showAlert('Insert', 'Inserted row id: $id');
  }

  void _update() async {
    Map<String, dynamic> row = {
      DatabaseHelper.columnId: int.parse(_idController.text),
      DatabaseHelper.columnName: _nameController.text,
      DatabaseHelper.completed: int.parse(_completedController.text),
    };
    final rowsAffected = await dbHelper.update(row);
    debugPrint('updated $rowsAffected row(s)');
    _showAlert('Update', 'Updated $rowsAffected row(s)');
  }

  void _delete() async {
    final id = int.parse(_idController.text);
    final rowsDeleted = await dbHelper.delete(id);
    debugPrint('deleted $rowsDeleted row(s): row $id');
    _showAlert('Delete', 'Deleted $rowsDeleted row(s): row $id');
  }
  void _deleteAllC() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Delete All'),
          content: Text('Are you sure you want to delete all records?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAll();
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }
  void _deleteAll() async {
    final rowsDeleted = await dbHelper.deleteAll();
    debugPrint('Deleted $rowsDeleted row(s)');
    _showAlert('Delete All', 'Deleted $rowsDeleted row(s)');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('sqflite')),
      body: tasks.isEmpty
    ? const Center(child: Text('No tasks yet.'))
    : ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          final id = task[DatabaseHelper.columnId];
          final name = task[DatabaseHelper.columnName];
          final isCompleted = (task['completed'] ?? 0) == 1;

          return ListTile(
            title: Text(
              name,
              style: TextStyle(
                decoration:
                    isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                color: isCompleted ? Colors.grey : Colors.black,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    isCompleted
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    color: isCompleted ? Colors.green : Colors.grey,
                  ),
                  onPressed: () async {
                    await dbHelper.update({
                      DatabaseHelper.columnId: id,
                      DatabaseHelper.columnName: name,
                      'completed': isCompleted ? 0 : 1,
                    });
                    _collectData();
                  },
                ),
                // 🗑️ Delete button
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await dbHelper.delete(id);
                    _collectData();
                  },
                ),
              ],
            ),
          );
        },
      ),

      
      floatingActionButton: Stack(
        children: [
          Positioned(
            left: 30,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: _deleteAllC,
              tooltip: 'delete',
              child: Icon(Icons.delete),
            ),
          ), 
          Positioned(
            right: 0,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: _add,
              tooltip: 'add',
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}