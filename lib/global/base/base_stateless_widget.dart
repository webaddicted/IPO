import 'package:flutter/material.dart';

abstract class BaseStatelessWidget extends StatelessWidget {
  const BaseStatelessWidget({super.key});

  Widget initBuild(BuildContext context);

  @override
  Widget build(BuildContext context) => initBuild(context);
}
