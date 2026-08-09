import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.isOpaque = false
    self.backgroundColor = .clear
    self.contentViewController = flutterViewController
    flutterViewController.view.wantsLayer = true
    flutterViewController.view.layer?.isOpaque = false
    flutterViewController.view.layer?.backgroundColor = NSColor.clear.cgColor
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    let windowChannel = FlutterMethodChannel(
      name: "luna_todo/window",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    windowChannel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "enableTransparency" else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.isOpaque = false
      self?.backgroundColor = .clear
      self?.hasShadow = false
      flutterViewController.view.wantsLayer = true
      flutterViewController.view.layer?.isOpaque = false
      flutterViewController.view.layer?.backgroundColor = NSColor.clear.cgColor
      result(nil)
    }

    super.awakeFromNib()
  }
}
