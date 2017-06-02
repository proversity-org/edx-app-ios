//
//  AuthenticatedWebViewController.swift
//  edX
//
//  Created by Akiva Leffert on 5/26/15.
//  Copyright (c) 2015 edX. All rights reserved.
//
import UIKit
import WebKit

class HeaderViewInsets : ContentInsetsSource {
    weak var insetsDelegate : ContentInsetsSourceDelegate?
    
    var view : UIView?
    
    var currentInsets : UIEdgeInsets {
        return UIEdgeInsets(top : view?.frame.size.height ?? 0, left : 0, bottom : 0, right : 0)
    }
    
    var affectsScrollIndicators : Bool {
        return true
    }
}

private protocol WebContentController {
    var view : UIView {get}
    var scrollView : UIScrollView {get}
    
    var alwaysRequiresOAuthUpdate : Bool { get}
    
    var initialContentState : AuthenticatedWebViewController.State { get }
    
    func loadURLRequest(request : NSURLRequest)
    
    func clearDelegate()
    func resetState()
}

// A class should implement AlwaysRequireAuthenticationOverriding protocol if it always require authentication.
protocol AuthenticatedWebViewControllerRequireAuthentication {
}

protocol AuthenticatedWebViewControllerDelegate {
    func authenticatedWebViewController(authenticatedController: AuthenticatedWebViewController, didFinishLoading webview: WKWebView)
}

private class WKWebViewContentController : WebContentController {
    fileprivate let webView : WKWebView
    
    init(configuration: WKWebViewConfiguration) {
        self.webView = WKWebView(frame: CGRect.zero, configuration: configuration)
    }
    
    var view : UIView {
        return webView
    }
    
    var scrollView : UIScrollView {
        return webView.scrollView
    }
    
    func clearDelegate() {
        return webView.navigationDelegate = nil
    }
    
    func loadURLRequest(request: NSURLRequest) {
        webView.load(request as URLRequest)
    }
    
    func resetState() {
        webView.stopLoading()
        webView.loadHTMLString("", baseURL: nil)
    }
    
    var alwaysRequiresOAuthUpdate : Bool {
        return false
    }
    
    var initialContentState : AuthenticatedWebViewController.State {
        return AuthenticatedWebViewController.State.LoadingContent
    }
}

private let OAuthExchangePath = "/oauth2/login/"

// Allows access to course content that requires authentication.
// Forwarding our oauth token to the server so we can get a web based cookie
public class AuthenticatedWebViewController: UIViewController, WKNavigationDelegate, WKScriptMessageHandler, WKUIDelegate, UIDocumentInteractionControllerDelegate {
    
    fileprivate enum State {
        case CreatingSession
        case LoadingContent
        case NeedingSession
    }

    public typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & OEXSessionProvider
    var delegate: AuthenticatedWebViewControllerDelegate?
    internal let environment : Environment
    private let blockID: CourseBlockID
    private let loadController : LoadStateViewController
    private let insetsController : ContentInsetsController
    private let headerInsets : HeaderViewInsets
    
    private lazy var webController : WebContentController = {
        let js : String = "$(document).ready(function() {" +
            "$('#recap_cmd_" + self.blockID + "').click(function() {" +
            "window.webkit.messageHandlers.clickPDFDownload.postMessage('clickPDF')" +
            "});" +
        "});"
        
        let userScript: WKUserScript =  WKUserScript(source: js,
                                                     injectionTime: WKUserScriptInjectionTime.atDocumentEnd,
                                                     forMainFrameOnly: false)
        
        let contentController = WKUserContentController();
        contentController.addUserScript(userScript)
        contentController.add(self, name: "clickPDFDownload")
        contentController.add(self, name: "downloadPDF")
        let config = WKWebViewConfiguration();
        config.userContentController = contentController;
        let controller = WKWebViewContentController(configuration: config)
        controller.webView.navigationDelegate = self
        controller.webView.uiDelegate = self
        return controller
        
    }()
    
    private var state = State.CreatingSession
    
    private var contentRequest : NSURLRequest? = nil
    var currentUrl: NSURL? {
        return contentRequest?.url as NSURL?
    }
    
