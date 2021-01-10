import 'dart:convert';
import 'dart:io';

const keywordHelp = "help";
const kJsonFilePath = "/flavors/flavors.json";
const kOriginalFilesKey = "files_to_flavorize";
const keywordInit = "init";

Future main(List<String> args) async {
  if (args.isEmpty || args.first.isEmpty) {
    await _help();
  }
  final arg = args.first.toLowerCase();
  if (arg == keywordHelp) {
    await _help();
  }
  if (arg == keywordInit) {
    await _writeFlavorFileWithDemoFiles();
    _exit("initialized flavors for ${Directory.current.path}");
  }
  final jsonMap = await _readFlavorFile();
  if (jsonMap.containsKey(kOriginalFilesKey)) {
    final files_to_flavorize_map = jsonMap[kOriginalFilesKey];
    if (files_to_flavorize_map is Map) {
      try {
        final files_to_flavorize = files_to_flavorize_map
            .map((key, value) => MapEntry(key as String, value as String));

        if (files_to_flavorize.isNotEmpty) {
          if (jsonMap.containsKey(arg)) {
            final fMap = jsonMap[arg];
            if (fMap is Map) {
              try {
                final sMap = fMap.map(
                    (key, value) => MapEntry(key as String, value as String));
                final flavor = Flavor(arg, sMap);
                await flavor.swapFiles(files_to_flavorize);
              } catch (e, s) {
                print(e);
                print(s);
                _exit(
                    "given flavor $arg is not well formatted in the $kJsonFilePath, keys and values must be strings");
              }
            } else {
              _exit(
                  "given flavor $arg is not well formatted in the $kJsonFilePath");
            }
          } else {
            _exit("given flavor doesn't exists");
          }
        } else {
          _exit("no files to flavorize");
        }
      } catch (e) {
        _exit(
          "$kOriginalFilesKey is not formatted well in the file $kJsonFilePath",
        );
      }
    } else {
      _exit(
        "$kOriginalFilesKey is not formatted well in the file $kJsonFilePath",
      );
    }
  } else {
    _exit(
        "$kJsonFilePath doesn't contain a mandatory key 'files_to_flavorize'");
  }
}

Future<Map<String, dynamic>> _readFlavorFile() async {
  Map<String, dynamic> map;
  try {
    final flavorFile = File(_absolutizePath(kJsonFilePath));
    if (flavorFile.existsSync()) {
      final data = await flavorFile.readAsString();
      map = jsonDecode(data);
    } else {
      _exit(
          "$kJsonFilePath doesn't exists, might be its your first run, run with init argument to initialize");
    }
  } catch (e) {
    _exit("unable to read $kJsonFilePath, make sure it exists,");
  }
  if (map is Map) {
    return map;
  } else {
    _exit("$kJsonFilePath is not well formatted");
  }
}

Future _writeFlavorFileWithDemoFiles() async {
  try {
    final flavorFile = File(_absolutizePath("/flavors/flavors.json"));
    await (await File(_absolutizePath("/flavors/demo.txt"))
            .create(recursive: true))
        .writeAsString("original file");
    await (await File(
      _absolutizePath("/flavors/demo_flavor_one.txt"),
    ).create(recursive: true))
        .writeAsString("flavor one file");
    await (await File(
      _absolutizePath("/flavors/demo_flavor_two.txt"),
    ).create(recursive: true))
        .writeAsString("flavor two file");
    await flavorFile.create(recursive: true);
    await flavorFile.writeAsString(
        '''{\r\n  \"files_to_flavorize\": {\r\n    \"demo_file\":\".\/flavors\/demo.txt\"\r\n  },\r\n  \"flavor_one\":{\r\n    \"demo_file\":\".\/flavors\/demo_flavor_one.txt\"\r\n  },\r\n  \"flavor_two\":{\r\n    \"demo_file\":\".\/flavors\/demo_flavor_two.txt\"\r\n  }\r\n}''');
  } catch (e, s) {
    print(e);
    print(s);
    _exit("error writing files");
  }
}

void _help() async {
  final initialized = await File(_absolutizePath("$kJsonFilePath")).exists();
  if (!initialized) {
    print(
      "run 'taste init' at the root of a project to initialize flavorization for the project",
    );
  }
  _exit("go here for online guide>>");
}

void _exit(String s) {
  print(s);
  exit(0);
}

class Flavor {
  final String name;
  final Map<String, String> files;

  Flavor(this.name, this.files);

  Future swapFiles(Map<String, String> files_to_flavorize) async {
    if (files_to_flavorize == null || files_to_flavorize.isEmpty) {
      _exit("'$kOriginalFilesKey' is empty in $kJsonFilePath");
    }
    for (var i = 0; i < files_to_flavorize.length; i++) {
      final key = files_to_flavorize.keys.elementAt(i);
      final value = files_to_flavorize.values.elementAt(i);
      if (files.containsKey(key)) {
        final replace = files[key];
        final replaceFile = File(replace);
        final toReplaceFile = File(value);
        if (await replaceFile.exists()) {
          try {
            await toReplaceFile.writeAsBytes(await replaceFile.readAsBytes());
            print("replaced $key with new one from flavor $name");
          } catch (e) {
            print("unable to write file ${toReplaceFile.path}");
          }
        } else {
          print(
              "file $key doesn't exist at path ${replaceFile.path} for flavor $name");
        }
      } else {
        print("flavor $name isn't applicable to file $key");
      }
    }
  }
}

String _absolutizePath(String path) {
  return Directory.current.path + "$path";
}
