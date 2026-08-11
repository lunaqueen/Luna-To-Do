#include "flutter_window.h"

#include <optional>
#include <variant>

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>

#include "flutter/generated_plugin_registrant.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());

  auto window_channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(), "luna_todo/window",
          &flutter::StandardMethodCodec::GetInstance());
  window_channel->SetMethodCallHandler(
      [window = GetHandle()](
          const flutter::MethodCall<flutter::EncodableValue>& call,
          std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
              result) {
        if (call.method_name() != "setOpacity") {
          result->NotImplemented();
          return;
        }

        const auto* arguments =
            std::get_if<flutter::EncodableMap>(call.arguments());
        if (arguments == nullptr) {
          result->Error("invalid_arguments",
                        "setOpacity expects an argument map.");
          return;
        }

        const auto opacity_it =
            arguments->find(flutter::EncodableValue("opacity"));
        if (opacity_it == arguments->end()) {
          result->Error("invalid_arguments", "Missing opacity value.");
          return;
        }

        double opacity = 1.0;
        if (const auto* value = std::get_if<double>(&opacity_it->second)) {
          opacity = *value;
        } else if (const auto* value = std::get_if<int>(&opacity_it->second)) {
          opacity = static_cast<double>(*value);
        } else {
          result->Error("invalid_arguments", "Opacity must be numeric.");
          return;
        }

        if (opacity < 0.0) {
          opacity = 0.0;
        } else if (opacity > 1.0) {
          opacity = 1.0;
        }

        LONG_PTR extended_style = GetWindowLongPtr(window, GWL_EXSTYLE);
        if (opacity < 1.0) {
          SetWindowLongPtr(window, GWL_EXSTYLE, extended_style | WS_EX_LAYERED);
          const BYTE alpha = static_cast<BYTE>(opacity * 255.0);
          if (!SetLayeredWindowAttributes(window, 0, alpha, LWA_ALPHA)) {
            result->Error("windows_opacity_failed",
                          "Unable to apply layered window opacity.");
            return;
          }
        } else {
          SetLayeredWindowAttributes(window, 0, 255, LWA_ALPHA);
          SetWindowLongPtr(window, GWL_EXSTYLE,
                           extended_style & ~WS_EX_LAYERED);
        }

        result->Success();
      });

  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() { this->Show(); });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  window_channel_ = std::move(window_channel);

  return true;
}

void FlutterWindow::OnDestroy() {
  window_channel_ = nullptr;

  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
