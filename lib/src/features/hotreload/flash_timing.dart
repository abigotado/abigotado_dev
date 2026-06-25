/// Timing and intensity constants for the hot-reload section-flash wave, plus
/// the pure per-section stagger helper.
///
/// The flash is a **full-mode-only** effect — lite mode never flashes, matching
/// the project's "lite = no animation" contract — so these helpers carry no
/// `EffectsMode` parameter; callers gate on the mode before using them.
library;

/// Duration of a single section's amber flash in full mode.
///
/// Matches the mockup's `.flash` 0.5s keyframe.
const int kFlashAnimMs = 500;

/// Stagger between consecutive sections in the top→bottom wave.
///
/// Matches the mockup's `i * 60ms` cascade.
const int kFlashStaggerMs = 60;

/// Peak opacity of the amber wash at the crest of a section's flash.
///
/// Softer than the mockup's 0.18 to suit the darker production palette.
const double kFlashPeakOpacity = 0.14;

/// The start delay for the section at [order] (0-based, top→bottom) within the
/// full-mode flash wave: `order * kFlashStaggerMs` milliseconds.
///
/// Pure and widget-free — unit-testable in isolation. [order] is the section's
/// document position (0 = first/top), passed in by `LandingPage` rather than
/// derived from enum order, so the wave always follows visual order.
Duration flashDelayForIndex(int order) =>
    Duration(milliseconds: order * kFlashStaggerMs);
