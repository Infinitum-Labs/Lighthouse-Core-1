part of markhor;

class Console {
  final ExecutionEnvironment environment;
  final TestProcess process;
  final TargetResult target;
  late String windowTitle;
  final List<InterfaceComponent> components = [];
  late List<InterfaceComponent> defaultComponents = [
    Divider(),
    TextLabel(windowTitle),
    Divider(),
  ];

  Console(this.process, this.environment, this.target) {
    windowTitle = "${process.name} [${process.runtimeType.toString()}]";
    if (process is TestSuite) {
    } else if (process is FunctionalTest) {
    } else if (process is PerformanceTest) {
    } else if (process is IntegrationTest) {
    } else if (process is UnitTest) {}
  }

  void clearScreen() => stdout.write("\u001Bc");

  void updateWindow() {
    clearScreen();
    components
      ..clear()
      ..addAll(defaultComponents)
      ..addAll(process.generateInterfaceComponents(0, environment));
    renderComponents();
  }

  void renderComponents() {
    print(components
        .map((InterfaceComponent c) => c.render())
        .toList()
        .join('\n'));
  }

  void disposeComponents() =>
      components.map((InterfaceComponent c) => c.dispose());

  Future<void> runProcess() async {
    components
      ..addAll(defaultComponents)
      ..addAll(process.generateInterfaceComponents(0, environment));
    updateWindow();
    final Timer timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      updateWindow();
    });
    updateWindow();
    await process.run(target, environment).whenComplete(() {
      timer.cancel();
      updateWindow();
      print("\nAll tests completed");
    });
  }
}

abstract class InterfaceComponent {
  String render();

  void dispose() {}
}

class Row extends InterfaceComponent {
  final List<InterfaceComponent> items;
  final int gutterWidth;

  Row(this.items, [this.gutterWidth = 1]);

  @override
  String render() {
    return items
        .map((InterfaceComponent c) => c.render())
        .toList()
        .join(' ' * gutterWidth);
  }
}

class TextLabel extends InterfaceComponent {
  final String content;

  TextLabel(this.content);

  @override
  String render() => content;
}

enum Icon {
  passed,
  failed,
  warning,
  error,
  skipped,
  pending,
  running,
}

class IconLabel extends InterfaceComponent {
  final Icon icon;

  IconLabel(this.icon);

  @override
  String render() {
    switch (icon) {
      case Icon.passed:
        return "✅";
      case Icon.failed:
        return "❌";
      case Icon.warning:
        return "🟡";
      case Icon.error:
        return "🔴";
      case Icon.skipped:
        return "⏭";
      case Icon.pending:
        return "⌛";
      case Icon.running:
        return "⏵";
    }
  }
}

class ProgressBar extends InterfaceComponent {
  final int totalValue;
  int currentValue = 0;
  final int barLength;

  ProgressBar(this.totalValue, [this.barLength = 30]);

  @override
  String render() {
    final int progressLength =
        ((currentValue / totalValue) * barLength).round();
    return "[${'#' * progressLength}${'_' * (barLength - progressLength)}]";
  }
}

class Divider extends InterfaceComponent {
  final int barLength;

  Divider([this.barLength = 30]);

  @override
  String render() => "=" * barLength;
}

class LoadingIndicator extends InterfaceComponent {
  late Timer _timer;
  static const List<String> _loadingSpinner = [
    "⣾",
    "⣽",
    "⣻",
    "⢿",
    "⡿",
    "⣟",
    "⣯",
    "⣷"
  ];
  int state = 0;

  LoadingIndicator() {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (state == 7) {
        state = 0;
      } else {
        state += 1;
      }
    });
  }

  @override
  String render() => _loadingSpinner[state];

  @override
  void dispose() => _timer.cancel();
}

class ListItem extends InterfaceComponent {
  final InterfaceComponent content;
  final ListItem? child;
  int indentLevel;

  ListItem(this.content, {this.indentLevel = 0, this.child});

  @override
  String render() {
    final String childContent;
    if (child != null) {
      child!.indentLevel = indentLevel + 1;
      childContent = '\n' + ' ' * (child!.indentLevel) + child!.render();
    } else {
      childContent = '';
    }
    return ' ' * indentLevel + content.render() + childContent;
  }
}
