//
//  OEXLinkedInSocial.h
//  edX
//
//  Created by Jose Antonio Gonzalez on 2017/08/14.
//  Copyright © 2017 edX. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@interface OEXLinkedInSocial : NSObject

- (void)loginFromController:(UIViewController*)controller completion:(void(^)(NSString* accessToken,NSError* error))completionHandler;
- (void)logout;
- (BOOL)isLogin;

- (void)requestUserProfileInfoWithCompletion:(void(^)(NSDictionary* userProfile, NSError* error))completion;

@end

NS_ASSUME_NONNULL_END
