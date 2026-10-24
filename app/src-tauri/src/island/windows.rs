use tauri::{AppHandle, Manager, PhysicalPosition, Runtime, WebviewUrl, WebviewWindow, WebviewWindowBuilder};
use windows::Win32::Foundation::HWND;
use windows::Win32::Graphics::Dwm::{DWMWA_WINDOW_CORNER_PREFERENCE, DWMWCP_DONOTROUND, DwmSetWindowAttribute};
use windows::Win32::UI::WindowsAndMessaging::{
    GWL_EXSTYLE, GetWindowLongPtrW, HWND_TOPMOST, SW_SHOWNOACTIVATE, SWP_NOACTIVATE, SWP_NOMOVE, SWP_NOSIZE,
    SWP_SHOWWINDOW, SetWindowLongPtrW, SetWindowPos, ShowWindow, WS_EX_APPWINDOW, WS_EX_NOACTIVATE, WS_EX_TOOLWINDOW,
    WS_EX_TOPMOST,
};

use super::{CANVAS_HEIGHT, CANVAS_WIDTH, IslandPlacement, LABEL, announce};

pub(super) fn create<R: Runtime>(app: &AppHandle<R>) -> tauri::Result<()> {
    let window = WebviewWindowBuilder::new(app, LABEL, WebviewUrl::App("island.html".into()))
        .title("Waft")
        .inner_size(CANVAS_WIDTH, CANVAS_HEIGHT)
        .decorations(false)
        .transparent(true)
        .shadow(false)
        .resizable(false)
        .always_on_top(true)
        .skip_taskbar(true)
        .focused(false)
        .focusable(false)
        .visible(false)
        .build()?;

    let hwnd = window.hwnd()?;

    unsafe {
        let style = GetWindowLongPtrW(hwnd, GWL_EXSTYLE);
        let island_style = (WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE | WS_EX_TOPMOST).0 as isize;
        SetWindowLongPtrW(
            hwnd,
            GWL_EXSTYLE,
            (style | island_style) & !(WS_EX_APPWINDOW.0 as isize),
        );

        let corners = DWMWCP_DONOTROUND;
        let size = size_of_val(&corners) as u32;

        if let Err(error) =
            DwmSetWindowAttribute(hwnd, DWMWA_WINDOW_CORNER_PREFERENCE, (&raw const corners).cast(), size)
        {
            tracing::warn!(%error, "couldn't turn off rounded corners on the island");
        }
    }

    window.set_ignore_cursor_events(true)?;

    Ok(())
}

pub(super) fn show<R: Runtime>(app: &AppHandle<R>) {
    let Some(window) = app.get_webview_window(LABEL) else {
        tracing::warn!("the island window is missing");
        return;
    };

    let placement = place(app, &window);

    if let Ok(hwnd) = window.hwnd() {
        present(hwnd);
    }

    place(app, &window);
    announce(app, &placement);
}

pub(super) fn hide<R: Runtime>(app: &AppHandle<R>) {
    let Some(window) = app.get_webview_window(LABEL) else {
        return;
    };

    if let Err(error) = window.hide() {
        tracing::warn!(%error, "couldn't hide the island");
    }
}

fn place<R: Runtime>(app: &AppHandle<R>, window: &WebviewWindow<R>) -> IslandPlacement {
    let placement = IslandPlacement {
        notch: None,
        top_inset: 0,
    };

    let monitor = app
        .cursor_position()
        .ok()
        .and_then(|cursor| app.monitor_from_point(cursor.x, cursor.y).ok().flatten());

    let Some(monitor) = monitor else {
        return placement;
    };

    let area = monitor.work_area();
    let width = CANVAS_WIDTH * monitor.scale_factor();
    let x = f64::from(area.position.x) + (f64::from(area.size.width) - width) / 2.0;

    if let Err(error) = window.set_position(PhysicalPosition::new(x.round() as i32, area.position.y)) {
        tracing::warn!(%error, "couldn't move the island");
    }

    placement
}

fn present(hwnd: HWND) {
    unsafe {
        let _ = ShowWindow(hwnd, SW_SHOWNOACTIVATE);

        if let Err(error) = SetWindowPos(
            hwnd,
            Some(HWND_TOPMOST),
            0,
            0,
            0,
            0,
            SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE | SWP_SHOWWINDOW,
        ) {
            tracing::warn!(%error, "couldn't raise the island");
        }
    }
}
