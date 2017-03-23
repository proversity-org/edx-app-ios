//
//  KPNService.m
//  edX
//
//  Created by Pro_Dev on 2017/03/23.
//  Copyright © 2017 edX. All rights reserved.
//

#import "KPNService.h"

#import "KPNService.h"

#define KONNEKTEER_API_URL "http://konnekteer-api.proversity.org"
#define MOBILE_ENDPOINT "/mobileEndpoints"
#define SUBSCRIBE "/subscribe"

@implementation KPNService

#pragma mark - Singleton

+ (id __nonnull)instance
{
    static KPNService *instance = nil;
    @synchronized (self) {
        if (instance == nil) {
            instance = [[self alloc] init];
        }
    }
    
    return instance;
}

+ (id __nonnull)initWithDeviceToken:(NSString * __nonnull)deviceToken
                               Mode:(NSString * _Nonnull)mode
{
    [[NSUserDefaults standardUserDefaults] setObject:deviceToken forKey:@"deviceToken"];
    [[NSUserDefaults standardUserDefaults] setObject:mode forKey:@"mode"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    return self;
}

- (NSString * __nonnull)getDeviceToken
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"deviceToken"];
}

- (NSString * __nonnull)getMode
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"mode"];
}

#pragma mark - Konnekteer

- (void)createMobileEndpoint:(NSDictionary * __nonnull)payload
           CompletionHandler:(onComplete __nullable)completionHandler
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%s%s", KONNEKTEER_API_URL, MOBILE_ENDPOINT]];
    NSMutableURLRequest *urlRequest = [self prepareUrlRequest:url
                                                  WithPayload:payload];
    
    NSURLSessionDataTask *task = [self getSessionDataTaskFromUrl:urlRequest
                                               completionHandler:completionHandler];
    
    [task resume];
}

- (void)subscribe:(NSDictionary * __nonnull)payload
CompletionHandler:(onComplete __nullable)completionHandler
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%s%s%s", KONNEKTEER_API_URL, MOBILE_ENDPOINT, SUBSCRIBE]];
    NSMutableURLRequest *urlRequest = [self prepareUrlRequest:url
                                                  WithPayload:payload];
    
    NSURLSessionDataTask *task = [self getSessionDataTaskFromUrl:urlRequest
                                               completionHandler:completionHandler];
    
    [task resume];
}

#pragma mark - Helpers

- (NSMutableURLRequest *)prepareUrlRequest:(NSURL * __nonnull)url
                               WithPayload:(NSDictionary * __nonnull)payload
{
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc]
                                       initWithURL:url];
    NSError *error;
    NSData *postData = [NSJSONSerialization dataWithJSONObject:payload
                                                       options:0
                                                         error:&error];
    
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setValue:@"application/json"
      forHTTPHeaderField:@"Content-Type"];
    
    [urlRequest setHTTPBody:postData];
    return urlRequest;
}

- (NSURLSessionDataTask *)getSessionDataTaskFromUrl:(NSMutableURLRequest *)urlRequest
                                  completionHandler:(onComplete __nonnull)completionHandler
{
    NSURLSession * session = [NSURLSession sharedSession];
    return [session dataTaskWithRequest:urlRequest
                      completionHandler:^(NSData * _Nullable data,
                                          NSURLResponse * _Nullable response,
                                          NSError * _Nullable error)
            {
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                NSLog(@"%ld", httpResponse.statusCode);
                NSLog(@"%@", error);
                if (data != nil) {
                    NSError *err;
                    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data
                                                                         options:NSJSONReadingAllowFragments
                                                                           error:&err];
                    
                    if (err == nil) {
                        completionHandler(json, nil);
                    } else {
                        completionHandler(nil, err);
                    }
                } else {
                    completionHandler(nil, error);
                }
            }];
}

@end
