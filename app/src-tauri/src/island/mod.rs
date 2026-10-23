#[cfg(target_os = "macos")]
mod macos;
#[cfg(windows)]
mod windows;

use serde::Serialize;
use specta::Type;
use tauri::{AppHandle, Runtime};
use tauri_specta::Event;

pub(crate) const LABEL: &str = "island";

const CANVAS_WIDTH: f64 = 640.0;
const CANVAS_HEIGHT: f64 = 280.0;

#[derive(Clone, Debug, Serialize, Type, Event)]
#[serde(rename_all = "camelCase")]
pub(crate) struct IslandPlacement {
    pub(crate) notch: Option<Notch>,
    pub(crate) top_inset: u32,
}

#[derive(Clone, Copy, Debug, Serialize, Type)]
pub(crate) struct Notch {
    pub(crate) width: u32,
    pub(crate) height: u32,
}

pub(crate) fn create<R: Runtime>(app: &AppHandle<R>) -> tauri::Result<()> {
    #[cfg(target_os = "macos")]
    return macos::create(app);

    #[cfg(windows)]
    return windows::create(app);
}

#[tauri::command]
#[specta::specta]
#[expect(
    clippy::needless_pass_by_value,
    reason = "Tauri passes the app handle to commands by value"
)]
pub(crate) fn show_island<R: Runtime>(app: AppHandle<R>) {
    #[cfg(target_os = "macos")]
    macos::show(&app);

    #[cfg(windows)]
    windows::show(&app);
}

#[tauri::command]
#[specta::specta]
#[expect(
    clippy::needless_pass_by_value,
    reason = "Tauri passes the app handle to commands by value"
)]
pub(crate) fn hide_island<R: Runtime>(app: AppHandle<R>) {
    #[cfg(target_os = "macos")]
    macos::hide(&app);

    #[cfg(windows)]
    windows::hide(&app);
}

fn announce<R: Runtime>(app: &AppHandle<R>, placement: &IslandPlacement) {
    if let Err(error) = placement.emit_to(app, LABEL) {
        tracing::warn!(%error, "couldn't send the island its placement");
    }
}
