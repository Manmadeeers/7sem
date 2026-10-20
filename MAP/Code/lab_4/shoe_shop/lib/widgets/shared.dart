import 'package:flutter/material.dart';

import '../theme.dart';

class ShopHeader extends StatelessWidget {
  const ShopHeader({
    super.key,
    required this.title,
    required this.leading,
    required this.trailing,
  });

  final String title;
  final Widget leading;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 18),
      child: Row(
        children: [
          leading,
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class HeaderIcon extends StatelessWidget {
  const HeaderIcon({super.key, required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFECEEEF), width: 1.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(width: 42, height: 42, child: Icon(icon, size: 23)),
      ),
    );
  }
}

class ShoeImage extends StatelessWidget {
  const ShoeImage({
    super.key,
    required this.image,
    this.angle = 0,
    this.shadow = true,
    this.dark = false,
  });

  final String image;
  final double angle;
  final bool shadow;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    Widget photo = Image.asset('assets/images/$image.png', fit: BoxFit.contain);
    if (dark) {
      photo = ColorFiltered(
        colorFilter: const ColorFilter.mode(
          Color(0xFF72777A),
          BlendMode.modulate,
        ),
        child: photo,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        alignment: Alignment.center,
        children: [
          if (shadow)
            Positioned(
              bottom: constraints.maxHeight * .06,
              child: Container(
                width: constraints.maxWidth * .65,
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 9,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.only(bottom: shadow ? 10 : 0),
            child: Transform.rotate(angle: angle, child: photo),
          ),
        ],
      ),
    );
  }
}

class PageDots extends StatelessWidget {
  const PageDots({super.key, this.count = 4});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (index) => Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index == 0
                ? const Color(0xFFE8F5FA)
                : const Color(0xFFE1E3E5),
            border: index == 0
                ? Border.all(color: const Color(0xFFABD8E7))
                : null,
          ),
        ),
      ),
    );
  }
}

class Rating extends StatelessWidget {
  const Rating({super.key, this.small = false});

  final bool small;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star_rounded,
          color: const Color(0xFFF5C400),
          size: small ? 17 : 22,
        ),
        const SizedBox(width: 3),
        Text(
          '4.8',
          style: TextStyle(
            fontSize: small ? 12 : 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
