import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:go_router/go_router.dart';

class SharedAxisTransitionPage<T> extends CustomTransitionPage<T> {
  /// Constructor for a page with no transition functionality.
  SharedAxisTransitionPage({
    required super.child,
    super.name,
    super.arguments,
    super.restorationId,
    super.key,
    SharedAxisTransitionType transitionType = SharedAxisTransitionType.vertical,
  }) : super(
         transitionsBuilder: (_, animation, secondary, child) {
           return SharedAxisTransition(
             animation: animation,
             secondaryAnimation: secondary,
             transitionType: transitionType,
             fillColor: Colors.transparent,
             child: child,
           );
         },
         transitionDuration: const Duration(milliseconds: 300),
         reverseTransitionDuration: const Duration(milliseconds: 300),
       );
}
