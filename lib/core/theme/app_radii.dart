import 'package:flutter/material.dart';

/// Border-radius tokens for RecapCoach.
///
/// We deliberately keep the radius vocabulary short. The most-used token
/// is [md] (12) for cards/buttons/inputs; reserve the larger values for
/// modal sheets and full-bleed surfaces.
class AppRadii {
  AppRadii._();

  /// 6 -- micro radius (small chips, badges)
  static const double xs = 6;

  /// 8 -- small radius (compact buttons, small inputs)
  static const double sm = 8;

  /// 12 -- default radius (most cards, buttons, inputs)
  static const double md = 12;

  /// 16 -- large radius (prominent cards, dialogs)
  static const double lg = 16;

  /// 20 -- bottom sheets, large modals
  static const double xl = 20;

  /// 28 -- "pill" feel for FABs and full-width primary CTAs
  static const double pill = 28;

  /// 9999 -- effectively-circular; used on avatars and round icons
  static const double full = 9999;

  // ---- Convenience wrappers ----

  static BorderRadius all(double r) => BorderRadius.circular(r);

  static const RoundedRectangleBorder cardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(md)),
  );

  static const RoundedRectangleBorder dialogShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(lg)),
  );
}
