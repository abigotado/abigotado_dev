import 'package:abigotado_dev/src/app/theme/app_sizing.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Plain constant-invariant guard — no widgets. `AppSizing.readmePanelWidth`,
// `.readmePanelBreakpoint`, `.sidebarWidth`, `.contentGutter`, and
// `.contentMaxWidth` are already real, committed constants (contracts
// commit) — this pins the numeric relationship their own doc comments
// derive, so the four tokens can't silently drift apart from each other.
// Born-green: passes today and must STAY green.
// ---------------------------------------------------------------------------

void main() {
  group('AppSizing', () {
    group('readmePanelBreakpoint', () {
      test(
        'clears sidebarWidth + contentGutter + contentMaxWidth + '
        'readmePanelWidth — the content column keeps its full '
        'contentMaxWidth measure the instant the README panel appears',
        () {
          const floor =
              AppSizing.sidebarWidth +
              AppSizing.contentGutter +
              AppSizing.contentMaxWidth +
              AppSizing.readmePanelWidth;

          expect(
            AppSizing.readmePanelBreakpoint,
            greaterThanOrEqualTo(floor),
            reason:
                'a breakpoint narrower than sidebarWidth + contentGutter + '
                'contentMaxWidth + readmePanelWidth ($floor px) would let '
                'the README panel claim its readmePanelWidth px BEFORE the '
                'content column has room for it — squeezing the pitch cards '
                'below AppSizing.contentMaxWidth the moment the panel '
                'appears',
          );
        },
      );
    });
  });
}
