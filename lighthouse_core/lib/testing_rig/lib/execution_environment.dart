part of markhor;

class ExecutionEnvironment {
  final Map<String, OutputPipe> pipeRegistry = {};
  final Map<String, InputPipe> inputRegistry = {};
}

class InputPipe {}

class OutputPipe<T> {
  final List<dynamic> _logs = [];
  final List<Map<Object, StackTrace>> _errors = [];
  final List<String> _warnings = [];
  TestResult? testResult;
  T? rawOutput;
  final String testId;

  OutputPipe(this.testId);

  void log(dynamic msg) => _logs.add(msg);

  void err(Object e, StackTrace st) => _errors.add({e: st});

  void warn(String msg) => _warnings.add(msg);

  void setResult(TestResult result) {
    testResult = result;
  }
}
