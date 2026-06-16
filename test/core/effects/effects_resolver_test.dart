import 'package:abigotado_dev/src/core/effects/effects_mode.dart';
import 'package:abigotado_dev/src/core/effects/effects_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveEffectsMode', () {
    group('manual choice (tier 1 — wins over everything)', () {
      test(
        'manualChoice=full, osReducedMotion=true, isCompact=true → full',
        () {
          expect(
            resolveEffectsMode(
              osReducedMotion: true,
              isCompact: true,
              manualChoice: EffectsMode.full,
            ),
            equals(EffectsMode.full),
          );
        },
      );

      test(
        'manualChoice=lite, osReducedMotion=false, isCompact=false → lite',
        () {
          expect(
            resolveEffectsMode(
              osReducedMotion: false,
              isCompact: false,
              manualChoice: EffectsMode.lite,
            ),
            equals(EffectsMode.lite),
          );
        },
      );
    });

    group('automatic resolution (no manual choice)', () {
      test(
        'manualChoice=null, osReducedMotion=false, isCompact=false → full',
        () {
          expect(
            resolveEffectsMode(
              osReducedMotion: false,
              isCompact: false,
            ),
            equals(EffectsMode.full),
          );
        },
      );

      test(
        'manualChoice=null, osReducedMotion=true, isCompact=false → lite',
        () {
          expect(
            resolveEffectsMode(
              osReducedMotion: true,
              isCompact: false,
            ),
            equals(EffectsMode.lite),
          );
        },
      );

      test(
        'manualChoice=null, osReducedMotion=false, isCompact=true → lite',
        () {
          expect(
            resolveEffectsMode(
              osReducedMotion: false,
              isCompact: true,
            ),
            equals(EffectsMode.lite),
          );
        },
      );

      test(
        'manualChoice=null, osReducedMotion=true, isCompact=true → lite',
        () {
          expect(
            resolveEffectsMode(
              osReducedMotion: true,
              isCompact: true,
            ),
            equals(EffectsMode.lite),
          );
        },
      );
    });
  });
}