    public func setLoadControllerState(withState state: LoadState) {
        loadController.state = state
    }
    
    public init(environment : Environment, blockID: String) {
        self.environment = environment
        self.blockID = blockID
        loadController = LoadStateViewController()
        insetsController = ContentInsetsController()
        headerInsets = HeaderViewInsets()
        insetsController.addSource(source: headerInsets)
        
        super.init(nibName: nil, bundle: nil)
        
        automaticallyAdjustsScrollViewInsets = false
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        // Prevent crash due to stale back pointer, since WKWebView's UIScrollView apparently doesn't
        // use weak for its delegate
        webController.scrollView.delegate = nil
        webController.clearDelegate()
    }
    
    override public func viewDidLoad() {
        
        self.state = webController.initialContentState
        self.view.addSubview(webController.view)
        webController.view.snp_makeConstraints {make in
            make.edges.equalTo(self.view)
        }
        self.loadController.setupInController(controller: self, contentView: webController.view)
        webController.view.backgroundColor = OEXStyles.shared().standardBackgroundColor()
        webController.scrollView.backgroundColor = OEXStyles.shared().standardBackgroundColor()
        
        self.insetsController.setupInController(owner: self, scrollView: webController.scrollView)
        
        
        if let request = self.contentRequest {
            loadRequest(request: request)
        }
    }
    
    private func resetState() {
        loadController.state = .Initial
        state = .CreatingSession
    }
    
