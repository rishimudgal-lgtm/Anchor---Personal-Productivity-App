import 'package:flutter/material.dart';

/// Owns text controllers for as long as a dialog route keeps its fields alive.
///
/// A dialog result is delivered as soon as the route starts popping, so code
/// after `await showDialog` can run before the reverse transition unmounts its
/// `EditableText` widgets. Disposing the controllers in that caller can race
/// those still-mounted fields.
class DialogControllerOwner extends StatefulWidget {
  const DialogControllerOwner({
    super.key,
    required this.controllers,
    required this.child,
  });

  final List<TextEditingController> controllers;
  final Widget child;

  @override
  State<DialogControllerOwner> createState() => _DialogControllerOwnerState();
}

class _DialogControllerOwnerState extends State<DialogControllerOwner> {
  @override
  Widget build(BuildContext context) => widget.child;

  @override
  void dispose() {
    for (final controller in widget.controllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
