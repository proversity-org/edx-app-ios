//
//  HPNService.m
//  edX
//
//  Created by José Antonio González on 2018/05/17.
//  Copyright © 2018 edX. All rights reserved.
//

#import <FirebaseCore/FirebaseCore.h>
#import <FirebaseMessaging/FirebaseMessaging.h>
#import "HPNService.h"

#define KONNEKTEER_API_URL "https://viz8n9p0ci.execute-api.us-east-1.amazonaws.com/prod/konnekteer"
#define SUBSCRIBE "/saveTopicSubscription"

@implementation HPNService

+ (id __nonnull)instance
{
    static HPNService *instance = nil;
    @synchronized (self) {
        if (instance == nil) {
            instance = [[self alloc] init];
        }
    }
    
    return instance;
}

- (void)subscribe:(NSString * __nonnull)authKey
      WithPayload:(NSDictionary * __nonnull)payload
CompletionHandler:(onComplete __nullable)completionHandler
{
    @try {
        [[FIRMessaging messaging] subscribeToTopic:payload[@"topic"]];
    } @catch (NSException *exception) {
        NSLog(@"%@", exception.reason);
    }
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%s%s", KONNEKTEER_API_URL, SUBSCRIBE]];
    NSMutableURLRequest *urlRequest = [self prepareUrlRequest:url
                                                  WithAuthKey: authKey
                                                  AndPayload:payload];
    
    NSURLSessionDataTask *task = [self getSessionDataTaskFromUrl:urlRequest
                                               completionHandler:completionHandler];
    
    [task resume];
}

#pragma mark - Helpers

- (NSMutableURLRequest *)prepareUrlRequest:(NSURL * __nonnull)url
                               WithAuthKey:(NSString* __nonnull)authKey
                               AndPayload:(NSDictionary * __nonnull)payload
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
    [urlRequest setValue:authKey
      forHTTPHeaderField:@"Authorization"];
    
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
