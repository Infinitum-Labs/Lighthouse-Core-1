library core.docs;

import '../../utils/utils.dart';

part './doc_components.dart';
part './markdown_components.dart';

void main() {
  try {
    print(Generator().generateClassDocumentation(
      "Row",
      constructorSnippet:
          """ProgressBar(this.totalValue, [this.barLength = 30]);""",
      propsSnippet: """final int totalValue;
  int currentValue = 0;
  final int barLength;""",
      methodsSnippet: """@override
  String render() {
    final int progressLength =
        ((currentValue / totalValue) * barLength).round();
    return "[\${'#' * progressLength}\${'_' * (barLength - progressLength)}]";
  }""",
    ).renderMarkdownText());
  } catch (e, st) {
    print(st);
  }
}

class Generator {
  String extractPropertyName(String propertyDeclaration) {
    final String returnable;

    if (propertyDeclaration.contains('=>')) {
      final List<String> chunks = propertyDeclaration.split(" ");
      returnable = chunks[chunks.indexWhere((String s) => s == '=>') - 1];
    } else if (propertyDeclaration.contains("=")) {
      final List<String> chunks = propertyDeclaration.split(" ");
      returnable = chunks[chunks.indexWhere((String s) => s == '=') - 1];
    } else {
      final List<String> chunks =
          propertyDeclaration.split('').reversed.toList();
      final int indexEnd = chunks.indexWhere((String s) => s == ' ');
      returnable = chunks.sublist(1, indexEnd).reversed.join('');
    }

    return returnable;
  }

  String extractMethodName(String methodDeclaration) {
    final List<String> chunks = methodDeclaration.split("");
    final int indexOfStart = chunks.indexWhere((String s) => s == ' ');
    final int indexOfEnd = chunks.indexWhere((String s) => s == '(');
    return chunks.sublist(indexOfStart + 1, indexOfEnd).join("");
  }

  String extractConstructorName(
      String constructorDeclaration, String className) {
    return constructorDeclaration.split("(")[0];
  }

  ClassDoc generateClassDocumentation(String className,
      {required String constructorSnippet,
      required String propsSnippet,
      required String methodsSnippet,
      String lang = 'dart'}) {
    if (methodsSnippet.trim() != '') {
      methodsSnippet = '$methodsSnippet\n';
    }
    final Map<String, String> constructors = {};
    final Map<String, String> properties = {};
    final Map<String, Map<String, String>> methods =
        {}; // { name : { signature:String, declaration:String } }

    final List<String> constr_decl = [];
    constructorSnippet.split("\n").forEach((String line) {
      if (line.trim() != '') constr_decl.add(line);
      if (line.endsWith(';') || line.endsWith('}')) {
        constructors.addAll({
          extractConstructorName(constr_decl.join('\n'), className):
              constr_decl.join('\n')
        });
        constr_decl.clear();
      }
    });

    propsSnippet.split(';').forEach((String chunk) {
      if (chunk.trim() != '')
        properties.addAll({extractPropertyName("$chunk;"): "$chunk;"});
    });

    final List<String> method_decl = [];
    void parseFn() {
      methods.addAll(
        {
          extractMethodName(method_decl.join('\n')): {
            'declaration': method_decl.join('\n'),
            'signature': method_decl.first.replaceAll(" {", "")
          }
        },
      );
      method_decl.clear();
    }

    bool parsingFn = true;
    if (methodsSnippet != '') {
      methodsSnippet.split('\n').forEach((String line) {
        if (line.trim() == '') {
          if (parsingFn) {
            if (method_decl.last.trim() == '}') {
              method_decl.add(line);
              parseFn();
              parsingFn = false;
            } else {
              method_decl.add(line);
            }
          }
        } else {
          if (!parsingFn) {
            parsingFn = true;
            method_decl.add(line);
          } else {
            method_decl.add(line);
          }
        }
      });
    }

    return ClassDoc(
      name: className,
      lang: lang,
      constructors: constructors.keys
          .map((String key) =>
              ClassConstructor(name: key, declaration: constructors[key]!))
          .toList(),
      properties: properties.keys
          .map((String key) =>
              ClassProperty(name: key, declaration: properties[key]!))
          .toList(),
      methods: methods.keys
          .map((String key) => ClassMethod(
              name: key,
              signature: methods[key]!['signature']!,
              declaration: methods[key]!['declaration']!))
          .toList(),
    );
  }
}
