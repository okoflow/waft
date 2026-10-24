mod island;

use tauri::{Manager, Wry};
use tracing_subscriber::EnvFilter;

const SETTINGS_LABEL: &str = "settings";

fn ipc() -> tauri_specta::Builder<Wry> {
    tauri_specta::Builder::<Wry>::new()
        .commands(tauri_specta::collect_commands![
            island::show_island::<Wry>,
            island::hide_island::<Wry>
        ])
        .events(tauri_specta::collect_events![island::IslandPlacement])
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tracing_subscriber::fmt()
        .with_env_filter(EnvFilter::try_from_default_env().unwrap_or_else(|_| EnvFilter::new("info")))
        .init();

    let ipc = ipc();

    let builder = tauri::Builder::default().plugin(tauri_plugin_single_instance::init(|app, _, _| {
        if let Some(settings) = app.get_webview_window(SETTINGS_LABEL) {
            let _ = settings.show();
            let _ = settings.set_focus();
        }
    }));

    #[cfg(target_os = "macos")]
    let builder = builder.plugin(tauri_nspanel::init());

    let result = builder
        .invoke_handler(ipc.invoke_handler())
        .setup(move |app| {
            ipc.mount_events(app);
            island::create(app.handle())?;

            Ok(())
        })
        .run(tauri::generate_context!());

    if let Err(error) = result {
        tracing::error!(%error, "Waft couldn't start");
        std::process::exit(1);
    }
}

#[cfg(test)]
mod tests {
    #[test]
    fn export_bindings() {
        super::ipc()
            .export(
                specta_typescript::Typescript::default(),
                concat!(env!("CARGO_MANIFEST_DIR"), "/../../ui/src/shared/api/bindings.ts"),
            )
            .expect("the bindings should export");
    }
}
