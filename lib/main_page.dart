import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_diary/add_page.dart';
import 'package:path_provider/path_provider.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Main(),
    );
  }
}

class Main extends StatefulWidget {
  const Main({
    super.key,
  });

  @override
  State<Main> createState() => _MainState();
}

class _MainState extends State<Main> {
  Directory? directory;
  String filePath = 'msg.json';
  String fileName = '';
  dynamic myList = const Text('준비');

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // 비동기를 바로 쓸 수 없음
    getPath().then((value) {
      showList();
    });
  }

  Future<void> getPath() async {
    directory = await getApplicationSupportDirectory(); // 모든 플랫폼에서 사용 가능하기 때문에
    if (directory != null) {
      var fileName = 'diary.json';
      filePath = '${directory!.path}/$fileName'; // 경로/경로/diary.json
      print(filePath);
    }
  }

  // 삭제
  Future<void> deleteFile() async {
    try {
      var file = File(filePath);
      var result = file.delete().then((value) {
        print(value);
      });
      print(result.toString());
    } catch (e) {
      print('delete error');
    }
  }

  Future<void> deleteContents(int index) async {
    try {
      // 파일을 불러옴 -> 그것을 [{}, {}] -> jsondecode해서 List<map<dynamic>>으로 변환
      File file = File(filePath);
      var fileContents = await file.readAsString();
      var dataList = jsonDecode(fileContents) as List<dynamic>;

      // List니까 배열 조작
      dataList.removeAt(index);

      // List<map<dyanmic>>을 jsonencode (string으로 변환) -> 다시 파일에 쓰기
      var jsondata = jsonEncode(dataList); // 변수 map을 다시 json으로 변환
      await file.writeAsString(jsondata).then((value) {
        // showList()
        showList();
      });
    } catch (e) {
      print('errer');
    }
  }

  Future<void> showList() async {
    try {
      var file = File(filePath);
      if (file.existsSync()) {
        setState(() {
          myList = FutureBuilder(
              future: file.readAsString(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  var d = snapshot.data; // String = [{'a' : 'b'}]
                  var dataList = jsonDecode(d!) as List<dynamic>;
                  if (dataList.isEmpty) {
                    return const Text('내용이 없습니다');
                  }
                  return ListView.separated(
                    itemBuilder: (context, index) {
                      var data = dataList[index] as Map<String, dynamic>;
                      return ListTile(
                        title: Text(data['title']),
                        subtitle: Text(data['contents']),
                        trailing: IconButton(
                            onPressed: () {
                              deleteContents(index);
                            },
                            icon: const Icon(Icons.delete)),
                      );
                    },
                    separatorBuilder: (context, index) => const Divider(),
                    itemCount: dataList.length,
                  );
                } else {
                  return const CircularProgressIndicator();
                }
              });
        });
      } else {
        setState(() {
          print('파일이 없습니다.');
        });
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(50.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () {
                    ListView;
                  },
                  child: const Text('조회'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final selectedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2023),
                      lastDate: DateTime.now(),
                    ).then((value) => {});
                  },
                  child: const Icon(Icons.date_range),
                ),
                ElevatedButton(
                  onPressed: () {
                    deleteFile();
                  },
                  child: const Text('삭제'),
                )
              ],
            ),
            Expanded(child: myList),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          var result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddPage(
                filePath: filePath,
              ),
            ),
          );
          print(result);
          if (result == 'ok') {
            //결과 출력
            showList();
          }
        },
        child: const Icon(Icons.pest_control_outlined),
      ),
    );
  }
}
