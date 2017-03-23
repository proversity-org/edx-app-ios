//
//  KPNService.h
//  edX
//
//  Created by Pro_Dev on 2017/03/23.
//  Copyright © 2017 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Foundation/Foundation.h>

typedef void (^onComplete)(NSDictionary * __nullable data, NSError * __nullable error);

@interface KPNService : NSObject

+ (id __nonnull)instance;
+ (id __nonnull)initWithDeviceToken:(NSString * __nonnull)deviceToken
                               Mode:(NSString * __nonnull)mode;

- (NSString * __nonnull)getDeviceToken;
- (NSString * __nonnull)getMode;

- (void)createMobileEndpoint:(NSDictionary * __nonnull)payload
           CompletionHandler:(onComplete __nullable)completionHandler;
- (void)subscribe:(NSDictionary * __nonnull)payload
CompletionHandler:(onComplete __nullable)completionHandler;

@end
