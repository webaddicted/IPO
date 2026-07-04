import 'package:flutter/material.dart';

abstract class BaseStatefulWidget extends StatefulWidget {
  const BaseStatefulWidget({super.key});
}

abstract class BaseState<T extends BaseStatefulWidget> extends State<T> {
  Widget initBuild(BuildContext context);

  @protected
  void initUIState() {}

  @protected
  void onDispose() {}

  @override
  void initState() {
    super.initState();
    initUIState();
  }

  @override
  void dispose() {
    onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => initBuild(context);
}
