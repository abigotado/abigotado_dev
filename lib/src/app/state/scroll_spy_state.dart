import 'package:abigotado_dev/src/app/widget/editor_file.dart';
import 'package:equatable/equatable.dart';

/// A one-shot scroll navigation request.
///
/// The [id] counter ensures that two sequential requests to the same [target]
/// are both honoured — incrementing it makes each request a distinct value
/// under Equatable equality.
final class ScrollRequest extends Equatable {
  /// Creates a scroll request to [target] with a unique [id].
  const ScrollRequest({required this.target, required this.id});

  /// The section to scroll to.
  final EditorFile target;

  /// Monotonically-increasing counter that makes consecutive same-target
  /// requests distinct (so `copyWith` on the notifier state triggers a
  /// listener diff even when the target is unchanged).
  final int id;

  @override
  List<Object?> get props => [target, id];
}

/// Immutable snapshot of the scroll-spy state.
///
/// - [activeFile] is the [EditorFile] whose section is currently in the
///   viewport's activation zone.
/// - [scrollRequest] is a pending one-shot navigation request, or `null`
///   when there is no pending request. The notifier clears it after the host
///   has dispatched the scroll.
/// - [revealed] is the set of [EditorFile]s whose sections have crossed the
///   reveal line at least once (one-shot latch, monotonically growing).
/// - [hasMeasured] is `true` once the host has performed at least one
///   reveal-set measurement. Used as a guard so that `RevealOnScroll` shows
///   content immediately before the first measurement has occurred.
final class ScrollSpyState extends Equatable {
  /// Creates an immutable scroll-spy state snapshot.
  const ScrollSpyState({
    this.activeFile = EditorFile.fileHero,
    this.scrollRequest,
    this.revealed = const {},
    this.hasMeasured = false,
  });

  /// The file whose section is currently active in the viewport.
  final EditorFile activeFile;

  /// A pending scroll-to request, or `null` if none is queued.
  final ScrollRequest? scrollRequest;

  /// The set of files whose sections have entered the reveal zone at least
  /// once. This set only ever grows — it is a one-shot latch per file.
  final Set<EditorFile> revealed;

  /// Whether the host has completed at least one reveal-set measurement.
  ///
  /// While `false`, `RevealOnScroll` treats every section as already revealed
  /// so that content is visible before the first scroll-listener fires.
  final bool hasMeasured;

  /// Returns a copy of this state with the provided fields overridden.
  ///
  /// Pass `scrollRequest: null` explicitly to clear a pending request;
  /// omitting the parameter preserves the current value. This is the single
  /// state-update path — direct construction is reserved for the notifier's
  /// `build` method.
  ScrollSpyState copyWith({
    EditorFile? activeFile,
    // Sentinel distinguishes "pass null explicitly" from "omit the parameter".
    Object? scrollRequest = _omit,
    Set<EditorFile>? revealed,
    bool? hasMeasured,
  }) {
    return ScrollSpyState(
      activeFile: activeFile ?? this.activeFile,
      scrollRequest: scrollRequest == _omit
          ? this.scrollRequest
          : scrollRequest as ScrollRequest?,
      revealed: revealed ?? this.revealed,
      hasMeasured: hasMeasured ?? this.hasMeasured,
    );
  }

  @override
  List<Object?> get props => [activeFile, scrollRequest, revealed, hasMeasured];
}

/// Sentinel value used by [ScrollSpyState.copyWith] to detect omitted
/// arguments — mirrors the sentinel idiom used in effects and locale states.
const Object _omit = Object();
