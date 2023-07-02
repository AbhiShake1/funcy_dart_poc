// void main() {
//   final person = PersonModel.fromJson({'name': 'abhi2', 'age_num': 21, 'salary': 30000}).then(({int? ageNum, name, salary}) {
//     print('$name, $ageNum, $salary');
//   });
//   print(person('name'));
//   print(person.toJson());
// }
//
// void PersonModel({required String name, int ageNum = 18}) {}

void main() {
  final person = PersonModel.fromJson({'name': 'abhi2', 'age_num': 21, 'salary': 30000}).then(PersonModel).ifCondition(
        (schema) => schema('name') != 'abhi',
        then: PersonModel,
      );
  print(person('name'));
  print(person.toJson());
}

void PersonModel({required String name, int ageNum = 18}) {
  print('$name');
}

// abstract class Models {
//   static void PersonModel({required String name, int age = 18});
// }

class KhaltiSchema {
  final Map<String, dynamic> _schema;
  final Map<String, dynamic> _json;

  const KhaltiSchema(this._json, this._schema);

  factory KhaltiSchema.fromJson(Function schema, Map<String, dynamic> json) {
    return KhaltiSchema(json, _fillFunctionParams(schema, json));
  }

  Map<String, dynamic> toJson() => _json;

  @override
  String toString() => toJson().toString();

  @override
  bool operator ==(Object other) {
    if (other is! KhaltiSchema) return false;
    return toJson() == other.toJson();
  }

  dynamic call(String key) => _json[_convertToModifiedConvention(key)];

  dynamic operator [](String key) => (key);

  KhaltiSchema copyWith([Map<String, dynamic>? json]) {
    if (json == null) return this;
    final newJson = _mergeMaps(_json, json);
    return KhaltiSchema(newJson, _schema);
  }

  KhaltiSchema then(Function function) {
    _fillFunctionParams(function, _schema);
    return this;
  }

  KhaltiSchema ifCondition(bool Function(KhaltiSchema schema) predicate, {required Function then}) {
    if (predicate(this)) {
      _fillFunctionParams(then, _schema);
    }
    return this;
  }

  Map<String, dynamic> _mergeMaps(Map<String, dynamic> map1, Map<String, dynamic> map2) {
    Map<String, dynamic> mergedMap = {...map1};

    for (var key in map2.keys) {
      if (map1.containsKey(key)) {
        mergedMap[key] = map2[key];
      }
    }

    return mergedMap;
  }

  static Map<String, dynamic> _fillFunctionParams(Function function, Map<String, dynamic> params) {
    final functionParams = RegExp(r'\((.*?)\)').firstMatch(function.toString())!.group(1)!;
    final paramList = functionParams.replaceAll('}', '').replaceAll('{', '').split(',').map(_toSnakeCase);

    final filledParams = <Symbol, dynamic>{};
    for (final param in paramList) {
      final paramName = param.trim().split(' ').last;
      final defaultValue = param.contains('=') ? param.split('=')[1].trim() : null;

      final snakeCaseParams = _toSnakeCase(paramName);

      if (params.containsKey(snakeCaseParams)) {
        final symbol = Symbol(snakeCaseParams);
        filledParams[symbol] = params[snakeCaseParams];
      } else if (defaultValue != null) {
        final symbol = Symbol(snakeCaseParams);
        filledParams[symbol] = defaultValue;
      }
    }

    final finalParams = Map.fromEntries(filledParams.entries.map((entry) {
      final keyString = entry.key.toString().substring(8, entry.key.toString().length - 2);
      final camelCaseKey = Symbol(
          keyString.split('_').map((part) => part[0].toUpperCase() + part.substring(1)).join('').substring(0, 1).toLowerCase() +
              keyString.split('_').map((part) => part[0].toUpperCase() + part.substring(1)).join('').substring(1));
      return MapEntry(camelCaseKey, entry.value);
    }));

    try {
      Function.apply(function, [], finalParams);
    } catch (_) {
      Function.apply(function, [], filledParams);
    }

    return params;
  }

  static String _toSnakeCase(String str) {
    return str.replaceAllMapped(RegExp('([A-Z])'), (match) => '_${match.group(1)!.toLowerCase()}');
  }

  String _convertToModifiedConvention(String key) {
    return key.replaceAllMapped(RegExp(r'([A-Z])'), (match) => '_${match.group(1)?.toLowerCase()}');
  }
}

extension KhaltiSchemaX on Function {
  KhaltiSchema fromJson(Map<String, dynamic> json) {
    return KhaltiSchema.fromJson(this, json);
  }
}
