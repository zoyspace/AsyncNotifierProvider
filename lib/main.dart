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
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      // border: OutlineInputBorder(
                      //   borderRadius: BorderRadius.circular(10),
                      // ),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Colors.blue,
                          )),
                      // fillColor: Colors.indigoAccent,
                      // filled: true,
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
            const SizedBox(
              height: 10,
            ),
            Expanded(
              child: asyncTodos.when(
                data: (todos) => ListView(
                  children: [
                    for (final todo in todos)
                      ListTile(
                        tileColor: Colors.blue.shade100,
                        title: Text(todo.description),
                        leading: Checkbox(
                            activeColor: Colors.deepOrange,
                            value: todo.completed,
                            onChanged: ((value) => asyncFunc.toggle(todo))
                            // When tapping on the todo, change its completed status
                            ),
                        trailing: MaterialButton(
                            child: const Icon(Icons.delete),
                            onPressed: () => asyncFunc.removeTodo(todo)),
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
      ),
    );
  }
}
