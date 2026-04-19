/// Platform abstraction for directory picker dialogs.
///
/// Implementations present a native directory-selection UI and return
/// platform-encoded absolute paths. Implementers should return an empty
/// list (for `getDirectoryPaths`) or `null` (for `getDirectoryPath`)
/// when the user cancels the selection, and must ensure returned paths are
/// normalized and absolute.
abstract class FsPickerBase {
    /// Opens a directory picker that allows selecting multiple directories.
    ///
    /// Returns a `Future` that completes with a list of absolute directory
    /// paths selected by the user. If the user cancels the dialog or no
    /// directories are chosen, return an empty list.
    Future<List<String>> getDirectoryPaths();

    /// Opens a directory picker that allows selecting a single directory.
    ///
    /// Returns a `Future` that completes with the absolute path selected by
    /// the user, or `null` if the user cancels the dialog.
    Future<String?> getDirectoryPath();
}