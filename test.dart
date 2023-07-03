import 'dart:mirrors';

class PersonModel extends KhaltiModel {
  late String idx;
  late String name;
  late int ageNum = 18;
  late int salary;

  String get primaryKey => idx;
}

void main() {
  final person = PersonModel().fromJson({'name': 'abhi2', 'age_num': 21, 'salary': 30000});
  //     .then<PersonModel>((model) {
  //   // print(model.salary);
  //   return model;
  // });
  //     .then(PersonModel).ifCondition(
  //       ({String? name}) => name == 'abhi',
  //       then: PersonModel,
  //     );
  final res = person.thenReturn((model) => model.ageNum);
  print('age $res');
  // print(person('name'));
  print(person.toJson());
}

abstract class KhaltiModel {}

class KhaltiSchema<T extends KhaltiModel> {
  // final Map<String, dynamic> _schema;
  final Map<String, dynamic> _json;
  final T _model;

  const KhaltiSchema(this._json, this._model);

  factory KhaltiSchema.fromJson(T schema, Map<String, dynamic> json) {
    return KhaltiSchema(json, _fillFunctionParams(schema, json) as T);
  }

  Map<String, dynamic> toJson() => _json;

  @override
  String toString() => toJson().toString();

  @override
  bool operator ==(Object other) {
    if (other is! KhaltiSchema) return false;
    return toJson() == other.toJson();
  }

  dynamic call(String key) => _json[_toSnakeCase(key)];

  dynamic operator [](String key) => (key);

  KhaltiSchema copyWith([Map<String, dynamic>? json]) {
    if (json == null) return this;
    final newJson = _mergeMaps(_json, json);
    return KhaltiSchema(newJson, _model);
  }

  KhaltiSchema then<T extends KhaltiModel>(T Function(T) schema) {
    _fillFunctionParams<T>(schema(_model as T), _json);
    return this;
  }

  M thenReturn<M>(M Function(T) schema) {
    return schema(_model);
  }

  KhaltiSchema ifCondition<T extends KhaltiModel>(bool Function(T) predicate, {required T then}) {
    // if (_fillFunctionParamsBool<T>(predicate, _model)) {
    //   _fillFunctionParams(then, _model);
    // }
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

  // static bool _fillFunctionParamsBool<T extends KhaltiModel>(T Function(T) schema, Map<String, dynamic> params) {
  //   return _fillFunctionParamsAny(schema, params);
  // }

  static KhaltiModel _fillFunctionParamsAny<T extends KhaltiModel, M>(T schema, Map<String, dynamic> params) {
    final filledParams = _fillFunctionParamsRaw<T>(schema, params);
    return filledParams.schema;
    // try {
    //   return Function.apply(schema, [], filledParams.camelCaseParams);
    // } catch (_) {
    //   try {
    //     return Function.apply(schema, [], filledParams.filledParams);
    //   } catch (_) {}
    // }
  }

  static KhaltiModel _fillFunctionParams<T extends KhaltiModel>(T schema, Map<String, dynamic> params) {
    return _fillFunctionParamsRaw(schema, params).schema;
  }

  static _Params _fillFunctionParamsRaw<T extends KhaltiModel>(T schema, Map<String, dynamic> params) {
    final instanceMirror = reflect(schema);
    final classMirror = instanceMirror.type;

    params.forEach((key, value) {
      final fieldName = Symbol(_toCamelCase(key));
      if (classMirror.declarations.containsKey(fieldName)) {
        instanceMirror.setField(fieldName, value);
      }
    });

    final paramList = _getClassFields<T>();

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

    final camelCaseParams = Map.fromEntries(filledParams.entries.map((entry) {
      final keyString = entry.key.toString().substring(8, entry.key.toString().length - 2);
      final camelCaseKey = Symbol(
          keyString.split('_').map((part) => part[0].toUpperCase() + part.substring(1)).join('').substring(0, 1).toLowerCase() +
              keyString.split('_').map((part) => part[0].toUpperCase() + part.substring(1)).join('').substring(1));
      return MapEntry(camelCaseKey, entry.value);
    }));

    return _Params(
      camelCaseParams: camelCaseParams,
      filledParams: filledParams,
      params: params,
      schema: schema,
    );
  }

  static List<String> _getClassFields<T extends KhaltiModel>() {
    ClassMirror classMirror = reflectClass(T);
    List<String> fields = [];

    classMirror.declarations.forEach((symbol, declarationMirror) {
      if (declarationMirror is VariableMirror && !declarationMirror.isStatic) {
        fields.add(Symbol(symbol.toString()).toString().substring(8));
      }
    });

    return fields;
  }

  static String _toSnakeCase(String str) {
    return str.replaceAllMapped(RegExp('([A-Z])'), (match) => '_${match.group(1)!.toLowerCase()}');
  }

  static String _toCamelCase(String str) {
    return str.replaceAllMapped(RegExp('_([a-z])'), (match) => match.group(1)!.toUpperCase());
  }
}

class _Params<T extends KhaltiModel> {
  _Params({
    required this.schema,
    required this.params,
    required this.filledParams,
    required this.camelCaseParams,
  });

  final T schema;
  final Map<String, dynamic> params;
  final Map<Symbol, dynamic> filledParams;
  final Map<Symbol, dynamic> camelCaseParams;
}

extension KhaltiSchemaX<T extends KhaltiModel> on T {
  KhaltiSchema<T> fromJson(Map<String, dynamic> json) {
    return KhaltiSchema.fromJson(this, json);
  }
}
