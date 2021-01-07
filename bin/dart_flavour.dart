import 'dart:convert';
import 'dart:io';

void main(List<String> arguments) async {
  try {
    final first = arguments.first;
    await _do(first);
  } on Exception catch (e) {
    _exit(e.toString());
  }
}

Future _do(String arg) async {
  final currentDir = Directory.current.absolute;
  final fileName = "flavor.json";
  final file = File("${currentDir.path}/$fileName");

  final fileData = await file.readAsString();
  final map = jsonDecode(fileData);

  if (map is Map) {
    if (map.containsKey(arg)) {
      final filesToBeReplaced = map[arg];
      if (filesToBeReplaced is List) {
        if (filesToBeReplaced.isNotEmpty) {
          if (map.containsKey("files_to_flavorize")) {
            final files = map["files_to_flavorize"];
            if(files is List){
              if(files.isNotEmpty){
                _validate(files);
                _validate(filesToBeReplaced);
                _replace(files,filesToBeReplaced);
              } else {
                throw Exception("'files_to_flavorize' value is empty");
              }
            } else {
              throw Exception("'files_to_flavorize' value is not a List");
            }
          } else {
            throw Exception("'files_to_flavorize' key isn't declared in flovor.json");
          }
        } else {
          throw Exception("Given flavor is empty");
        }
      } else {
        throw Exception("Given flavor $arg is not well formatted json");
      }
    } else {
      throw Exception("Given flavor $arg doesn't in flavor.json");
    }
  } else {
    _exit("flavor.json is not well formatted");
    return;
  }
}

void _replace(List<String> files,List<String> filesToBeReplaced) async {
  if(files.length!=filesToBeReplaced.length){
    _exit("files_to_flavorize and the the given flavor should have same length");
    return;
  }
  for(var i=0;i<files.length;i++){
    final done = await _switchFiles(files[i],filesToBeReplaced[i]);
    if(done){
      print("switched ${files[i]} with ${filesToBeReplaced[i]}");
    } else {
      print("unable to switch ${files[i]} with ${filesToBeReplaced[i]},continuing");
    }
  }
}

Future<bool> _switchFiles(original,update) async {
  final uFile = File(update);
  if(await uFile.exists()){    
    try{
      await File(original).writeAsBytes(await uFile.readAsBytes());
      return true;
    } catch (e){
      _exit("unable to write file $original");
      return false;
    }
  } else {
    _exit("File '$update' doesn't exists");
    return false;
  }
}

String _validate(List list){
  for (final l in list){
    if(l is! String){
      _exit("files contain non string values");
      break;
    }
  }
}

void _exit(String s) {
  print(s);
  exit(0);
}
