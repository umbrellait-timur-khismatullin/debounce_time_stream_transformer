import 'dart:async';

void main(List<String> arguments) async {
  final controller = StreamController();
  final stream = controller.stream;

  stream.debounceTime(300).listen((event) {
    print(event);
  });
  
  controller.add(1);
  await Future.delayed(Duration(milliseconds: 400));
  controller.add(2);
  controller.add(3);
  await Future.delayed(Duration(milliseconds: 400));
  controller.add(4);
  await Future.delayed(Duration(milliseconds: 400));
  controller.add(5);
  controller.add(6);
  controller.add(7);
  controller.add(8);
  controller.add(9);
  controller.add(10);
}

extension DebounceTime<T> on Stream<T> {
  Stream<T> debounceTime(int milliseconds) =>
      transform(DebounceTimeTransformer(milliseconds));
}

class DebounceTimeTransformer<T> extends StreamTransformerBase<T, T> {
  final int debounceTime;

  DebounceTimeTransformer(this.debounceTime);

  @override
  Stream<T> bind(Stream<T> stream) {
    final controller = stream.isBroadcast
        ? StreamController<T>.broadcast()
        : StreamController<T>();
    return (controller..onListen = () => _onListen(stream, controller)).stream;
  }

  void _onListen(
    Stream<T> stream,
    StreamController<T> controller,
  ) {
    final sink = controller.sink;
    final subscription = stream.listen(null, cancelOnError: false);
    if (!stream.isBroadcast) {
      controller
        ..onPause = subscription.pause
        ..onResume = subscription.resume;
    }
    Timer timer = Timer(Duration(milliseconds: debounceTime), () {});
    subscription
      ..onData(
        (T data) {
          timer = Timer(Duration(milliseconds: debounceTime), () {
            if (timer.tick == 1) {
              sink.add(data);
            }
          });
        },
      )
      ..onError(sink.addError)
      ..onDone(() => sink.close());
  }
}
