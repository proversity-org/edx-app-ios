//
//  OEXLinkedInConfig.m
//  edX
//
//  Created by Jose Antonio Gonzalez on 2017/08/14.
//  Copyright © 2017 edX. All rights reserved.
//

#import "OEXLinkedInConfig.h"

static NSString* const OEXLinkedInConfigKey = @"LINKEDIN";
static NSString* const OEXLinkedInEnabledKey = @"ENABLED";
static NSString* const OEXLinkedInGetProfileKey = @"GET_PROFILE";

@interface OEXLinkedInConfig () {
    BOOL _enabled;
    BOOL _getProfile;
}

@end

@implementation OEXLinkedInConfig

- (instancetype)initWithDictionary:(NSDictionary*)dictionary {
    self = [super init];
    if(self) {
        _enabled = [dictionary[@"ENABLED"] boolValue];
        _getProfile = [dictionary[@"GET_PROFILE"] boolValue];
    }
    return self;
}

@end

@implementation OEXConfig (LinkedIn)

- (OEXLinkedInConfig*)linkedInConfig {
    NSDictionary* dictionary = [self objectForKey:OEXLinkedInConfigKey];
    OEXLinkedInConfig* linkedInConfig = [[OEXLinkedInConfig alloc] initWithDictionary:dictionary];
    return linkedInConfig;
}

@end
