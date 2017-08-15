//
//  OEXLinkedInSocial.m
//  edX
//
//  Created by Jose Antonio Gonzalez on 2017/08/14.
//  Copyright © 2017 edX. All rights reserved.
//

#import "OEXLinkedInSocial.h"

#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import <linkedin-sdk/LISDK.h>

#import "edX-Swift.h"
#import "Logger+OEXObjC.h"

#import "NSNotificationCenter+OEXSafeAccess.h"
#import "OEXConfig.h"
#import "OEXLinkedInConfig.h"
#import "OEXSession.h"

@implementation OEXLinkedInSocial

- (id)init {
    self = [super init];
    if(self != nil) {
        [[NSNotificationCenter defaultCenter] oex_addObserver:self notification:OEXSessionEndedNotification action:^(NSNotification *notification, OEXLinkedInSocial* observer, id<OEXRemovable> removable) {
            [observer logout];
        }];
    }
    return self;
}

- (void)loginFromController:(UIViewController *)controller completion:(void (^)(NSString *, NSError *))completionHandler {
    [LISDKSessionManager
     createSessionWithAuth:[NSArray arrayWithObjects:LISDK_BASIC_PROFILE_PERMISSION, LISDK_EMAILADDRESS_PERMISSION, nil]
     state:nil
     showGoToAppStoreDialog:YES
     successBlock:^(NSString *returnState) {
         LISDKSession *session = [[LISDKSessionManager sharedInstance] session];
         completionHandler(session.value, nil);
     }
     errorBlock:^(NSError *error) {
         completionHandler(nil, error);
     }
    ];
}

- (BOOL)isLogin {
    OEXConfig* config = [OEXConfig sharedConfig];
    OEXLinkedInConfig* linkedInConfig = [config linkedInConfig];
    if(linkedInConfig.enabled) {
        return [[LISDKSessionManager sharedInstance] session] != nil;
    }
    return NO;
}

- (void)logout {
    if([self isLogin]) {
        [LISDKSessionManager clearSession];
    }
}

- (void)requestUserProfileInfoWithCompletion:(void (^)(NSDictionary*, NSError *))completion {
    if ([LISDKSessionManager hasValidSession]) {
        NSString *url = @"https://api.linkedin.com/v1/people/~:(id,first-name,last-name,headline,location,industry,summary,specialties,email-address)";
        [[LISDKAPIHelper sharedInstance] getRequest:url
                                            success:^(LISDKAPIResponse *response) {
                                                // do something with response
                                                NSData *data = [response.data dataUsingEncoding:NSUTF8StringEncoding];
                                                id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                                                completion(json, nil);
                                            }
                                              error:^(LISDKAPIError *apiError) {
                                                  completion(nil, apiError);
                                              }];
    }
}

@end
