//
//  PollXblockViewController.swift
//  edX
//
//  Created by José Antonio González on 2018/06/14.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit

public class PollViewController: UIViewController, CourseBlockViewController, PreloadableBlockController {
    
    public typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & DataManagerProvider & OEXSessionProvider
    
    public var blockID: CourseBlockID?
    public var courseID: CourseBlockID
    private let loader = BackedStream<CourseBlock>()
    private let xblockApiClient : XBlockApiClient
    
    public init(blockID : CourseBlockID?, courseID : String, environment : Environment) {
        self.blockID = blockID
        self.courseID = courseID
        self.xblockApiClient = XBlockApiClient(environment: environment, courseID: self.courseID)
        let username = environment.session.currentUser?.username
        self.xblockApiClient.makeSettingsRequest(PollGetSettings(blockId: self.blockID!, username: username!), completionHandler: { message in
            print(message)
        })
        
        super.init(nibName : nil, bundle : nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    public func preloadData() {
        
    }
}
