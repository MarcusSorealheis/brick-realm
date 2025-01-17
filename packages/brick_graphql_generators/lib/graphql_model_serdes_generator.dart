import 'package:analyzer/dart/element/element.dart';
import 'package:brick_build/generators.dart' show ProviderSerializableGenerator, SerdesGenerator;
import 'package:brick_graphql/graphql.dart';
import 'package:brick_graphql_generators/src/graphql_deserialize.dart';
import 'package:brick_graphql_generators/src/graphql_fields.dart';
import 'package:brick_graphql_generators/src/graphql_serializable_query_transformer_extended.dart';
import 'package:brick_graphql_generators/src/graphql_serialize.dart';
import 'package:source_gen/source_gen.dart';

/// Digest a `graphqlConfig` (`@ConnectOfflineFirstWithGraphQL`) from [reader] and manage serdes generators
/// to and from a `GraphqlProvider`.
class GraphqlModelSerdesGenerator
    extends ProviderSerializableGenerator<GraphqlSerializableExtended> {
  /// Repository prefix passed to the generators. `Repository` will be appended and
  /// should not be included.
  final String repositoryName;

  GraphqlModelSerdesGenerator(
    Element element,
    ConstantReader reader, {
    required this.repositoryName,
  }) : super(element, reader, configKey: 'graphqlConfig');

  @override
  GraphqlSerializableExtended get config {
    if (reader.peek(configKey) == null) {
      return GraphqlSerializableExtended();
    }

    final fieldRenameIndex =
        withinConfigKey('fieldRename')?.objectValue.getField('index')?.toIntValue();
    final fieldRename = fieldRenameIndex != null ? FieldRename.values[fieldRenameIndex] : null;
    final function = withinConfigKey('queryOperationTransformer')?.objectValue.toFunctionValue();
    var functionName = function?.enclosingElement3.name;
    if (function is ConstructorElement) {
      functionName = '$functionName.new';
    }

    return GraphqlSerializableExtended(
      fieldRename: fieldRename ?? GraphqlSerializable.defaults.fieldRename,
      queryOperationTransformerName: functionName,
    );
  }

  @override
  List<SerdesGenerator> get generators {
    final classElement = element as ClassElement;
    final fields = GraphqlFields(classElement, config);
    return [
      GraphqlDeserialize(classElement, fields, repositoryName: repositoryName),
      GraphqlSerialize(classElement, fields, repositoryName: repositoryName),
    ];
  }
}