    public override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        if view.window == nil {
            webController.resetState()
        }
        resetState()
    }
    
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        insetsController.updateInsets()
    }
    
    public func showError(error : NSError?, icon : Icon? = nil, message : String? = nil) {
        loadController.state = LoadState.failed(error: error, icon : icon, message : message)
        refreshAccessibility()
    }
    
    // MARK: Header View
    
    var headerView : UIView? {
        get {
            return headerInsets.view
        }
        set {
            headerInsets.view?.removeFromSuperview()
            headerInsets.view = newValue
            if let headerView = newValue {
                webController.view.addSubview(headerView)
                headerView.snp_makeConstraints {make in
                    make.top.equalTo(self.snp_topLayoutGuideBottom)
                    make.leading.equalTo(webController.view)
                    make.trailing.equalTo(webController.view)
                }
                webController.view.setNeedsLayout()
                webController.view.layoutIfNeeded()
            }
        }
    }
    
    private func loadOAuthRefreshRequest() {
        if let hostURL = environment.config.apiHostURL() {
            let URL = hostURL.appendingPathComponent(OAuthExchangePath)
            let exchangeRequest = NSMutableURLRequest(url: URL)
            exchangeRequest.httpMethod = HTTPMethod.POST.rawValue
            
            for (key, value) in self.environment.session.authorizationHeaders {
                exchangeRequest.addValue(value, forHTTPHeaderField: key)
            }
            self.webController.loadURLRequest(request: exchangeRequest)
        }
    }
    
    private func refreshAccessibility() {
        DispatchQueue.main.async {
            UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil)
        }
    }
    
    // MARK: Request Loading
    
    public func loadRequest(request : NSURLRequest) {
        contentRequest = request
        loadController.state = .Initial
        state = webController.initialContentState
        
        let isAuthRequestRequire = ((parent as? AuthenticatedWebViewControllerRequireAuthentication) != nil) ? true: webController.alwaysRequiresOAuthUpdate

        if isAuthRequestRequire {
            self.state = State.CreatingSession
            loadOAuthRefreshRequest()
        }
        else {
            webController.loadURLRequest(request: request)
        }
    }
    
    // MARK: WKWebView delegate
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        switch navigationAction.navigationType {
        case .linkActivated, .formSubmitted, .formResubmitted:
            if let URL = navigationAction.request.url {
                UIApplication.shared.openURL(URL)
            }
            decisionHandler(.cancel)
        default:
            decisionHandler(.allow)
        }
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        
        if let httpResponse = navigationResponse.response as? HTTPURLResponse, let statusCode = OEXHTTPStatusCode(rawValue: httpResponse.statusCode), let errorGroup = statusCode.errorGroup, state == .LoadingContent {
            switch errorGroup {
            case HttpErrorGroup.http4xx:
                self.state = .NeedingSession
            case HttpErrorGroup.http5xx:
                self.loadController.state = LoadState.failed()
                decisionHandler(.cancel)
            }
        }
        decisionHandler(.allow)
        
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        switch state {
        case .CreatingSession:
            if let request = contentRequest {
                state = .LoadingContent
                webController.loadURLRequest(request: request)
                
            }
            else {
                loadController.state = LoadState.failed()
            }
        case .LoadingContent:
            //The class which will implement this protocol method will be responsible to set the loadController state as Loaded
            if delegate?.authenticatedWebViewController(authenticatedController: self, didFinishLoading: webView) == nil {
              loadController.state = .Loaded
            }
        case .NeedingSession:
            state = .CreatingSession
            loadOAuthRefreshRequest()
        }
        
        refreshAccessibility()
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        showError(error: error as NSError?)
    }
    
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        showError(error: error as NSError?)
    }
    
    public func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // Don't use basic auth on exchange endpoint. That is explicitly non protected
        // and it screws up the authorization headers
        if let URL = webView.url, ((URL.absoluteString.hasSuffix(OAuthExchangePath)) != false) {
            completionHandler(.performDefaultHandling, nil)
        }
        else if let credential = environment.config.URLCredentialForHost(challenge.protectionSpace.host as NSString)  {
            completionHandler(.useCredential, credential)
        }
        else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if(message.name == "clickPDFDownload") {
            generatePdf()
        } else if (message.name == "downloadPDF") {
            showPdf(pdf: message.body as AnyObject);
        }
    }
    
    public func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }
    
    public func generatePdf() {
        let pdfJS : String = "var doc = new jsPDF('p', 'pt', 'letter');" +
            "doc.fromHTML($('#recap_answers_" + blockID + "').get(0), 30, 20, {" +
            "'width': 550," +
            "'elementHandlers': {" +
            "'#recap_editor_" + blockID + "': function(element, renderer){" +
            "return true;" +
            "}" +
            "}" +
            "}, function(){" +
            "window.webkit.messageHandlers.downloadPDF.postMessage(doc.output('datauristring'))" +
        "}, { top: 10, bottom: 10 });"
        let webView = webController.view as! WKWebView
        webView.evaluateJavaScript(pdfJS, completionHandler: { (result, error) -> Void in
            print(result ?? "")
            print(error ?? "")
        })
    }
    
    public func showPdf(pdf: AnyObject) {
        let url = NSURL(string: pdf as! String)
        let request = NSURLRequest(url: url! as URL)
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        let task = session.downloadTask(with: request as URLRequest, completionHandler: { (location, response, error) in
            let fileManager = FileManager.default
            let documents = try! fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let fileURL = documents.appendingPathComponent("PDF.pdf")
            let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
            let url = NSURL(fileURLWithPath: path)
            let filePath = url.appendingPathComponent("PDF.pdf")!.path
            if fileManager.fileExists(atPath: filePath) {
                do {
                    try fileManager.removeItem(atPath: filePath)
                } catch {
                    print(error)
                }
            }
            
            do {
                let backgroundQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.default)
                try fileManager.moveItem(at: location!, to: fileURL)
                backgroundQueue.async(execute: { 
                    let documentController = UIDocumentInteractionController.init(url: fileURL)
                    documentController.delegate = self
                    DispatchQueue.main.async(execute: { () -> Void in
                        documentController.presentPreview(animated: true)
                    })
                })
            } catch {
                print(error)
            }
        })
        task.resume()
    }
    
    //    public func webView(webView: WKWebView!, createWebViewWithConfiguration configuration: WKWebViewConfiguration!, forNavigationAction navigationAction: WKNavigationAction!, windowFeatures: WKWindowFeatures!) -> WKWebView! {
    //        if navigationAction.targetFrame == nil {
    //            webView.loadRequest(navigationAction.request)
    //        }
    //        return nil
    //    }
}
