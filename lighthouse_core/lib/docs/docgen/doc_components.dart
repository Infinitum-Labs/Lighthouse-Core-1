part of core.docs;

abstract class DocComponent {
  List<MarkdownComponent> returnRenderables();
  String renderMarkdownText() => returnRenderables()
      .map((MarkdownComponent c) => c.render())
      .toList()
      .join('\n');
}

class ClassDoc extends DocComponent {
  final String name;
  final String lang;
  final List<ClassConstructor> constructors;
  final List<ClassProperty> properties;
  final List<ClassMethod> methods;

  ClassDoc({
    required this.name,
    required this.lang,
    required this.constructors,
    required this.properties,
    required this.methods,
  });

  @override
  List<MarkdownComponent> returnRenderables() {
    final List<MarkdownComponent> components = [
      Body([
        Text('class', const Formatting(code: true)),
        Text(lang, const Formatting(code: true)),
      ]),
      Divider(),
      Header1("Overview"),
      Text("overviewStuff"),
      Header1("See Also"),
      Text("stuffToSee"),
      Header1("Reference"),
    ];
    components.add(Header2("CONSTRUCTORS"));
    constructors.forEach(
        (ClassConstructor c) => components.addAll(c.returnRenderables()));
    components.add(Header2("PROPERTIES"));
    properties
        .forEach((ClassProperty c) => components.addAll(c.returnRenderables()));
    components.add(Header2("METHODS"));
    methods
        .forEach((ClassMethod c) => components.addAll(c.returnRenderables()));
    components.add(Header1("Changelog"));
    return components;
  }
}

class ClassConstructor extends DocComponent {
  final String name;
  final String declaration;

  ClassConstructor({required this.name, required this.declaration});

  @override
  List<MarkdownComponent> returnRenderables() {
    return [
      Header3(name, const Formatting(code: true)),
      Text("summary"),
      Header3("Implementation"),
      Text("description"),
      CodeBlock(declaration),
    ];
  }
}

class ClassMethod extends DocComponent {
  final String name;
  final String signature;
  final String declaration;

  ClassMethod(
      {required this.name, required this.signature, required this.declaration});

  @override
  List<MarkdownComponent> returnRenderables() {
    return [
      Header3(name, const Formatting(code: true)),
      Text("summary"),
      CodeBlock(signature),
      Header3("Implementation"),
      Text("description"),
      CodeBlock(declaration),
    ];
  }
}

class ClassProperty extends DocComponent {
  final String name;
  final String declaration;

  ClassProperty({required this.name, required this.declaration});

  @override
  List<MarkdownComponent> returnRenderables() {
    return [
      Header3(name, const Formatting(code: true)),
      Text("summary"),
      CodeBlock(declaration),
    ];
  }
}
