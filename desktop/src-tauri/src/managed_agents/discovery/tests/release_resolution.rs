use std::path::PathBuf;

use super::super::{
    command_search_dirs_for_profile, is_executable_file, resolve_workspace_command,
};

#[cfg(unix)]
#[test]
fn explicit_path_resolution_ignores_non_executable_files() {
    use std::os::unix::fs::PermissionsExt;

    let dir = std::env::temp_dir().join(format!("buzz-discovery-path-{}", uuid::Uuid::new_v4()));
    std::fs::create_dir_all(&dir).expect("create temp dir");
    let bin = dir.join("buzz-acp");
    std::fs::write(&bin, "").expect("write placeholder");
    std::fs::set_permissions(&bin, std::fs::Permissions::from_mode(0o644))
        .expect("chmod placeholder");

    assert!(
        resolve_workspace_command(bin.to_str().expect("utf8 path")).is_none(),
        "non-executable placeholder must not resolve"
    );

    std::fs::set_permissions(&bin, std::fs::Permissions::from_mode(0o755))
        .expect("chmod executable");
    assert_eq!(
        resolve_workspace_command(bin.to_str().expect("utf8 path")),
        Some(bin.clone())
    );

    let _ = std::fs::remove_dir_all(dir);
}

#[test]
fn release_command_search_prefers_bundled_sidecars() {
    let dirs = command_search_dirs_for_profile(
        std::path::Path::new("/workspace"),
        Some(std::path::Path::new("/working-copy")),
        Some(std::path::Path::new(
            "/Applications/Buzz.app/Contents/MacOS",
        )),
        false,
    );

    assert_eq!(
        dirs,
        vec![
            PathBuf::from("/Applications/Buzz.app/Contents/MacOS"),
            PathBuf::from("/workspace/target/release"),
            PathBuf::from("/workspace/target/debug"),
            PathBuf::from("/working-copy/target/release"),
            PathBuf::from("/working-copy/target/debug"),
        ]
    );
}

/// Resolve a command against an explicit, ordered dir list using the same
/// first-executable-wins rule as `resolve_workspace_command`. Keeps the
/// assertion on real files instead of only on directory ordering.
#[cfg(unix)]
fn first_executable_in(dirs: &[PathBuf], file_name: &str) -> Option<PathBuf> {
    dirs.iter()
        .map(|dir| dir.join(file_name))
        .find(|candidate| is_executable_file(candidate))
}

/// Release profile must pick the packaged sidecar even when a workspace
/// artifact with the same name also exists. The ordering tests alone cannot
/// catch a regression here, because they never place real files on disk.
#[cfg(unix)]
#[test]
fn release_resolution_picks_bundled_sidecar_over_workspace_artifact() {
    use std::os::unix::fs::PermissionsExt;

    let root = std::env::temp_dir().join(format!("buzz-sidecar-{}", uuid::Uuid::new_v4()));
    let bundled = root.join("Buzz.app/Contents/MacOS");
    let workspace = root.join("workspace");
    let workspace_release = workspace.join("target/release");
    std::fs::create_dir_all(&bundled).expect("create bundled dir");
    std::fs::create_dir_all(&workspace_release).expect("create workspace target dir");

    for dir in [&bundled, &workspace_release] {
        let bin = dir.join("buzz-acp");
        std::fs::write(&bin, "").expect("write sidecar");
        std::fs::set_permissions(&bin, std::fs::Permissions::from_mode(0o755))
            .expect("chmod sidecar");
    }

    let dirs = command_search_dirs_for_profile(&workspace, None, Some(&bundled), false);
    assert_eq!(
        first_executable_in(&dirs, "buzz-acp"),
        Some(bundled.join("buzz-acp")),
        "release profile must resolve the packaged sidecar, not the workspace artifact"
    );

    let _ = std::fs::remove_dir_all(&root);
}

/// A non-executable packaged sidecar deliberately falls through to the next
/// executable candidate instead of becoming a successful resolution.
#[cfg(unix)]
#[test]
fn release_resolution_falls_back_when_bundled_sidecar_is_not_executable() {
    use std::os::unix::fs::PermissionsExt;

    let root = std::env::temp_dir().join(format!("buzz-sidecar-{}", uuid::Uuid::new_v4()));
    let bundled = root.join("Buzz.app/Contents/MacOS");
    let workspace = root.join("workspace");
    let workspace_release = workspace.join("target/release");
    std::fs::create_dir_all(&bundled).expect("create bundled dir");
    std::fs::create_dir_all(&workspace_release).expect("create workspace target dir");

    let broken = bundled.join("buzz-acp");
    std::fs::write(&broken, "").expect("write bundled sidecar");
    std::fs::set_permissions(&broken, std::fs::Permissions::from_mode(0o644))
        .expect("chmod bundled sidecar non-executable");

    let usable = workspace_release.join("buzz-acp");
    std::fs::write(&usable, "").expect("write workspace sidecar");
    std::fs::set_permissions(&usable, std::fs::Permissions::from_mode(0o755))
        .expect("chmod workspace sidecar");

    let dirs = command_search_dirs_for_profile(&workspace, None, Some(&bundled), false);
    assert_eq!(
        first_executable_in(&dirs, "buzz-acp"),
        Some(usable),
        "a non-executable packaged sidecar must fall through to the workspace artifact"
    );

    let _ = std::fs::remove_dir_all(&root);
}

#[test]
fn debug_command_search_prefers_fresh_workspace_artifacts() {
    let dirs = command_search_dirs_for_profile(
        std::path::Path::new("/workspace"),
        Some(std::path::Path::new("/working-copy")),
        Some(std::path::Path::new(
            "/Applications/Buzz.app/Contents/MacOS",
        )),
        true,
    );

    assert_eq!(
        dirs,
        vec![
            PathBuf::from("/workspace/target/debug"),
            PathBuf::from("/workspace/target/release"),
            PathBuf::from("/working-copy/target/debug"),
            PathBuf::from("/working-copy/target/release"),
            PathBuf::from("/Applications/Buzz.app/Contents/MacOS"),
        ]
    );
}
