//
//  PhotoBrowserCollectionViewController.swift
//  PhotoBrowser
//
//  Created by Zhouqi Mo on 12/22/14.
//  Copyright (c) 2014 Zhouqi Mo. All rights reserved.
//

import UIKit
import Foundation
import CoreData
import Alamofire
import FastImageCache
import SwiftyJSON

class PhotoBrowserCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var logoutButtonItem: UIBarButtonItem!
    
    let formatName = KMSmallImageFormatName
    var shouldLogin = false
    var user: User? {
        didSet {
            if user != nil {
                handleRefresh()
                hideLogoutButtonItem(false)
                
            } else {
                shouldLogin = true
                hideLogoutButtonItem(true)
            }
        }
    }
    
    var photos = [PhotoInfo]()
    let refreshControl = UIRefreshControl()
    var populatingPhotos = false
    var nextURLRequest: URLRequest?
    var coreDataStack: CoreDataStack!
    
    let PhotoBrowserCellIdentifier = "PhotoBrowserCell"
    let PhotoBrowserFooterViewIdentifier = "PhotoBrowserFooterView"
    
    // MARK: Life-cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        
        if let fetchRequest = coreDataStack.model.fetchRequestTemplate(forName: "UserFetchRequest") {
            
            let results = try! coreDataStack.context.fetch(fetchRequest) as! [User]
            user = results.first
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if shouldLogin {
            performSegue(withIdentifier: "login", sender: self)
            shouldLogin = false
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func unwindToPhotoBrowser (_ segue : UIStoryboardSegue) {
        
    }
    
    // MARK: CollectionView
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoBrowserCellIdentifier, for: indexPath) as! PhotoBrowserCollectionViewCell
        let sharedImageCache = FICImageCache.shared()
        cell.imageView.image = nil
        
        let photo = photos[indexPath.row] as PhotoInfo
        if (cell.photoInfo != photo) {
            
            sharedImageCache?.cancelImageRetrieval(for: cell.photoInfo, withFormatName: formatName)
            
            cell.photoInfo = photo
        }
        
        sharedImageCache?.retrieveImage(for: photo, withFormatName: formatName, completionBlock: {
            (photoInfo, _, image) -> Void in
            if (photoInfo as! PhotoInfo) == cell.photoInfo {
                cell.imageView.image = image
            }
        })
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: PhotoBrowserFooterViewIdentifier, for: indexPath) as! PhotoBrowserLoadingCollectionView
        if nextURLRequest == nil {
            footerView.spinner.stopAnimating()
        } else {
            footerView.spinner.startAnimating()
        }
        return footerView
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let photoInfo = photos[indexPath.row]
        performSegue(withIdentifier: "show photo", sender: ["photoInfo": photoInfo])
    }
    
    func setupCollectionViewLayout() {
        let layout = UICollectionViewFlowLayout()
        let column = UI_USER_INTERFACE_IDIOM() == .pad ? 4 : 3
        let itemWidth = floor((view.bounds.size.width - CGFloat(column - 1)) / CGFloat(column))
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
        layout.minimumInteritemSpacing = 1.0
        layout.minimumLineSpacing = 1.0
        layout.footerReferenceSize = CGSize(width: collectionView!.bounds.size.width, height: 100.0)
        collectionView!.collectionViewLayout = layout
    }
    
    func setupView() {
        setupCollectionViewLayout()
        collectionView!.register(PhotoBrowserCollectionViewCell.classForCoder(), forCellWithReuseIdentifier: PhotoBrowserCellIdentifier)
        collectionView!.register(PhotoBrowserLoadingCollectionView.classForCoder(), forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: PhotoBrowserFooterViewIdentifier)
        
        refreshControl.tintColor = UIColor.white
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView!.addSubview(refreshControl)
    }
    
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if (self.nextURLRequest != nil && scrollView.contentOffset.y + view.frame.size.height > scrollView.contentSize.height * 0.8) {
            populatePhotos(self.nextURLRequest!)
        }
    }
    
    func populatePhotos(_ request: URLRequestConvertible) {
        
        if populatingPhotos {
            return
        }
        
        populatingPhotos = true
        
        Alamofire.request(request).responseJSON() {
            (_ , _, result) in
            defer {
                self.populatingPhotos = false
            }
            switch result {
            case .success(let jsonObject):
                //debugPrint(jsonObject)
                let json = JSON(jsonObject)
                
                if (json["meta"]["code"].intValue  == 200) {
                    DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.high).async {
                        if let urlString = json["pagination"]["next_url"].URL {
                            self.nextURLRequest = URLRequest(url: urlString)
                        } else {
                            self.nextURLRequest = nil
                        }
                        let photoInfos = json["data"].arrayValue
                            
                            .filter {
                                $0["type"].stringValue == "image"
                            }.map({
                                PhotoInfo(sourceImageURL: $0["images"]["standard_resolution"]["url"].URL!)
                            })
                        
                        let lastItem = self.photos.count
                        self.photos.append(contentsOf: photoInfos)
                        
                        let indexPaths = (lastItem..<self.photos.count).map { IndexPath(item: $0, section: 0) }
                        
                        DispatchQueue.main.async {
                            self.collectionView!.insertItems(at: indexPaths)
                        }
                        
                    }
                    
                }
            case .failure:
                break;
            }
            
        }
    }
    
    func handleRefresh() {
        nextURLRequest = nil
        refreshControl.beginRefreshing()
        self.photos.removeAll(keepingCapacity: false)
        self.collectionView!.reloadData()
        refreshControl.endRefreshing()
        if user != nil {
            let request = Instagram.Router.popularPhotos(user!.userID, user!.accessToken)
            populatePhotos(request)
        }
    }
    
    func hideLogoutButtonItem(_ hide: Bool) {
        if hide {
            logoutButtonItem.title = ""
            logoutButtonItem.isEnabled = false
        } else {
            logoutButtonItem.title = "Logout"
            logoutButtonItem.isEnabled = true
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "show photo" && segue.destination.isKind(of: PhotoViewerViewController.classForCoder()) {
            let photoViewerViewController = segue.destination as! PhotoViewerViewController
            photoViewerViewController.photoInfo = (sender as AnyObject).value(forKey: "photoInfo") as? PhotoInfo
        } else if segue.identifier == "login" && segue.destination.isKind(of: UINavigationController.classForCoder()) {
            let navigationController = segue.destination as! UINavigationController
            if let oauthLoginViewController = navigationController.topViewController as? OauthLoginViewController {
                oauthLoginViewController.coreDataStack = coreDataStack
            }
            
            if self.user != nil {
                coreDataStack.context.delete(user!)
                coreDataStack.saveContext()
                
            }
        }
    }
}
class PhotoBrowserCollectionViewCell: UICollectionViewCell {
    let imageView = UIImageView()
    var photoInfo: PhotoInfo?
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor(white: 0.1, alpha: 1.0)
        
        imageView.frame = bounds
        addSubview(imageView)
    }
}

class PhotoBrowserLoadingCollectionView: UICollectionReusableView {
    let spinner = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge)
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        spinner.startAnimating()
        spinner.center = self.center
        addSubview(spinner)
    }
}
