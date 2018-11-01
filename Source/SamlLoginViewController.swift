//
//  SamlLoginViewController.swift
//  edX
//
//  Created by andrey.canon on 10/11/18.
//  Copyright © 2018 edX. All rights reserved.
//

import WebKit

@objc class SamlLoginViewController: UIViewController, UIWebViewDelegate {

    var webView: UIWebView!
    var sessionCookie: HTTPCookie!
    private let loadingIndicatorView = SpinnerView(size: .Large, color: .Primary)

    typealias Environment = OEXConfigProvider & OEXStylesProvider & OEXRouterProvider
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

    func webViewDidStartLoad(_ webView: UIWebView) {
        loadingIndicatorView.startAnimating()
        view.addSubview(loadingIndicatorView)
        loadingIndicatorView.snp.makeConstraints { make in
            make.center.equalTo(view)
        }
        webView.isHidden = true
    }

    func webViewDidFinishLoad(_ webView: UIWebView) {
        navigationItem.title = webView.stringByEvaluatingJavaScript(from: "document.title")
        loadingIndicatorView.removeFromSuperview()
        guard let url = webView.request?.URLString else {
            return
        }
        if url.contains(find: (environment.config.apiHostURL()?.absoluteString)!) {
            guard  let cookies = HTTPCookieStorage.shared.cookies else {
                return
            }
            for cookie in cookies {
                if cookie.name.elementsEqual("sessionid"){
                    self.sessionCookie = cookie
                    getUserDetails(sessionCookie: cookie)

                }
            }
        } else {
            webView.isHidden = false
        }

    }

    func handleSuccessfulLoginWithSaml(userDetails: OEXUserDetails) {

        guard let session = OEXSession.shared() else {
            return
        }
        session.saveCookies(sessionCookie, userDetails: userDetails)
        self.dismiss(animated: false, completion: nil)

    }

    //// This methods is used to get user details when user session cookie is available
    func getUserDetails(sessionCookie: HTTPCookie) {
        let config = URLSessionConfiguration.default
        let session = URLSession.init(configuration: config, delegate: nil, delegateQueue: nil)
        let cookie = String(format: "%@=%@", sessionCookie.name, sessionCookie.value)
        let request = NSMutableURLRequest.init(url: URL(string: String(format: "%@%@", (environment.config.apiHostURL()?.absoluteString)!, URL_GET_USER_INFO))!)
        request.addValue(cookie, forHTTPHeaderField: "Cookie")
        let task = session.dataTask(with: request as URLRequest, completionHandler: self.completionGetUserDetails)
        task.resume()
    }

    func completionGetUserDetails(data:Data?, response: URLResponse?, error: Error?) {
        guard error == nil && data != nil else {
            return
        }
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 200 {
                let dictionary = try? JSONSerialization.jsonObject(with: data!)
                let userDetails = OEXUserDetails(userDictionary: dictionary as! [AnyHashable : Any])
                handleSuccessfulLoginWithSaml(userDetails: userDetails)
            } else if httpResponse.statusCode == 401 {
                DispatchQueue.main.async {
                    guard let session = OEXSession.shared() else {
                        return
                    }
                    session.closeAndClear()
                    self.webView.isHidden = false
                }
            }
        }
    }

}
