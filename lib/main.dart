import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';

// Global database helper
final dbHelper = DatabaseHelper();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dbHelper.init();

  // Load saved theme preference
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('isDarkMode') ?? false;

  runApp(MyApp(isDarkMode: isDarkMode));
}

class MyApp extends StatefulWidget {
  final bool isDarkMode;
  const MyApp({super.key, required this.isDarkMode});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
  }

  void _toggleTheme() async {
    setState(() => _isDarkMode = !_isDarkMode);
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', _isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task manager',
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: MyHomePage(
        isDarkMode: _isDarkMode,
        toggleTheme: () {
          setState(() {
            _isDarkMode = !_isDarkMode;
          });
        },
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;
  const MyHomePage({super.key, required this.toggleTheme, required this.isDarkMode});

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
          title: const Text('Confirm Delete All'),
          content: const Text('Are you sure you want to delete all records?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAll();
              },
              child: const Text('Delete'),
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
      appBar: AppBar(
        title: const Text('sqflite'),
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            tooltip: 'Toggle Theme',
            onPressed: widget.toggleTheme,
          ),
        ],
      ),
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
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      color: isCompleted ? Colors.grey : null,
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
              tooltip: 'Delete All',
              child: const Icon(Icons.delete),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: _add,
              tooltip: 'Add Task',
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}
