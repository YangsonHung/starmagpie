import AppKit
import SwiftUI
import WebKit

struct ReadmeWebView: NSViewRepresentable {
    let html: String
    let baseURL: URL

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = false
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = false
        webView.setValue(false, forKey: "drawsBackground")
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        let document = htmlDocument(readmeHTML: html)
        guard context.coordinator.lastDocument != document ||
              context.coordinator.lastBaseURL != baseURL else {
            return
        }

        context.coordinator.lastDocument = document
        context.coordinator.lastBaseURL = baseURL
        webView.loadHTMLString(document, baseURL: baseURL)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var lastDocument: String?
        var lastBaseURL: URL?

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard let url = navigationAction.request.url,
                  navigationAction.navigationType == .linkActivated || navigationAction.targetFrame == nil else {
                decisionHandler(.allow)
                return
            }

            NSWorkspace.shared.open(ReadmeURLMapper.externalURL(for: url))
            decisionHandler(.cancel)
        }
    }

    private func htmlDocument(readmeHTML: String) -> String {
        """
        <!doctype html>
        <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <style>
            * {
              box-sizing: border-box;
            }
            :root {
              color-scheme: light dark;
              font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif;
              font-size: 14px;
              line-height: 1.55;
            }
            html {
              width: 100%;
              overflow-x: hidden;
            }
            body {
              margin: 0;
              padding: 16px;
              width: 100%;
              max-width: 100%;
              overflow-x: hidden;
              background: transparent;
              color: #1f2328;
              word-wrap: break-word;
            }
            article {
              width: 100%;
              max-width: 100%;
              overflow-wrap: anywhere;
            }
            a {
              color: #0969da;
              text-decoration: none;
              overflow-wrap: anywhere;
            }
            a:hover {
              text-decoration: underline;
            }
            h1, h2, h3, h4, h5, h6 {
              margin: 20px 0 8px;
              line-height: 1.25;
            }
            h1 {
              font-size: 24px;
              padding-bottom: 8px;
              border-bottom: 1px solid #d0d7de;
            }
            h2 {
              font-size: 20px;
              padding-bottom: 6px;
              border-bottom: 1px solid #d8dee4;
            }
            h3 {
              font-size: 17px;
            }
            p, ul, ol, pre, table, blockquote {
              margin-top: 0;
              margin-bottom: 12px;
            }
            img,
            svg,
            video,
            canvas,
            iframe {
              display: block;
              max-width: 100%;
              height: auto;
            }
            picture {
              display: block;
              max-width: 100%;
            }
            code {
              font-family: "SF Mono", Menlo, monospace;
              font-size: 0.92em;
              padding: 0.15em 0.35em;
              border-radius: 5px;
              background: rgba(175, 184, 193, 0.2);
            }
            pre {
              max-width: 100%;
              overflow-x: auto;
              padding: 12px;
              border-radius: 8px;
              background: #f6f8fa;
            }
            pre code {
              padding: 0;
              background: transparent;
            }
            blockquote {
              color: #57606a;
              padding-left: 12px;
              border-left: 3px solid #d0d7de;
            }
            table {
              border-spacing: 0;
              border-collapse: collapse;
              display: block;
              max-width: 100%;
              overflow-x: auto;
            }
            th, td {
              padding: 6px 10px;
              border: 1px solid #d0d7de;
            }
            @media (prefers-color-scheme: dark) {
              body {
                color: #e6edf3;
              }
              a {
                color: #58a6ff;
              }
              h1, h2, th, td {
                border-color: #30363d;
              }
              code {
                background: rgba(110, 118, 129, 0.35);
              }
              pre {
                background: #161b22;
              }
              blockquote {
                color: #8b949e;
                border-left-color: #30363d;
              }
            }
          </style>
        </head>
        <body>
          <article>
            \(readmeHTML)
          </article>
        </body>
        </html>
        """
    }
}

enum ReadmeURLMapper {
    static func externalURL(for url: URL) -> URL {
        githubURL(forRawContentURL: url) ?? url
    }

    private static func githubURL(forRawContentURL url: URL) -> URL? {
        guard url.host == "raw.githubusercontent.com" else { return nil }

        let pathComponents = url.pathComponents.filter { $0 != "/" }
        guard pathComponents.count >= 3 else { return nil }

        let owner = pathComponents[0]
        let repo = pathComponents[1]
        let ref = pathComponents[2]
        let filePath = pathComponents.dropFirst(3).joined(separator: "/")

        var components = URLComponents()
        components.scheme = "https"
        components.host = "github.com"
        components.path = filePath.isEmpty
            ? "/\(owner)/\(repo)/tree/\(ref)"
            : "/\(owner)/\(repo)/blob/\(ref)/\(filePath)"
        components.fragment = URLComponents(url: url, resolvingAgainstBaseURL: false)?.fragment
        return components.url
    }
}
