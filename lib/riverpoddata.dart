import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '.env.dart'; //NOTION_DATABASEID,NOTION_BEARER_TOKEN

const String urlNotionDBApi =
    'https://api.notion.com/v1/databases/$NOTION_DATABASEID/query';
const String urlNotionPageApi = 'https://api.notion.com/v1/pages/';
const Map<String, String> headersApi = {
  "Authorization": NOTION_BEARER_TOKEN,
  'Notion-Version': '2022-06-28',
  'Content-Type': 'application/json'
};

const Map<String, dynamic> bodyGetApi = {
  "filter": {"or": []},
  "sorts": [
    // {"property": "main", "direction": "ascending"}
    {"timestamp": "created_time", "direction": "ascending"}
  ]
};

final Uri urlDB = Uri.parse(urlNotionDBApi);
final Uri urlPage = Uri.parse(urlNotionPageApi);
final String bodyGet = jsonEncode(bodyGetApi);

//riverpod
/// An immutable state is preferred.
// We could also use packages like Freezed to help with the implementation.
@immutable
class Todo {
  const Todo({
    required this.pageId,
    required this.description,
    required this.completed,
  });

  factory Todo.fromJson(dynamic todo) {
    final String workpageId = todo['id'];
    final String workDescription = todo['properties']['description']
            ['rich_text']
        .map((text) => text['plain_text'])
        .toList()
        .join();
    final bool workCompleted = todo['properties']['completed']['checkbox'];

    return Todo(
      pageId: workpageId,
      description: workDescription,
      completed: workCompleted,
    );
  }
  // All properties should be `final` on our class.
  final String pageId;
  final String description;
  final bool completed;
}

// The Notifier class that will be passed to our NotifierProvider.
// This class should not expose state outside of its "state" property, which means
// no public getters/properties!
// The public methods on this class will be what allow the UI to modify the state.
class AsyncTodosNotifier extends AsyncNotifier<List<Todo>> {
  Future<List<Todo>> _fetchTodos() async {
    final json = await http.post(urlDB, headers: headersApi, body: bodyGet);
    final todos = jsonDecode(json.body);
    final todoList =
        todos["results"].map<Todo>((todo) => Todo.fromJson(todo)).toList();
    return todoList;
  }

  @override
  Future<List<Todo>> build() async {
    // Load initial todo list from the remote repository
    return _fetchTodos();
  }

  Future<void> addTodo(String description) async {
    final String bodyAdd = jsonEncode({
      "parent": {"database_id": NOTION_DATABASEID},
      "properties": {
        "description": {
          "rich_text": [
            {
              "text": {"content": description}
            }
          ]
        }
      }
    });
    // Set the state to loading
    state = const AsyncValue.loading();
    // Add the new todo and reload the todo list from the remote repository
    state = await AsyncValue.guard(() async {
      await http.post(urlPage, headers: headersApi, body: bodyAdd);
      return _fetchTodos();
    });
  }

  // Let's allow removing todos
  Future<void> removeTodo(Todo todo) async {
    final Uri urlPageId = Uri.parse(urlNotionPageApi + todo.pageId);
    final String bodyPatchDel = jsonEncode({"archived": true});
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await http.patch(urlPageId, headers: headersApi, body: bodyPatchDel);

      return _fetchTodos();
    });
  }

  // Let's mark a todo as completed

  Future<void> rebuild() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return _fetchTodos();
    });
  }
}

final asyncTodosProvider =
    AsyncNotifierProvider<AsyncTodosNotifier, List<Todo>>(() {
  return AsyncTodosNotifier();
});

// Finally, we are using NotifierProvider to allow the UI to interact with
// our TodosNotifier class.

class AsyncTileNotifier extends FamilyAsyncNotifier<Todo, Todo> {
  AsyncTileNotifier(this.todo);
  Todo todo;

  @override
  build(Todo arg) async {
    // return await initbuild(Todo todo);
    // Load initial todo list from the remote repository
    return arg;
  }

  Future<Todo> _fetchA(Todo todo) async {
    final Uri urlPageId = Uri.parse(urlNotionPageApi + todo.pageId);

    final json = await http.get(urlPageId, headers: headersApi);
    final aTodo = jsonDecode(json.body);
    return Todo.fromJson(aTodo);
  }

  Future<void> toggle(Todo todo) async {
    final Uri urlPageId = Uri.parse(urlNotionPageApi + todo.pageId);
    final String bodyPatch = jsonEncode({
      "properties": {
        "completed": {"checkbox": !todo.completed}
      }
    });

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await http.patch(urlPageId, headers: headersApi, body: bodyPatch);

      return _fetchA(todo);
    });
  }

  Future<void> removeA(Todo todo) async {
    final Uri urlPageId = Uri.parse(urlNotionPageApi + todo.pageId);
    final String bodyPatchDel = jsonEncode({"archived": true});
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final json =
          await http.patch(urlPageId, headers: headersApi, body: bodyPatchDel);
      final aTodo = jsonDecode(json.body);
      return Todo.fromJson(aTodo);
    });
  }
}

final asyncTileProviderFamily =
    AsyncNotifierProvider.family<AsyncTileNotifier, Todo, Todo>(() {
  return AsyncTileNotifier(
      const Todo(pageId: 'a', description: 'a', completed: false));
});
