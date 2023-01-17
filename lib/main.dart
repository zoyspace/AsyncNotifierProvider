import 'package:asyncnotifierprovider/riverpoddata.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const TodoListView(),
    );
  }
}

class TodoListView extends ConsumerWidget {
  const TodoListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // rebuild the widget when the todo list changes
    final asyncTodos = ref.watch(asyncTodosProvider);
    final asyncFunc = ref.read(asyncTodosProvider.notifier);
    TextEditingController addTextController = TextEditingController();

    // Let's render the todos in a scrollable list view
    return Scaffold(
      appBar: AppBar(title: const Text('Notion todo list')),
      body: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    fillColor: Color.fromARGB(255, 144, 202, 249),
                    filled: true,
                    // icon: Icon(Icons.add),
                    // hintText: "shopping",
                    // labelText: "add todo",
                  ),
                  controller: addTextController,
                ),
              ),
              FloatingActionButton(
                  child: const Icon(Icons.add),
                  onPressed: () => asyncFunc.addTodo(addTextController.text))
            ],
          ),
          Expanded(
            child: asyncTodos.when(
              data: (todos) => ListView(
                children: [
                  for (final todo in todos)
                    ListTile(
                      tileColor: Colors.blue.shade200,
                      title: Text(todo.description),
                      leading: Checkbox(
                          activeColor: Colors.deepOrange,
                          value: todo.completed,
                          onChanged: ((value) =>
                              asyncFunc.toggle(todo.pageId, !todo.completed))
                          // When tapping on the todo, change its completed status
                          ),
                      trailing: MaterialButton(
                          child: const Icon(Icons.delete),
                          onPressed: () => asyncFunc.removeTodo(todo.pageId)),
                    ),
                ],
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (err, stack) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('エラー発生！　Error: $err'),
                  FloatingActionButton(
                      child: const Icon(Icons.redo_outlined),
                      onPressed: () => asyncFunc.rebuild())
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
