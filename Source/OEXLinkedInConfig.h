//
//  OEXLinkedInConfig.h
//  edX
//
//  Created by Jose Antonio Gonzalez on 2017/08/14.
//  Copyright © 2017 edX. All rights reserved.
//

#import "OEXConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface OEXLinkedInConfig : NSObject
@property(nonatomic, readonly, assign, getter = isEnabled) BOOL enabled;
@property(nonatomic, readonly, assign, getter = isGetProfile) BOOL getProfile;

- (instancetype)initWithDictionary:(NSDictionary*)dictionary;

@end

@interface OEXConfig (LinkedIn)

@property (nullable, readonly, strong, nonatomic) OEXLinkedInConfig* linkedInConfig;

@end

NS_ASSUME_NONNULL_END
