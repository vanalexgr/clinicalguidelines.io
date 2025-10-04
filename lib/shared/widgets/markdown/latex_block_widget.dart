import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../../theme/theme_extensions.dart';

class LatexBlockWidget extends StatelessWidget {
  const LatexBlockWidget({
    super.key,
    required this.content,
    required this.isInline,
    required this.style,
    required this.isDark,
  });

  final String content;
  final bool isInline;
  final TextStyle style;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final mathWidget = Math.tex(
      content,
      mathStyle: MathStyle.text,
      textStyle: style,
      textScaleFactor: 1,
      onErrorFallback: (error) {
        return Text(content, style: style.copyWith(color: Colors.red));
      },
    );

    if (isInline) {
      return mathWidget;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
      child: Center(child: mathWidget),
    );
  }
}
