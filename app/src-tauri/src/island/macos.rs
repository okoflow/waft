use objc2::MainThreadMarker;
use objc2_app_kit::{NSEvent, NSScreen};
use objc2_foundation::{NSPoint, NSRect, NSSize};
use tauri::utils::config::BackgroundThrottlingPolicy;
use tauri::{AppHandle, Runtime, WebviewUrl};
use tauri_nspanel::{CollectionBehavior, ManagerExt, PanelBuilder, PanelLevel, StyleMask};

use self::panel::IslandPanel;
use super::{CANVAS_HEIGHT, CANVAS_WIDTH, IslandPlacement, LABEL, Notch, announce};

mod panel {
    tauri_nspanel::tauri_panel! {
        panel!(IslandPanel {
            config: {
                can_become_key_window: false,
                can_become_main_window: false,
                is_floating_panel: true
            }
        })
    }
}

pub(super) fn create<R: Runtime>(app: &AppHandle<R>) -> tauri::Result<()> {
    let panel = PanelBuilder::<R, IslandPanel<R>>::new(app, LABEL)
        .url(WebviewUrl::App("island.html".into()))
        .title("Waft")
        .size(tauri::Size::Logical(tauri::LogicalSize::new(
            CANVAS_WIDTH,
            CANVAS_HEIGHT,
        )))
        .level(PanelLevel::Status)
        .has_shadow(false)
        .transparent(true)
        .corner_radius(0.0)
        .no_activate(true)
        .add_style_mask(StyleMask::empty().borderless().nonactivating_panel())
        .collection_behavior(
            CollectionBehavior::new()
                .can_join_all_spaces()
                .full_screen_auxiliary()
                .stationary()
                .ignores_cycle(),
        )
        .with_window(|window| {
            window
                .decorations(false)
                .transparent(true)
                .focusable(false)
                .background_throttling(BackgroundThrottlingPolicy::Suspend)
        })
        .build()
        .map_err(|error| tauri::Error::Anyhow(error.into()))?;

    panel.set_ignores_mouse_events(true);
    panel.hide();

    Ok(())
}

pub(super) fn show<R: Runtime>(app: &AppHandle<R>) {
    let handle = app.clone();

    let result = app.run_on_main_thread(move || {
        let Some(main_thread) = MainThreadMarker::new() else {
            return;
        };

        let Ok(panel) = handle.get_webview_panel(LABEL) else {
            tracing::warn!("the island panel is missing");
            return;
        };

        let Some(screen) = screen_under_mouse(main_thread) else {
            return;
        };

        let frame = screen.frame();
        let origin = NSPoint::new(
            frame.origin.x + (frame.size.width - CANVAS_WIDTH) / 2.0,
            frame.origin.y + frame.size.height - CANVAS_HEIGHT,
        );

        panel
            .as_panel()
            .setFrame_display(NSRect::new(origin, NSSize::new(CANVAS_WIDTH, CANVAS_HEIGHT)), true);

        announce(&handle, &placement(&screen));
        panel.show();
    });

    if let Err(error) = result {
        tracing::warn!(%error, "couldn't show the island");
    }
}

pub(super) fn hide<R: Runtime>(app: &AppHandle<R>) {
    let handle = app.clone();

    let result = app.run_on_main_thread(move || {
        if let Ok(panel) = handle.get_webview_panel(LABEL) {
            panel.hide();
        }
    });

    if let Err(error) = result {
        tracing::warn!(%error, "couldn't hide the island");
    }
}

fn screen_under_mouse(main_thread: MainThreadMarker) -> Option<objc2::rc::Retained<NSScreen>> {
    let mouse = NSEvent::mouseLocation();

    let screens = NSScreen::screens(main_thread);

    let under_mouse = screens.iter().find(|screen| contains(screen.frame(), mouse));

    if under_mouse.is_some() {
        return under_mouse;
    }

    NSScreen::mainScreen(main_thread)
}

fn contains(frame: NSRect, point: NSPoint) -> bool {
    let horizontally = point.x >= frame.origin.x && point.x < frame.origin.x + frame.size.width;
    let vertically = point.y >= frame.origin.y && point.y < frame.origin.y + frame.size.height;

    horizontally && vertically
}

fn placement(screen: &NSScreen) -> IslandPlacement {
    let frame = screen.frame();
    let visible = screen.visibleFrame();
    let menu_bar_height = (frame.origin.y + frame.size.height) - (visible.origin.y + visible.size.height);

    IslandPlacement {
        notch: notch(screen),
        top_inset: points(menu_bar_height),
    }
}

fn notch(screen: &NSScreen) -> Option<Notch> {
    let height = screen.safeAreaInsets().top;

    if height <= 0.0 {
        return None;
    }

    let left = screen.auxiliaryTopLeftArea();
    let right = screen.auxiliaryTopRightArea();

    Some(Notch {
        width: points(right.origin.x - (left.origin.x + left.size.width)),
        height: points(height),
    })
}

#[expect(
    clippy::cast_possible_truncation,
    clippy::cast_sign_loss,
    reason = "lengths on a screen in points are small and clamped to zero or more"
)]
fn points(length: f64) -> u32 {
    length.max(0.0).round() as u32
}
