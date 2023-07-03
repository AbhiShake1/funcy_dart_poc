import 'dart:mirrors';

class PersonModel extends KhaltiModel {
  late String idx;
  late String name;
  late int gradeCount = 30;
  late int salary;

  String get primaryKey => idx;
}

void main() {
  final person = PersonModel().fromJson({'name': 'abhi2', 'grade_count': 21, 'salary': 30000, 'idx': 'idx1'}).then((model) {
    print(model.name);
  });
  final newPerson = person.copyWith((model) {
    return model..name = 'abhi';
  });
  //     .then<PersonModel>((model) {
  //   // print(model.salary);
  //   return model;
  // });
  //     .then(PersonModel).ifCondition(
  //       ({String? name}) => name == 'abhi',
  //       then: PersonModel,
  //     );
  // final res = person.thenReturn((model) => model.ageNum);
  // print('age $res');
  // print(person('name'));
  print(person.copyWith((model) => model));
  print(person('name'));
  print(newPerson('name'));
}

abstract class KhaltiModel {
  Map<String, dynamic> toJson() {
    final classMirror = reflectClass(runtimeType);
    final instanceMirror = reflect(this);

    final json = <String, dynamic>{};

    classMirror.declarations.forEach((symbol, declarationMirror) {
      if (declarationMirror is VariableMirror && !declarationMirror.isStatic) {
        final field = MirrorSystem.getName(symbol);
        final value = instanceMirror.getField(symbol).reflectee;
        json[field] = value;
      }
    });

    return json;
  }

  @override
  String toString() {
    final mirror = reflect(this);
    final classMirror = mirror.type;
    final className = MirrorSystem.getName(classMirror.simpleName);

    final buffer = StringBuffer();

    classMirror.declarations.values.whereType<VariableMirror>().forEach((variable) {
      final variableName = MirrorSystem.getName(variable.simpleName);
      final variableValue = mirror.getField(variable.simpleName).reflectee;

      buffer.write('$variableName: $variableValue, ');
    });

    final result = buffer.toString().trimRight().replaceFirst(RegExp(r',\s*$'), '');

    return '$className($result)';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.isSetter) {
      final fieldName = MirrorSystem.getName(invocation.memberName);
      final setterName = 'set$fieldName';

      final setterSymbol = Symbol(setterName);
      final setterMirror = reflect(this).type.instanceMembers[setterSymbol];

      if (setterMirror != null) {
        final positionalArgs = [invocation.positionalArguments.first];
        final namedArgs = invocation.namedArguments;
        return reflect(this).invoke(setterMirror.simpleName, positionalArgs, namedArgs).reflectee;
      }
    }

    return super.noSuchMethod(invocation);
  }
}

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

  KhaltiSchema<T> copyWith(T Function(T) schema) {
    final model = schema(_model);
    return KhaltiSchema(model.toJson(), model);
  }

  // KhaltiSchema copyWith(T Function(T) modify) {
  //   modify(_model);
  //   return this;
  //   final newModel = modify(_model);
  //   return KhaltiSchema(_json, newModel);
  // }

  KhaltiSchema<T> then(void Function(T) schema) {
    schema(_model);
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

  static void _fillFunctionParamsVoid<T extends KhaltiModel>(T schema, Map<String, dynamic> params) {
    _fillFunctionParamsRaw(schema, params);
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
