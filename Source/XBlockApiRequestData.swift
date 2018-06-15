//
//  XBlockApiRequest.swift
//  edX
//
//  Created by José Antonio González on 2018/06/14.
//  Copyright © 2018 edX. All rights reserved.
//

import Foundation

public protocol XBlockApiRequestData: Encodable {
    associatedtype Response: Decodable
    var resourceName: String { get }
    var blockId: CourseBlockID { get }
    var username: String { get }
    var studentViewData: String { get }
}
