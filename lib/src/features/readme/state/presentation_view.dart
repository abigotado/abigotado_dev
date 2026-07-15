/// The pane's presentation — the stylized pitch vs the human-readable
/// README document.
///
/// [pitch] is the default landing content (the editor-shell "agents build
/// the page" scroll experience); [readme] is the `README.md` document view
/// opened via [PresentationView.readme]'s entry points (chip, invitation
/// card, sidebar row).
enum PresentationView {
  /// The stylized landing pitch — the default presentation.
  pitch,

  /// The human-readable `README.md` document.
  readme,
}
