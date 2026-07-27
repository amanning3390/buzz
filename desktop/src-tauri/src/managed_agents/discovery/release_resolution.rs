use std::path::{Path, PathBuf};

fn profile_target_dirs(root: &Path, debug_profile: bool) -> [PathBuf; 2] {
    if debug_profile {
        // `just dev` builds fresh debug sidecars; never prefer stale release output.
        [root.join("target/debug"), root.join("target/release")]
    } else {
        [root.join("target/release"), root.join("target/debug")]
    }
}

pub(super) fn command_search_dirs_for_profile(
    workspace_root: &Path,
    current_dir: Option<&Path>,
    current_exe_parent: Option<&Path>,
    debug_profile: bool,
) -> Vec<PathBuf> {
    let mut dirs = Vec::new();

    // Release builds must use the sidecars shipped beside the app executable.
    // Workspace paths can still exist on developer machines and may contain
    // stale artifacts that do not match the packaged application.
    if !debug_profile {
        dirs.extend(current_exe_parent.map(Path::to_path_buf));
    }

    dirs.extend(profile_target_dirs(workspace_root, debug_profile));
    if let Some(current_dir) = current_dir {
        dirs.extend(profile_target_dirs(current_dir, debug_profile));
    }

    // Debug builds prefer fresh workspace artifacts while retaining bundled
    // sidecars as a fallback.
    if debug_profile {
        dirs.extend(current_exe_parent.map(Path::to_path_buf));
    }

    dirs.into_iter().fold(Vec::new(), |mut unique, dir| {
        if !unique.contains(&dir) {
            unique.push(dir);
        }
        unique
    })
}

pub(super) fn command_search_dirs() -> Vec<PathBuf> {
    let current_dir = std::env::current_dir().ok();
    let current_exe_parent = std::env::current_exe()
        .ok()
        .and_then(|path| path.parent().map(Path::to_path_buf));

    command_search_dirs_for_profile(
        &super::workspace_root_dir(),
        current_dir.as_deref(),
        current_exe_parent.as_deref(),
        cfg!(debug_assertions),
    )
}

pub(super) fn is_executable_file(path: &Path) -> bool {
    let Ok(metadata) = path.metadata() else {
        return false;
    };
    if !metadata.is_file() {
        return false;
    }

    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        metadata.permissions().mode() & 0o111 != 0
    }

    #[cfg(not(unix))]
    {
        true
    }
}
