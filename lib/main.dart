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

    // Let's render the todos in a scrollable list view
    return Scaffold(
      body: asyncTodos.when(
        data: (todos) => ListView(
          children: [
            for (final todo in todos)
              CheckboxListTile(
                value: todo.completed,
                // When tapping on the todo, change its completed status
                onChanged: (value) => ref
                    .read(asyncTodosProvider.notifier)
                    .toggle(todo.pageId, !todo.completed),
                // ref.read(asyncTodosProvider.notifier).toggle(todo.id),
                title: Text(todo.description),
              ),
          ],
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (err, stack) => Text('エラー発生！　Error: $err'),
      ),
    );
  }
}
