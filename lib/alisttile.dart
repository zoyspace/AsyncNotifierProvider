import 'package:asyncnotifierprovider/riverpoddata.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AListTile extends ConsumerWidget {
  AListTile(this.todo, {Key? key}) : super(key: key);
  Todo todo;
  bool _isRemove = false;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var asyncTile = ref.watch(asyncTileProviderFamily(todo));
    var asyncRead = ref.read(asyncTileProviderFamily(todo).notifier);
    // print(identityHashCode(asyncRead));

    return asyncTile.when(
      data: (data) => _isRemove
          ? const Center(child: Text('removed'))
          : ListTile(
              tileColor: Colors.blue.shade100,
              title: Text(
                data.description,
              ),
              leading: Checkbox(
                  activeColor: Colors.deepOrange,
                  value: data.completed,
                  onChanged: ((value) => asyncRead.toggle(data))),
              trailing: MaterialButton(
                  child: const Icon(Icons.delete),
                  onPressed: () {
                    asyncRead.removeA(data);
                    _isRemove = true;
                  })),
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (err, stack) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('エラー発生tail Error: $err'),
          FloatingActionButton(
              child: const Icon(Icons.redo_outlined),
              onPressed: () => print('rebuild'))
        ],
      ),
    );
  }
}
