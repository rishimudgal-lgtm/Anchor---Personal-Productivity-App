import 'package:flutter/material.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 38});

  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: 'Anchor Hub logo',
    child: ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.24),
      child: Image.asset(
        'assets/brand/anchor_hub_logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    ),
  );
}
