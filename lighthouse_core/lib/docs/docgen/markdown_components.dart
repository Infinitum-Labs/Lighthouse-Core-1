part of core.docs;

class Formatting {
  final String? hyperlink;
  final bool italics;
  final bool bold;
  final bool underline;
  final bool strikethrough;
  final bool code;

  const Formatting({
    this.hyperlink,
    this.italics = false,
    this.bold = false,
    this.underline = false,
    this.strikethrough = false,
    this.code = false,
  });

  String applyTo(String obj) {
    if (italics) obj = "*$obj*";
    if (bold) obj = "**$obj**";
    if (underline) obj = "<u>$obj</u>";
    if (strikethrough) obj = "~$obj~";
    if (code) obj = "`$obj`";
    if (hyperlink != null) obj = "[$obj]($hyperlink)";
    return obj;
  }
}

abstract class MarkdownComponent {
  final String value;
  final Formatting formatting;

  MarkdownComponent(this.value, [this.formatting = const Formatting()]);

  String render();
}

class Header1 extends MarkdownComponent {
  Header1(super.value, [super.formatting]);

  @override
  String render() => "# ${formatting.applyTo(value)}";
}

class Header2 extends MarkdownComponent {
  Header2(super.value, [super.formatting]);

  @override
  String render() => "## ${formatting.applyTo(value)}";
}

class Header3 extends MarkdownComponent {
  Header3(super.value, [super.formatting]);

  @override
  String render() => "### ${formatting.applyTo(value)}";
}

class Body extends MarkdownComponent {
  final List<MarkdownComponent> components;

  Body(this.components) : super("");

  @override
  String render() =>
      components.map((MarkdownComponent c) => c.render()).toList().join(' ');
}

class Text extends MarkdownComponent {
  Text(super.value, [super.formatting]);

  @override
  String render() => formatting.applyTo(value);
}

class CodeBlock extends MarkdownComponent {
  CodeBlock(String value) : super(value);

  @override
  String render() {
    return """```dart\n$value```""";
  }
}

class BulletListItem extends MarkdownComponent {
  BulletListItem(super.value, [super.formatting]);

  @override
  String render() => "- ${formatting.applyTo(value)}";
}

class BulletList extends MarkdownComponent {
  final List<BulletListItem> children;

  BulletList(this.children) : super("");

  @override
  String render() {
    final List<String> result = [];
    LoopUtils.iterateOver<BulletListItem>(children, (BulletListItem item) {
      result.add(item.render());
    });
    return result.join('\n');
  }
}

class Divider extends MarkdownComponent {
  Divider() : super("");

  @override
  String render() => "\n---\n";
}

class Callout extends MarkdownComponent {
  final String title;

  Callout(this.title, super.value, [super.formatting]);

  @override
  String render() {
    return "<aside>${formatting.applyTo(title)}\n${formatting.applyTo(value)}\n</aside>";
  }
}
