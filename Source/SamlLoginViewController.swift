//
//  SamlLoginViewController.swift
//  edX
//
//  Created by andrey.cano on 10/11/18.
//  Copyright © 2018 edX. All rights reserved.
//

import WebKit

@objc class SamlLoginViewController: UIViewController, UIWebViewDelegate {
    
    var webView: UIWebView!
    
    typealias Environment = OEXConfigProvider & OEXStylesProvider
    fileprivate let environment: Environment
    
    init(environment: Environment) {
        self.environment = environment
        super.init(nibName: nil, bundle :nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        webView = UIWebView(frame: UIScreen.main.bounds)
        webView.delegate = self
        view.addSubview(webView)
        let path = NSString.oex_string(withFormat: SAML_PROVIDER_LOGIN_URL, parameters: ["idpSlug": environment.config.samlProviderConfig.samlIdpSlug])
        if let url = URL(string: (environment.config.apiHostURL()?.absoluteString)!+path) {
            let request = URLRequest(url: url)
            webView.loadRequest(request)
        }
        let closeButton = UIBarButtonItem(image: UIImage(named: "ic_cancel"), style: .plain, target: self, action: #selector(navigateBack))
        navigationItem.leftBarButtonItem = closeButton
    }
    
    func navigateBack() {
        dismiss(animated: true, completion: nil)
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        navigationItem.title = webView.stringByEvaluatingJavaScript(from: "document.title")
        let url = webView.request?.URLString
        if (url?.contains(find: (environment.config.apiHostURL()?.absoluteString)!))! {
            if let cookies = HTTPCookieStorage.shared.cookies {
                for cookie in cookies {
                    NSLog("\(cookie)")
                }
            }
        }        
    }
}
