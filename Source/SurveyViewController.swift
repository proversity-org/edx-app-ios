//
//  SurveyXBlockViewController.swift
//  edX
//
//  Created by José Antonio González on 2018/06/14.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit

public class SurveyViewController: UIViewController, CourseBlockViewController, PreloadableBlockController {

    public typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & DataManagerProvider & OEXSessionProvider
    public let courseID : String
    public let blockID : CourseBlockID?
    
    private let loader = BackedStream<CourseBlock>()
    
    public init(blockID : CourseBlockID?, courseID : String, environment : Environment) {
        self.courseID = courseID
        self.blockID = blockID
        
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
