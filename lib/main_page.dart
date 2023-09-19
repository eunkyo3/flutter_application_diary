import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'add_page.dart';
import 'dir_page.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // 자신에게 필요한 언어 locale을 모두 추가
      supportedLocales: [
        Locale('ko'), // 한국어
      ],
      debugShowCheckedModeBanner: false,
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
  String filePath = '';
  late String fileName = '7';

  dynamic myList = const Text(
    '파일을 생성해 주세요!',
    style: TextStyle(fontSize: 30),
  );

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fileName = 'diary.json';
    getPath().then((value) {
      showList();
    });
  }

  Future<void> getPath() async {
    directory = await getApplicationDocumentsDirectory();
    //서포트 디렉토리는 모든 플렛폼에서 지원
    if (directory != null) {
      filePath = '${directory!.path}/$fileName';
      print(filePath);
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
                var dataList = jsonDecode(snapshot.data!) as List<dynamic>;
                if (dataList.isEmpty) {
                  return const Text(
                    '내용이 없습니다!',
                    style: TextStyle(fontSize: 30),
                  );
                }

                return ListView.separated(
                    itemBuilder: (context, index) {
                      var data = dataList[index] as Map<String, dynamic>;
                      return ListTile(
                          title: Text(data['title']),
                          subtitle: Text(data['contents']),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              deleteContents(index);
                            },
                          ));
                    },
                    separatorBuilder: (context, index) => const Divider(),
                    itemCount: dataList.length);
              } else {
                return const CircularProgressIndicator();
              }
            },
          );
        });
      } else {
        setState(() {
          myList = Center(
            child: const Text(
              '파일이 없습니다!',
              style: TextStyle(fontSize: 30),
            ),
          );
        });
      }
    } catch (e) {
      print('errer');
    }
  }

  Future<void> deleteFile() async {
    try {
      var file = File(filePath);
      if (file.existsSync()) {
        file.delete().then(
          (value) {
            print(value);
            showList();
          },
        );
      }
    } catch (e) {
      print('deleteFile error');
    }
  }

  Future<void> deleteContents(int index) async {
    //파일을 불러옴 -> 그것을 [{},{}] -> jsondecode를 해서 List<map<dynamic>>으로 변환
    //List니까 배열 조작 - 원하는 index번지 삭제 가능
    //List<map<dynamic>> 를 jsonencode (String으로 변경) -> 다시 파일에 쓰기
    //showList()
    try {
      File file = File(filePath);
      var fileStr = await file.readAsString();
      var dataList = jsonDecode(fileStr) as List<dynamic>;
      dataList.removeAt(index);
      var jsonData = jsonEncode(dataList);
      var res = await file
          .writeAsString(jsonData, mode: FileMode.write)
          .then((value) => showList());
    } catch (e) {
      print('deleteContents error');
    }
  }

  Future<void> showFileList() async {
    try {
      filePath = directory!.path;
      Directory dic = Directory(filePath);
      var dataList = dic.listSync().toList();
      await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => DirectoryPage(dataList: dataList)),
      );
      getPath().then((value) => showList());
    } catch (e) {
      print('errer');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$fileName'),
      ),
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Column(children: [
          IconButton(
              onPressed: () async {
                var dt = await showDatePicker(
                  locale: const Locale('ko', 'KR'),
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2023),
                  lastDate: DateTime.now(),
                );
                if (dt != null) {
                  setState(() {
                    fileName = '${dt.toString().split(' ')[0]}.json';
                    getPath().then((value) {
                      showList();
                    });
                  });
                }
              },
              icon: const Icon(Icons.calendar_month)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(onPressed: showList, child: const Text('조회')),
              ElevatedButton(onPressed: showFileList, child: const Text('목록')),
              ElevatedButton(onPressed: deleteFile, child: const Text('삭제'))
            ],
          ),
          Expanded(child: myList)
        ]),
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: () async {
            var result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddPage(filePath: filePath),
              ),
            ); //context 화면 순서 관리,
            if (result == "ok") {
              showList();
            }
          },
          child: const Icon(
            Icons.upload_file_sharp,
            size: 35,
          )),
    );
  }
}
