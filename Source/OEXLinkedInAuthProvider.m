//
//  OEXLinkedInAithProvider.m
//  edX
//
//  Created by Jose Antonio Gonzalez on 2017/08/14.
//  Copyright © 2017 edX. All rights reserved.
//

#import "OEXLinkedInAuthProvider.h"

#import "edX-Swift.h"

#import "OEXExternalAuthProviderButton.h"
#import "OEXLinkedInSocial.h"
#import "OEXRegisteringUserDetails.h"

@implementation OEXLinkedInAuthProvider

- (UIColor*)linkedInBlue {
    return [UIColor colorWithRed:0./255. green:119./255. blue:181./255. alpha:1];
}

- (NSString*)displayName {
    return @"LinkedIn";
}

- (NSString*)backendName {
    return @"linkedin-oauth2";
}

- (OEXExternalAuthProviderButton*)freshAuthButton {
    OEXExternalAuthProviderButton* button = [[OEXExternalAuthProviderButton alloc] initWithFrame:CGRectZero];
    button.provider = self;
    [button setImage:[UIImage imageNamed:@"icon_linkedin_white"] forState:UIControlStateNormal];
    [button useBackgroundImageOfColor:[self linkedInBlue]];
    return button;
}

- (void)authorizeServiceFromController:(UIViewController *)controller requestingUserDetails:(BOOL)loadUserDetails withCompletion:(void (^)(NSString *, OEXRegisteringUserDetails *, NSError *))completion {
    OEXLinkedInSocial* linkedInManager = [[OEXLinkedInSocial alloc] init];
    [linkedInManager loginFromController:controller completion:^(NSString *accessToken, NSError *error) {
        if(error) {
            completion(accessToken, nil, error);
            return;
        }
        if(loadUserDetails) {
            [linkedInManager requestUserProfileInfoWithCompletion:^(NSDictionary *userInfo, NSError *error) {
                NSLog(@"successfully call linkedin api");
                NSLog(@"%@", userInfo);
                // userInfo is a linkedIn user object
                OEXRegisteringUserDetails* profile = [[OEXRegisteringUserDetails alloc] init];
                profile.email = userInfo[@"emailAddress"];
                profile.name = [NSString stringWithFormat:@"%@ %@", userInfo[@"firstName"], userInfo[@"lastName"]];
                completion(accessToken, profile, error);
            }];
        }
        else {
            completion(accessToken, nil, error);
        }
        
    }];
}

@end
