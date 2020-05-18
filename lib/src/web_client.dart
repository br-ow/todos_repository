// Copyright 2018 The Flutter Architecture Sample Authors. All rights reserved.
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.
import 'dart:convert';
import 'dart:async';

import 'package:todos_repository_core/todos_repository_core.dart';
import 'package:http/http.dart' as http;

enum HttpRequestStatus {
  NOT_DONE,
  DONE,
  ERROR
}

/// A class that is meant to represent a Client that would be used to call a Web
/// Service. It is responsible for fetching and persisting Todos to and from the
/// cloud.
///
/// Since we're trying to keep this example simple, it doesn't communicate with
/// a real server but simply emulates the functionality.
class WebClient implements TodosRepository {
  final Duration delay;
  static const _todosUrl = 'http://localhost:8888/todos';
  static final _headers = {'Content-Type': 'application/json'};


  const WebClient([this.delay = const Duration(milliseconds: 3000)]);

  /// fetches some Todos from web service
  @override
  Future<List<TodoEntity>> loadTodos() async {
    final response = await http.get(_todosUrl);
    print(response.body);
    List responseJson = json.decode(response.body.toString());
    List<TodoEntity> todoList = createTodoList(responseJson);
    return todoList;
  }

List<TodoEntity> createTodoList(List data) {
  List<TodoEntity> list = new List();

  for (int i = 0; i < data.length; i++) {
    String task = data[i]["task"];
    String id = data[i]["id"].toString();
    String note = data[i]["note"];
    bool complete = data[i]["complete"];
    TodoEntity todo = new TodoEntity(task, id, note, complete);
    list.add(todo);
  }

  return list;
}

  /// Compare the list of todos kept locally with the repo
  /// and update the repo to match.
  @override
  Future<bool> saveTodos(List<TodoEntity> todos) async {
    //HttpRequestStatus httpRequestStatus = HttpRequestStatus.NOT_DONE;
    bool noErrors = true;
    final response = await http.get(_todosUrl);
    print(response.body);
    List responseJson = json.decode(response.body.toString());
    List<TodoEntity> repoList = createTodoList(responseJson);
    List<TodoEntity> temp_todos;
    //delete first
    for (var todo in repoList) {
      temp_todos = []..addAll(todos);
      temp_todos.retainWhere((element) => element.id == todo.id);
      if (temp_todos.isEmpty) {
        if (deleteTodo(todo).toString() == 'false') {
          noErrors = false;
        }
        repoList.remove(todo);
      }
    }

    //add and update
    for (var todo in todos) {
      temp_todos = []..addAll(repoList);
      temp_todos.retainWhere((element) => element.id == todo.id);
      if (temp_todos.isNotEmpty) {
        //just update
        if (updateTodo(todo).toString() == 'false') {
          noErrors = false;
        }

      }
      else {
        //time to add
        if (addTodo(todo).toString() == 'false') {
          noErrors = false;
        }
      }
    }
    return Future.value(noErrors);
  }

  //Add a todo to the repo
  Future<bool> addTodo(TodoEntity todo) async {
    bool success = false;
    final response = await http.post(_todosUrl,
        headers: _headers, body: json.encode({'task': todo.task, 'complete': todo.complete, 'note': todo.note, 'goal_id': 0, 'key_result_id': 0, 'team_id': 0, 'user_id': 0}));
    if (response.statusCode == 200) {
      print(response.body.toString());
      success = true;
    } else {
      success = false;
      print('WebClient.addTodo: HTTP Post Request Error');
    }

    return success;
  }

  //Update a todo in the repo
  Future<bool> updateTodo(TodoEntity todo) async {
    bool success = false;
    int id = int.parse(todo.id);
    final url = '$_todosUrl/$id';
    final response = await http.put(url,
        headers: _headers, body: json.encode({'task': todo.task, 'complete': todo.complete, 'note': todo.note, 'goal_id': 0, 'key_result_id': 0, 'team_id': 0, 'user_id': 0}));
    if (response.statusCode == 200) {
      print(response.body.toString());
      success = true;
    } else {
      success = false;
      print('WebClient.updateTodo: unable to update todo');
    }
  }

  //Delete a todo from the repo
  Future<bool> deleteTodo(TodoEntity todo) async {
    bool success = false;
    int id = int.parse(todo.id);
    final url = '$_todosUrl/$id';
    final response = await http.delete(url, headers: _headers);
    if (response.statusCode == 200) {
      print(response.body.toString());
      success = true;
    } else {
      //throw Exception('Failed to delete data');
      success = false;
      print('WebClient.deleteTodo: failed to delete data');
    }

    return success;
  }

}
