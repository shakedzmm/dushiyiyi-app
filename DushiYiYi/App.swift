import SwiftUI
import WebKit

/* 自定义 scheme 处理器：把打包进 App 的 www 目录以 app://www/ 的正规源提供。
   相对路径（assets/...）直接可用；localStorage/IndexedDB 在该源下持久保存。 */
final class GameSchemeHandler: NSObject, WKURLSchemeHandler {
    private let base = Bundle.main.resourceURL!.appendingPathComponent("www", isDirectory: true)

    func webView(_ webView: WKWebView, start task: WKURLSchemeTask) {
        guard let url = task.request.url else {
            task.didFailWithError(URLError(.badURL)); return
        }
        var rel = url.path
        if rel.hasPrefix("/") { rel.removeFirst() }
        if rel.isEmpty { rel = "game.html" }
        let file = base.appendingPathComponent(rel).standardizedFileURL
        guard file.path.hasPrefix(base.standardizedFileURL.path),
              FileManager.default.fileExists(atPath: file.path) else {
            task.didFailWithError(URLError(.fileDoesNotExist)); return
        }
        let data = (try? Data(contentsOf: file)) ?? Data()
        let mime: String
        switch file.pathExtension.lowercased() {
        case "html", "htm": mime = "text/html"
        case "js":          mime = "text/javascript"
        case "css":         mime = "text/css"
        case "png":         mime = "image/png"
        case "jpg", "jpeg": mime = "image/jpeg"
        case "webp":        mime = "image/webp"
        case "svg":         mime = "image/svg+xml"
        case "json":        mime = "application/json"
        case "ico":         mime = "image/x-icon"
        default:            mime = "application/octet-stream"
        }
        let resp = URLResponse(url: url, mimeType: mime, expectedContentLength: data.count, textEncodingName: "utf-8")
        task.didReceive(resp)
        task.didReceive(data)
        task.didFinish()
    }

    func webView(_ webView: WKWebView, stop task: WKURLSchemeTask) {}
}

struct GameView: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        let cfg = WKWebViewConfiguration()
        cfg.setURLSchemeHandler(GameSchemeHandler(), forURLScheme: "app")
        let wv = WKWebView(frame: .zero, configuration: cfg)
        wv.isOpaque = false
        wv.backgroundColor = UIColor(red: 0.95, green: 0.94, blue: 0.91, alpha: 1)
        if let url = URL(string: "app://www/game.html") {
            wv.load(URLRequest(url: url))
        }
        return wv
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

@main
struct DushiYiYiApp: App {
    var body: some Scene {
        WindowGroup {
            GameView()
                .ignoresSafeArea()
                .persistentSystemOverlays(.hidden)
        }
    }
}
