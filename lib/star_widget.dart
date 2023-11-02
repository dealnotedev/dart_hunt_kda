import 'package:flutter/cupertino.dart';
import 'package:hunt_stats/generated/assets.dart';

class StarWidget extends StatelessWidget {
  final double fill;
  final double size;

  const StarWidget({super.key, required this.fill, this.size = 16.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(1),
      height: size,
      width: size,
      child: Stack(
        children: [
          Image.asset(
            Assets.assetsCrossWhite20dp,
            width: size,
            height: size,
            filterQuality: FilterQuality.medium,
            color: const Color(0xFF939598).withOpacity(0.5),
          ),
          SizedBox(
            height: size,
            width: size * fill,
            child: Image.asset(
              Assets.assetsCrossWhite20dp,
              alignment: Alignment.centerLeft,
              fit: BoxFit.fitHeight,
              height: size,
              filterQuality: FilterQuality.medium,
              width: size * fill,
              color: const Color(0xFFCEB379),
            ),
          )
        ],
      ),
    );
  }
}