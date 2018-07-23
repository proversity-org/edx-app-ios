//
//  HPNService.h
//  edX
//
//  Created by José Antonio González on 2018/05/17.
//  Copyright © 2018 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^onComplete)(NSDictionary * __nullable data, NSError * __nullable error);

@interface HPNService : NSObject
    
+ (id __nonnull)instance;
    
- (void)subscribe:(NSString * __nonnull)authKey
      WithPayload:(NSDictionary * __nonnull)payload
CompletionHandler:(onComplete __nullable)completionHandler;
    
@end
