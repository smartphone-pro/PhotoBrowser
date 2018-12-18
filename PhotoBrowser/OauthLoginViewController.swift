//
//  OauthLoginViewController.swift
//  PhotoBrowser
//
//  Created by Zhouqi Mo on 12/22/14.
//  Copyright (c) 2014 Zhouqi Mo. All rights reserved.
//

import UIKit
import Foundation
import CoreData
import Alamofire
import SwiftyJSON

class OauthLoginViewController: UIViewController {
    
    @IBOutlet weak var webView: UIWebView!
    var coreDataStack: CoreDataStack!
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        webView.isHidden = true
        URLCache.shared.removeAllCachedResponses()
        if let cookies = HTTPCookieStorage.shared.cookies {
            for cookie in cookies {
                HTTPCookieStorage.shared.deleteCookie(cookie)
            }
        }
        
        let request = URLRequest(url: Instagram.Router.requestOauthCode.URLRequest.url!, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 10.0)
        self.webView.loadRequest(request)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "unwindToPhotoBrowser" && segue.destination.isKind(of: PhotoBrowserCollectionViewController.classForCoder()) {
            let photoBrowserCollectionViewController = segue.destination as! PhotoBrowserCollectionViewController
            if let user = (sender as AnyObject).value(forKey: "user") as? User {
                photoBrowserCollectionViewController.user = user
                
            }
        }
    }
    
}

extension OauthLoginViewController: UIWebViewDelegate {
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        debugPrint(request.URLString)
        
        let redirectURIComponents = URLComponents(string: Instagram.Router.redirectURI)!
        let components = URLComponents(string: request.URLString)!
        if components.host == redirectURIComponents.host {
            if let code = (components.queryItems?.filter { $0.name == "code" })?.first?.value {
                debugPrint(code)
                requestAccessToken(code)
                return false
            }
        }
        return true
    }
    
    func requestAccessToken(_ code: String) {
        let request = Instagram.Router.requestAccessTokenURLStringAndParms(code)
        
        Alamofire.request(.POST, request.URLString, parameters: request.Params)
            .responseJSON {
                (_, _, result) in
                switch result {
                case .success(let jsonObject):
                    //debugPrint(jsonObject)
                    let json = JSON(jsonObject)
                    
                    if let accessToken = json["access_token"].string, let userID = json["user"]["id"].string {
                        let user = NSEntityDescription.insertNewObject(forEntityName: "User", into: self.coreDataStack.context) as! User
                        user.userID = userID
                        user.accessToken = accessToken
                        self.coreDataStack.saveContext()
                        self.performSegue(withIdentifier: "unwindToPhotoBrowser", sender: ["user": user])
                    }
                case .failure:
                    break;
                }
        }
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        webView.isHidden = false
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        
    }
}
