import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class CodeScapeLogo extends StatelessWidget {
  /// darkColor = the parts that are black in the original logo
  /// lightColor = the parts that are white in the original logo
  final Color darkColor;
  final Color lightColor;

  const CodeScapeLogo({
    super.key,
    this.darkColor = blackColor,
    this.lightColor = whiteColor,
  });

  Widget pixel(double size, Color color) {
    return SizedBox(
      width: size,
      height: size,
      child: ColoredBox(color: color),
    );
  }

  Widget bar(double width, double height, Color color) {
    return SizedBox(
      width: width,
      height: height,
      child: ColoredBox(color: color),
    );
  }

  Widget pixelShape({
    required double size,
    required Color color,
    required List<List<int>> blocks,
  }) {
    return SizedBox(
      width: 3 * size,
      height: 5 * size,
      child: Stack(
        children: [
          for (final block in blocks)
            Positioned(
              left: block[0] * size,
              top: block[1] * size,
              child: pixel(size, color),
            ),
        ],
      ),
    );
  }

  Widget leftBracket(double size) {
    return pixelShape(
      size: size,
      color: lightColor,
      blocks: const [
        [1, 0],
        [0, 1],
        [0, 2],
        [0, 3],
        [1, 4],
      ],
    );
  }

  Widget rightBracket(double size) {
    return pixelShape(
      size: size,
      color: lightColor,
      blocks: const [
        [1, 0],
        [2, 1],
        [2, 2],
        [2, 3],
        [1, 4],
      ],
    );
  }

  Widget slash(double size) {
    return SizedBox(
      width: 5 * size,
      height: 5 * size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(left: 0, top: 4 * size, child: pixel(size, darkColor)),
          Positioned(left: size, top: 3 * size, child: pixel(size, darkColor)),
          Positioned(
            left: 2 * size,
            top: 2 * size,
            child: pixel(size, darkColor),
          ),
          Positioned(left: 3 * size, top: size, child: pixel(size, darkColor)),
          Positioned(left: 4 * size, top: 0, child: pixel(size, darkColor)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = constraints.maxWidth / 340;
        final s = 18.0 * scale;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // CODE
            Positioned(
              left: 24 * scale,
              top: 30 * scale,
              child: Text(
                'C O D E',
                style: TextStyle(
                  color: darkColor,
                  fontSize: 16 * scale,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

            // Upper-right black corner
            Positioned(
              left: 230 * scale,
              top: 24 * scale,
              child: bar(68 * scale, s, darkColor),
            ),
            Positioned(
              left: 288 * scale,
              top: 24 * scale,
              child: bar(s, 70 * scale, darkColor),
            ),

            // Lower-left black corner
            Positioned(
              left: 20 * scale,
              top: 156 * scale,
              child: bar(s, 70 * scale, darkColor),
            ),
            Positioned(
              left: 38 * scale,
              top: 208 * scale,
              child: bar(68 * scale, s, darkColor),
            ),

            // </> logo
            Positioned(
              left: -10 * scale,
              right: -5 * scale,
              top: 80 * scale,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    leftBracket(s),
                    SizedBox(width: 7 * scale),
                    slash(s),
                    SizedBox(width: 7 * scale),
                    rightBracket(s),
                  ],
                ),
              ),
            ),

            // SCAPES
            Positioned(
              left: 234 * scale,
              top: 205 * scale,
              child: Text(
                'S C A P E S',
                style: TextStyle(
                  color: lightColor,
                  fontSize: 15 * scale,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
