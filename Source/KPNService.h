//
//  KPNService.h
//  edX
//
//  Created by José Antonio González on 12/12/16.
//  Copyright © 2016 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^onComplete)(NSDictionary * __nullable data, NSError * __nullable error);

@interface KPNService : NSObject

@property (nonnull, nonatomic, strong) NSString *username;
@property (nonnull, nonatomic, strong) NSString *email;

+ (id __nonnull)instance;
+ (id __nonnull)initWithDeviceToken:(NSString * __nonnull)deviceToken;
- (NSString * __nonnull)getDeviceToken;

- (void)createMobileEndpoint:(NSDictionary * __nonnull)payload
           CompletionHandler:(onComplete __nullable)completionHandler;
- (void)subscribe:(NSDictionary * __nonnull)payload
CompletionHandler:(onComplete __nullable)completionHandler;

@end
