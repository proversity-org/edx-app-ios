//
//  Poll.swift
//  edX
//
//  Created by José Antonio González on 2018/06/14.
//  Copyright © 2018 edX. All rights reserved.
//

import Foundation

public struct Poll: Decodable {
    let question: String
    let answers: [PollAnswers]
    
    init(question: String, answers: [PollAnswers]) {
        self.question = question
        self.answers = answers
    }
}

struct PollAnswers: Codable {
    let value: String
    let display: PollAnswer
    
    private enum CodingKeys: String, CodingKey {
        case value = "value"
        case display = "display"
    }
}

struct PollAnswer: Codable {
    let img: String
    let imgAlt: String
    let label: String
    
    private enum CodingKeys: String, CodingKey {
        case img = "img"
        case imgAlt = "imgAlt"
        case label = "label"
    }
}
