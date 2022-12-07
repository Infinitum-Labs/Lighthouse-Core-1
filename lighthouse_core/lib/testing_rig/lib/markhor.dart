library markhor;

import 'dart:mirrors';
import 'dart:async';
import 'dart:math';
import 'dart:io';

part './utils.dart';
part './console.dart';
part './execution_environment.dart';
part './debugging.dart';

class Markhor {
  final List<TestSuite> testSuites;

  Markhor(this.testSuites);
}

abstract class TestProcess {
  final String name;
  late String testId = "$name-${Utils.randomAlphaNum}";
  late TestResult testResult = TestResult(testId);

  TestProcess(this.name);

  Future<TestResult> run(TargetResult target, ExecutionEnvironment environment);

  List<InterfaceComponent> generateInterfaceComponents(
      int indentLevel, ExecutionEnvironment environment);
}

class TestSuite extends TestProcess {
  final List<FunctionalTest> functionalTests;
  final List<PerformanceTest> performanceTests;

  TestSuite(
    super.name, {
    this.functionalTests = const [],
    this.performanceTests = const [],
  });

  @override
  Future<TestResult> run(
      TargetResult target, ExecutionEnvironment environment) async {
    final int iterationLimit = functionalTests.length;
    bool hasFailed = false;
    for (int i = 0; i < iterationLimit; i++) {
      final TestResult result =
          await functionalTests[i].run(target, environment);
      if (result.status == TestStatus.failed) hasFailed = true;
    }
    testResult.status = hasFailed ? TestStatus.failed : TestStatus.passed;
    return testResult;
  }

  @override
  List<InterfaceComponent> generateInterfaceComponents(
      int indentLevel, ExecutionEnvironment environment) {
    final List<InterfaceComponent> components = [];
    for (int i = 0; i < functionalTests.length; i++) {
      components.addAll(functionalTests[i]
          .generateInterfaceComponents(indentLevel + 2, environment));
    }
    for (int i = 0; i < performanceTests.length; i++) {
      components.addAll(performanceTests[i]
          .generateInterfaceComponents(indentLevel + 2, environment));
    }

    return components;
  }
}

class FunctionalTest extends TestProcess {
  final List<IntegrationTest> integrationTests;

  FunctionalTest(super.name, {this.integrationTests = const []});
  @override
  Future<TestResult> run(
      TargetResult target, ExecutionEnvironment environment) async {
    final int iterationLimit = integrationTests.length;
    bool hasFailed = false;
    for (int i = 0; i < iterationLimit; i++) {
      final TestResult result =
          await integrationTests[i].run(target, environment);
      if (result.status == TestStatus.failed) hasFailed = true;
    }
    testResult.status = hasFailed ? TestStatus.failed : TestStatus.passed;
    return testResult;
  }

  @override
  List<InterfaceComponent> generateInterfaceComponents(
      int indentLevel, ExecutionEnvironment environment) {
    final List<InterfaceComponent> components = [];
    for (int i = 0; i < integrationTests.length; i++) {
      components.addAll(integrationTests[i]
          .generateInterfaceComponents(indentLevel + 2, environment));
    }
    return components;
  }
}

class PerformanceTest extends TestProcess {
  PerformanceTest(super.name);
  @override
  Future<TestResult> run(
      TargetResult target, ExecutionEnvironment environment) {
    // TODO: implement run
    throw UnimplementedError();
  }

  @override
  List<InterfaceComponent> generateInterfaceComponents(
      int indentLevel, ExecutionEnvironment environment) {
    // TODO: implement generateInterfaceComponents
    throw UnimplementedError();
  }
}

class IntegrationTest extends TestProcess {
  final List<UnitTest> unitTests;

  IntegrationTest(super.name, {this.unitTests = const []});

  @override
  Future<TestResult> run(
      TargetResult target, ExecutionEnvironment environment) async {
    final int iterationLimit = unitTests.length;
    bool hasFailed = false;
    for (int i = 0; i < iterationLimit; i++) {
      final TestResult result = await unitTests[i].run(target, environment);
      if (result.status == TestStatus.failed) hasFailed = true;
    }
    testResult.status = hasFailed ? TestStatus.failed : TestStatus.passed;
    return testResult;
  }

  @override
  List<InterfaceComponent> generateInterfaceComponents(
      int indentLevel, ExecutionEnvironment environment) {
    final List<InterfaceComponent> components = [];
    for (int i = 0; i < unitTests.length; i++) {
      components.addAll(unitTests[i]
          .generateInterfaceComponents(indentLevel + 2, environment));
    }
    return components;
  }
}

