import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme.dart';

class CyberspexMark extends StatelessWidget {
  final double size;

  const CyberspexMark({
    super.key,
    this.size = 54,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            Color(0xFF0EA5E9),
          ],
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.cable_rounded,
            color: Colors.white.withValues(alpha: 0.18),
            size: size * 0.95,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_rounded,
                color: Colors.white,
                size: size * 0.34,
              ),
              const SizedBox(height: 2),
              Text(
                'CXT',
                style: GoogleFonts.bebasNeue(
                  color: Colors.white,
                  fontSize: size * 0.42,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CyberspexWordmark extends StatelessWidget {
  final CrossAxisAlignment alignment;
  final Color titleColor;
  final Color subtitleColor;
  final bool compact;

  const CyberspexWordmark({
    super.key,
    this.alignment = CrossAxisAlignment.start,
    this.titleColor = AppTheme.textPrimary,
    this.subtitleColor = AppTheme.textSecondary,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CyberspexMark(size: compact ? 48 : 58),
        SizedBox(width: compact ? 10 : 14),
        Flexible(
          child: Column(
            crossAxisAlignment: alignment,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'CYBERSPEX',
                style: GoogleFonts.bebasNeue(
                  fontSize: compact ? 28 : 34,
                  letterSpacing: 1.6,
                  color: titleColor,
                  height: 1,
                ),
              ),
              Text(
                'TECHNOLOGIES',
                style: GoogleFonts.bebasNeue(
                  fontSize: compact ? 22 : 26,
                  letterSpacing: 1.8,
                  color: titleColor,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Smart Tech Smart Life',
                style: GoogleFonts.caveat(
                  fontSize: compact ? 18 : 22,
                  color: subtitleColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
