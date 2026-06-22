import 'package:abigotado_dev/src/app/theme/app_colors.dart';
import 'package:abigotado_dev/src/features/hero/state/build_phase.dart';
import 'package:abigotado_dev/src/features/hero/widget/build_tag_style.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildTagStyle', () {
    group('planning → DEBUG style', () {
      test(
        'planning → DEBUG/accentRed/accentAmber record',
        () {
          expect(
            buildTagStyle(BuildPhase.planning),
            equals(
              (
                label: 'DEBUG',
                background: AppColors.accentRed,
                foreground: AppColors.accentAmber,
              ),
            ),
          );
        },
      );
    });

    group('coding → DEBUG style', () {
      test(
        'coding → DEBUG/accentRed/accentAmber record',
        () {
          expect(
            buildTagStyle(BuildPhase.coding),
            equals(
              (
                label: 'DEBUG',
                background: AppColors.accentRed,
                foreground: AppColors.accentAmber,
              ),
            ),
          );
        },
      );
    });

    group('reviewing → DEBUG style', () {
      test(
        'reviewing → DEBUG/accentRed/accentAmber record',
        () {
          expect(
            buildTagStyle(BuildPhase.reviewing),
            equals(
              (
                label: 'DEBUG',
                background: AppColors.accentRed,
                foreground: AppColors.accentAmber,
              ),
            ),
          );
        },
      );
    });

    group('released → RELEASE style', () {
      test(
        'released → RELEASE/accentGreen/background record',
        () {
          expect(
            buildTagStyle(BuildPhase.released),
            equals(
              (
                label: 'RELEASE',
                background: AppColors.accentGreen,
                foreground: AppColors.background,
              ),
            ),
          );
        },
      );
    });
  });
}