class UnitTest<T> extends TestProcess {
  final T Function(OutputPipe)? syncAction;
  final Future<T> Function(OutputPipe<T>)? asyncAction;
  final List<ResultReporter> Function(T) reporters;
  late String testId = "$name-${Utils.randomAlphaNum}";
  late OutputPipe<T> outputPipe = OutputPipe<T>(testId);
  late TestResult testResult = TestResult(testId);

  UnitTest(
    super.name, {
    this.syncAction,
    this.asyncAction,
    required this.reporters,
  });

  Future<TestResult> run(
      TargetResult target, ExecutionEnvironment environment) async {
    testResult.status = TestStatus.running;
    environment.pipeRegistry.addAll({testId: outputPipe});
    final T output;
    try {
      if (syncAction != null) {
        output = syncAction!(outputPipe);
      } else if (asyncAction != null) {
        output = await asyncAction!(outputPipe);
      } else {
        throw Exception("Bad Test: ${testId} >> No actions defined");
      }

      outputPipe.rawOutput = output;
      final List<ResultReporter> resultReporters = reporters(output);
      final int iterationLimit = resultReporters.length;
      bool hasFailedResult = false;
      for (int i = 0; i < iterationLimit; i++) {
        final ResultReporter reporter = resultReporters[i];
        final TestStatus status;
        if (target.targets.keys.contains(reporter.id)) {
          if (target.targets[reporter.id]!(reporter.value)) {
            status = TestStatus.passed;
          } else {
            status = TestStatus.failed;
            hasFailedResult = true;
          }
        } else {
          status = TestStatus.skipped;
          outputPipe
              .warn("Reporter (${reporter.id}) SKIPPED result verification");
        }
        testResult.reporterStatuses.addAll({reporter: status});
      }
      testResult.status =
          hasFailedResult ? TestStatus.failed : TestStatus.passed;
    } catch (e, st) {
      outputPipe.err(e, st);
      outputPipe.rawOutput = null;
      testResult.status = TestStatus.failed;
    }
    outputPipe.setResult(testResult);
    return testResult;
  }

  @override
  List<InterfaceComponent> generateInterfaceComponents(
      int indentLevel, ExecutionEnvironment environment) {
    final Map<TestStatus, Icon> iconMap = {
      TestStatus.pending: Icon.pending,
      TestStatus.failed: Icon.failed,
      TestStatus.passed: Icon.passed,
      TestStatus.skipped: Icon.skipped,
      TestStatus.running: Icon.running,
    };
    final Icon icon = iconMap[testResult.status]!;
    final List<InterfaceComponent> components = [
      Row(
        [
          IconLabel(icon),
          TextLabel(name),
        ],
      ),
    ];
    if (outputPipe._logs.isNotEmpty) {
      components.add(ListItem(TextLabel("LOGS"), indentLevel: indentLevel + 2));
      components.addAll(
        outputPipe._logs
            .map((e) => ListItem(TextLabel(e), indentLevel: indentLevel + 4))
            .toList(),
      );
    }
    if (outputPipe._warnings.isNotEmpty) {
      components
          .add(ListItem(TextLabel("WARNINGS"), indentLevel: indentLevel + 2));
      components.addAll(
        outputPipe._warnings
            .map((e) => ListItem(TextLabel(e), indentLevel: indentLevel + 4))
            .toList(),
      );
    }
    if (outputPipe._errors.isNotEmpty) {
      components
          .add(ListItem(TextLabel("ERRORS"), indentLevel: indentLevel + 2));
      components.addAll(
        outputPipe._errors.map((e) {
          return ListItem(
            Row([
              IconLabel(Icon.error),
              TextLabel(e.keys.first.toString()),
            ]),
            indentLevel: indentLevel + 4,
            child: ListItem(
              TextLabel(e[e.keys.first].toString()),
              indentLevel: indentLevel + 6,
            ),
          );
        }).toList(),
      );
    }

    return components;
  }
}

class ResultReporter {
  final String id;
  final dynamic value;

  ResultReporter(this.id, this.value);
}

enum TestStatus {
  pending,
  running,
  passed,
  failed,
  skipped,
}

class TestResult {
  final String testId;
  TestStatus status = TestStatus.pending;
  final Map<ResultReporter, TestStatus> reporterStatuses = {};

  TestResult(this.testId);
}

typedef CheckerFn = bool Function(dynamic);

class TargetResult {
  final Map<String, CheckerFn> targets;

  TargetResult(this.targets);
}
