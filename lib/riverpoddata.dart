import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '.env.dart';

import 'package:http/http.dart' as http;

// const sampleApiUrl = 'https://api.sampleapis.com/coffee/hot';
const String urlNotionDBApi =
    'https://api.notion.com/v1/databases/$NOTION_DATABASEID/query';
const String urlNotionPageApi = 'https://api.notion.com/v1/pages/';
const Map<String, String> headersApi = {
  "Authorization": NOTION_BEARER_TOKEN,
  'Notion-Version': '2022-06-28',
  'Content-Type': 'application/json'
};

const Map<String, dynamic> bodyGetApi = {
  "filter": {
    "or": [
      // {
      //   "property": "completed",
      //   "checkbox": {"equals": true}
      // },
      // {
      //   "property": "id",
      //   "number": {"greater_than_or_equal_to": 0}
      // }
    ]
  },
  "sorts": [
    {"property": "main", "direction": "ascending"}
  ]
};

final Uri urlDB = Uri.parse(urlNotionDBApi);
final String bodyGet = jsonEncode(bodyGetApi);

//riverpod
/// An immutable state is preferred.
// We could also use packages like Freezed to help with the implementation.
@immutable
class Todo {
  const Todo({
    required this.pageId,
    required this.id,
    required this.description,
    required this.completed,
  });

  factory Todo.fromJson(dynamic todo) {
    final String workPageId = todo['id'];
    final int workId = todo['properties']['id']['number'] ?? 0;
    final String workDescription = todo['properties']['description']
            ['rich_text']
        .map((text) => text['plain_text'])
        .toList()
        .join();
    final bool workCompleted = todo['properties']['completed']['checkbox'];

    return Todo(
      pageId: workPageId,
      id: workId,
      description: workDescription,
      completed: workCompleted,
    );
  }
  // All properties should be `final` on our class.
  final String pageId;
  final int id;
  final String description;
  final bool completed;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'description': description,
        'completed': completed,
      };
}

// The Notifier class that will be passed to our NotifierProvider.
// This class should not expose state outside of its "state" property, which means
// no public getters/properties!
// The public methods on this class will be what allow the UI to modify the state.
class AsyncTodosNotifier extends AsyncNotifier<List<Todo>> {
  Future<List<Todo>> _fetchTodo() async {
    // try {
    final json = await http.post(urlDB, headers: headersApi, body: bodyGet);
    final todos = jsonDecode(json.body);
    final todoList =
        todos["results"].map<Todo>((todo) => Todo.fromJson(todo)).toList();
    // final List<Todo> todoList = todosWork.toList();
    return todoList;
    // } catch (e) {
    //   print(e);
    //   // state =  AsyncValue.error(e,);

    //   return [
    //     Todo(pageId: 'page', id: 0, description: e.toString(), completed: false)
    //   ];
    // }
  }

  @override
  Future<List<Todo>> build() async {
    // Load initial todo list from the remote repository
    state = const AsyncValue.loading();
    return _fetchTodo();
  }

  Future<void> addTodo(String description) async {
    final Uri urlPage = Uri.parse(urlNotionPageApi);
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
      return _fetchTodo();
    });
  }

  // Let's allow removing todos
  Future<void> removeTodo(String pageId) async {
    final Uri urlPage = Uri.parse(urlNotionPageApi + pageId);
    final String bodyPatchDel = jsonEncode({"archived": true});
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await http.patch(urlPage, headers: headersApi, body: bodyPatchDel);

      return _fetchTodo();
    });
  }

  // Let's mark a todo as completed
  Future<void> toggle(String pageId, bool reverseCompleted) async {
    final Uri urlPage = Uri.parse(urlNotionPageApi + pageId);
    final String bodyPatch = jsonEncode({
      "properties": {
        "completed": {"checkbox": reverseCompleted}
      }
    });

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await http.patch(urlPage, headers: headersApi, body: bodyPatch);

      return _fetchTodo();
    });
  }

  Future<void> rebuild() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return _fetchTodo();
    });
  }
}

// Finally, we are using NotifierProvider to allow the UI to interact with
// our TodosNotifier class.
final asyncTodosProvider =
    AsyncNotifierProvider<AsyncTodosNotifier, List<Todo>>(() {
  return AsyncTodosNotifier();
});
