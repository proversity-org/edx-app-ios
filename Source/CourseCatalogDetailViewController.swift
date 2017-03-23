//
//  CourseCatalogDetailViewController.swift
//  edX
//
//  Created by Akiva Leffert on 12/3/15.
//  Copyright © 2015 edX. All rights reserved.
//

import WebKit
import UIKit

import edXCore

class CourseCatalogDetailViewController: UIViewController {
    private let courseID: String
    
    typealias Environment = protocol<OEXAnalyticsProvider, DataManagerProvider, NetworkManagerProvider, OEXRouterProvider, OEXSessionProvider>
    
    private let environment: Environment
    private lazy var loadController = LoadStateViewController()
    private lazy var aboutView : CourseCatalogDetailView = {
        return CourseCatalogDetailView(frame: CGRectZero, environment: self.environment)
    }()
    private let courseStream = BackedStream<(OEXCourse, enrolled: Bool)>()
    
    init(environment : Environment, courseID : String) {
        self.courseID = courseID
        self.environment = environment
        super.init(nibName: nil, bundle: nil)
        self.navigationItem.title = Strings.findCourses
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .Plain, target: nil, action: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(aboutView)
        aboutView.snp_makeConstraints { make in
            make.edges.equalTo(self.view)
        }
        self.view.backgroundColor = OEXStyles.sharedStyles().standardBackgroundColor()
        
        self.loadController.setupInController(self, contentView: aboutView)
        
        self.aboutView.setupInController(self)
        
        listen()
        load()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        environment.analytics.trackScreenWithName(OEXAnalyticsScreenCourseInfo)
    }
    
    private func listen() {
        self.courseStream.listen(self,
            success: {[weak self] (course, enrolled) in
                self?.aboutView.applyCourse(course)
                var isOldEnough = true
                let minimumAge = course.minimum_age
                let profile = self?.environment.dataManager.userProfileManager.feedForCurrentUser().map({ (profile: UserProfile) -> UserProfile in
                    return profile
                })
                
                let yearOfBirthProfile = profile!.output.value?.birthYear!
                let yearOfBirthDetails = self?.environment.session.currentUser?.year_of_birth
                
                if (yearOfBirthProfile != nil || yearOfBirthDetails != nil) {
                    if (yearOfBirthDetails != nil && yearOfBirthDetails! == 0) {
                        isOldEnough = false
                    } else if (yearOfBirthProfile != nil && yearOfBirthProfile == 0) {
                        isOldEnough = false
                    } else {
                        let date = NSDate()
                        let calendar = NSCalendar.currentCalendar()
                        let components = calendar.components([.Day , .Month , .Year], fromDate: date)
                        let year =  components.year
                        if (yearOfBirthProfile != nil && Float(year - yearOfBirthProfile!) <= minimumAge) {
                            isOldEnough = false
                        } else if (yearOfBirthDetails != nil && Float(year - yearOfBirthDetails!) <= minimumAge) {
                            isOldEnough = false
                        }
                    }
                }
                
                if enrolled {
                    self?.aboutView.actionText = Strings.CourseDetail.viewCourse
                    self?.aboutView.action = {completion in
                        self?.showCourseScreen()
                        completion()
                    }
                }
                else if !isOldEnough {
                    self?.aboutView.invitationOnlyBtn("You are not old enough to enrol")
                }
                else if course.invitation_only {
                    self?.aboutView.invitationOnlyBtn("Invitation only")
                }
                else {
                    self?.aboutView.actionText = Strings.CourseDetail.enrollNow
                    self?.aboutView.action = {[weak self] completion in
                        self?.enrollInCourse(completion)
                    }
                }
            }, failure: {[weak self] error in
                self?.loadController.state = LoadState.failed(error)
            }
        )
        self.aboutView.loaded.listen(self) {[weak self] _ in
            self?.loadController.state = .Loaded
        }
    }
    
    private func load() {
        let username = self.environment.router?.environment.session.currentUser?.username
        let request = CourseCatalogAPI.getCourse(courseID, userID: username!)
        let courseStream = environment.networkManager.streamForRequest(request)
        let enrolledStream = environment.dataManager.enrollmentManager.streamForCourseWithID(courseID).resultMap {
            return .Success($0.isSuccess)
        }
        let stream = joinStreams(courseStream, enrolledStream).map{($0, enrolled: $1) }
        self.courseStream.backWithStream(stream)
    }
    
    private func showCourseScreen(message message: String? = nil) {
        self.environment.router?.showMyCourses(animated: true, pushingCourseWithID:courseID)
        
        if let message = message {
            let after = dispatch_time(DISPATCH_TIME_NOW, Int64(EnrollmentShared.overlayMessageDelay * NSTimeInterval(NSEC_PER_SEC)))
            dispatch_after(after, dispatch_get_main_queue()) {
                NSNotificationCenter.defaultCenter().postNotificationName(EnrollmentShared.successNotification, object: message, userInfo: nil)
            }
        }
    }
    
    private func enrollInCourse(completion : () -> Void) {
        
        let notEnrolled = environment.dataManager.enrollmentManager.enrolledCourseWithID(self.courseID) == nil
        
        guard notEnrolled else {
            self.showCourseScreen(message: Strings.findCoursesAlreadyEnrolledMessage)
            completion()
            return
        }
        
        let courseID = self.courseID
        let request = CourseCatalogAPI.enroll(courseID)
        environment.networkManager.taskForRequest(request) {[weak self] response in
            if response.response?.httpStatusCode.is2xx ?? false {
                self?.environment.analytics.trackUserEnrolledInCourse(courseID)
                self?.showCourseScreen(message: Strings.findCoursesEnrollmentSuccessfulMessage)
            }
            else {
                self?.showOverlayMessage(Strings.findCoursesEnrollmentErrorDescription)
            }
            completion()
        }
    }
    
}
// Testing only
extension CourseCatalogDetailViewController {
    
    var t_loaded : Stream<()> {
        return self.aboutView.loaded
    }
    
    var t_actionText: String? {
        return self.aboutView.actionText
    }
    
    func t_enrollInCourse(completion : () -> Void) {
        enrollInCourse(completion)
    }
    
}
