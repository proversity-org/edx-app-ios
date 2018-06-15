//
//  PollGetSettings.swift
//  edX
//
//  Created by José Antonio González on 2018/06/14.
//  Copyright © 2018 edX. All rights reserved.
//

import Foundation

public struct PollGetSettings: XBlockApiRequestData {
    
    public typealias Response = [Poll]
    
    public var resourceName: String {
        return "api/courses/v1/blocks"
    }
    
    public let blockId: CourseBlockID
    public let username: String
    public let studentViewData: String
    
    public init(blockId: CourseBlockID,
                username: String) {
        self.blockId = blockId
        self.username = username
        self.studentViewData = "poll"
    }
}
