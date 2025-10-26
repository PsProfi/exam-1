import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TodoApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TODO List',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      home: const TodoPage(),
    );
  }
}

class Todo {
  final int id;
  final String title;
  final bool completed;

  const Todo({required this.id, required this.title, required this.completed});

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'],
      title: json['title'],
      completed: json['completed'],
    );
  }
}

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  final TextEditingController _controller = TextEditingController();
  final String apiUrl = 'http://127.0.0.1:8000/todos';
  List<Todo> todos = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    fetchTodos();
  }

  Future<void> fetchTodos() async {
    try {
      setState(() => loading = true);
      final res = await http.get(Uri.parse(apiUrl));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        setState(() {
          todos = data.map((e) => Todo.fromJson(e)).toList();
        });
      }
    } catch (e) {
      debugPrint('❌ Error fetching todos: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> addTodo() async {
    if (_controller.text.isEmpty) return;
    try {
      final res = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'title': _controller.text}),
      );
      if (res.statusCode == 200) {
        _controller.clear();
        fetchTodos();
      }
    } catch (e) {
      debugPrint('❌ Error adding todo: $e');
    }
  }

  Future<void> toggleTodoStatus(Todo todo) async {
    try {
      await http.put(
        Uri.parse('$apiUrl/${todo.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': todo.id, 'title': todo.title, 'completed': !todo.completed}),
      );
      fetchTodos();
    } catch (e) {
      debugPrint('❌ Error updating todo: $e');
    }
  }

  Future<void> deleteTodo(int id) async {
    try {
      await http.delete(Uri.parse('$apiUrl/$id'));
      fetchTodos();
    } catch (e) {
      debugPrint('❌ Error deleting todo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TODO List')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                        hintText: 'Enter a task...', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: addTodo, child: const Text('Add')),
              ],
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: todos.length,
                    itemBuilder: (context, i) {
                      final todo = todos[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
                          leading: Checkbox(
                            value: todo.completed,
                            onChanged: (_) => toggleTodoStatus(todo),
                          ),
                          title: Text(
                            todo.title,
                            style: TextStyle(
                                decoration: todo.completed
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none),
                          ),
                          trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => deleteTodo(todo.id)),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
