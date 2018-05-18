//
//  OEXAppDelegate.m
//  edXVideoLocker
//
//  Created by Nirbhay Agarwal on 15/05/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

@import edXCore;
#import <Crashlytics/Crashlytics.h>
#import <Fabric/Fabric.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <GoogleSignIn/GoogleSignIn.h>
#import <NewRelicAgent/NewRelic.h>
#import <Analytics/SEGAnalytics.h>
#import <Branch/Branch.h>
#import <FirebaseCore/FirebaseCore.h>
#import <FirebaseMessaging/FirebaseMessaging.h>

#import "OEXAppDelegate.h"
#import "HPNService.h"

#import "edX-Swift.h"
#import "Logger+OEXObjC.h"

#import "OEXAuthentication.h"
#import "OEXConfig.h"
#import "OEXDownloadManager.h"
#import "OEXEnvironment.h"
#import "OEXFabricConfig.h"
#import "OEXFacebookConfig.h"
#import "OEXGoogleConfig.h"
#import "OEXGoogleSocial.h"
#import "OEXInterface.h"
#import "OEXNewRelicConfig.h"
#import "OEXPushProvider.h"
#import "OEXPushNotificationManager.h"
#import "OEXPushSettingsManager.h"
#import "OEXRouter.h"
#import "OEXSession.h"
#import "OEXSegmentConfig.h"
#import <UserNotifications/UserNotifications.h>

@interface OEXAppDelegate () <UIApplicationDelegate, UNUserNotificationCenterDelegate, FIRMessagingDelegate>

@property (nonatomic, strong) NSMutableDictionary* dictCompletionHandler;
@property (nonatomic, strong) OEXEnvironment* environment;

@end


@implementation OEXAppDelegate

@synthesize window = _window;

- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
#if DEBUG
    // Skip all this initialization if we're running the unit tests
    // So they can start from a clean state.
    // dispatch_async so that the XCTest bundle (where TestEnvironmentBuilder lives) has already loaded
    if([[NSProcessInfo processInfo].arguments containsObject:@"-UNIT_TEST"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            Class builder = NSClassFromString(@"TestEnvironmentBuilder");
            NSAssert(builder != nil, @"Can't find test environment builder");
            (void)[[builder alloc] init];
        });
        return YES;
    }
    if([[NSProcessInfo processInfo].arguments containsObject:@"-END_TO_END_TEST"]) {
        [[[OEXSession alloc] init] closeAndClearSession];
        [OEXFileUtility nukeUserData];
    }
#endif

    // logout user automatically if server changed
    [[[ServerChangedChecker alloc] init] logoutIfServerChanged];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];

    [self setupGlobalEnvironment];
    [self.environment.session performMigrations];

    [self.environment.router openInWindow:self.window];
    
    [self configureFabricKits:launchOptions];
    
    if (self.environment.config.pushNotificationsEnabled) {
        [FIRApp configure];
        [FIRMessaging messaging].delegate = self;
        if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_9_x_Max) {
            UIUserNotificationType allNotificationTypes =
            (UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge);
            UIUserNotificationSettings *settings =
            [UIUserNotificationSettings settingsForTypes:allNotificationTypes categories:nil];
            [application registerUserNotificationSettings:settings];
        } else {
            // iOS 10 or later
#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
            // For iOS 10 display notification (sent via APNS)
            [UNUserNotificationCenter currentNotificationCenter].delegate = self;
            UNAuthorizationOptions authOptions =
            UNAuthorizationOptionAlert
            | UNAuthorizationOptionSound
            | UNAuthorizationOptionBadge;
            [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:authOptions completionHandler:^(BOOL granted, NSError * _Nullable error) {
            }];
#endif
        }
        
        [application registerForRemoteNotifications];
    }
    
    return [[FBSDKApplicationDelegate sharedInstance] application:application didFinishLaunchingWithOptions:launchOptions];
}

- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window{
    
    UIViewController *topController = self.window.rootViewController;
    
    return [topController supportedInterfaceOrientations];
}


- (BOOL)application:(UIApplication*)application openURL:(NSURL*)url sourceApplication:(NSString*)sourceApplication annotation:(id)annotation {
    BOOL handled = false;
    if (self.environment.config.facebookConfig.enabled) {
        handled = [[FBSDKApplicationDelegate sharedInstance] application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
        if(handled) {
            return handled;
        }

    }
    
    if (self.environment.config.googleConfig.enabled){
        handled = [[GIDSignIn sharedInstance] handleURL:url sourceApplication:sourceApplication annotation:annotation];
        [[OEXGoogleSocial sharedInstance] setHandledOpenUrl:YES];
    }
   
    return handled;
}

// Respond to URI scheme links
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    // pass the url to the handle deep link call
    BOOL handled = false;
    if (self.environment.config.fabricConfig.kits.branchConfig.enabled) {
        handled = [[Branch getInstance] application:app openURL:url options:options];
        if (handled) {
            return handled;
        }
    }
    
    if (self.environment.config.facebookConfig.enabled) {
        handled = [[FBSDKApplicationDelegate sharedInstance] application:app openURL:url options:options];
        if (handled) {
            return handled;
        }
    }
    
    if (self.environment.config.googleConfig.enabled){
        handled = [[GIDSignIn sharedInstance] handleURL:url
                                   sourceApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey]
                                          annotation:options[UIApplicationOpenURLOptionsAnnotationKey]];
    }
    
    return handled;
}

// Respond to Universal Links
- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray *restorableObjects))restorationHandler {
    
    if (self.environment.config.fabricConfig.kits.branchConfig.enabled) {
        return [[Branch getInstance] continueUserActivity:userActivity];
    }
    return NO;
}

#pragma mark Push Notifications

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    [self.environment.pushNotificationManager didReceiveRemoteNotificationWithUserInfo:userInfo];
    completionHandler(UIBackgroundFetchResultNewData);
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    [self.environment.pushNotificationManager didReceiveLocalNotificationWithUserInfo:notification.userInfo];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [FIRMessaging messaging].APNSToken = deviceToken;
    [[FIRMessaging messaging] subscribeToTopic:self.environment.config.mainTopic];
    [self.environment.pushNotificationManager didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    [self.environment.pushNotificationManager didFailToRegisterForRemoteNotificationsWithError:error];
}

#pragma mark Background Downloading

- (void)application:(UIApplication*)application handleEventsForBackgroundURLSession:(NSString*)identifier completionHandler:(void (^)(void))completionHandler {
    [OEXDownloadManager sharedManager];
    [self addCompletionHandler:completionHandler forSession:identifier];
}

- (void)addCompletionHandler:(void (^)(void))handler forSession:(NSString*)identifier {
    if(!_dictCompletionHandler) {
        _dictCompletionHandler = [[NSMutableDictionary alloc] init];
    }
    if([self.dictCompletionHandler objectForKey:identifier]) {
        OEXLogError(@"DOWNLOADS", @"Error: Got multiple handlers for a single session identifier.  This should not happen.\n");
    }
    [self.dictCompletionHandler setObject:handler forKey:identifier];
}

- (void)callCompletionHandlerForSession:(NSString*)identifier {
    dispatch_block_t handler = [self.dictCompletionHandler objectForKey: identifier];
    if(handler) {
        [self.dictCompletionHandler removeObjectForKey: identifier];
        OEXLogInfo(@"DOWNLOADS", @"Calling completion handler for session %@", identifier);
        //[self presentNotification];
        handler();
    }
}

#pragma mark Environment

- (void)setupGlobalEnvironment {
    [UserAgentOverrideOperation overrideUserAgentWithCompletion:nil];
    
    self.environment = [[OEXEnvironment alloc] init];
    [self.environment setupEnvironment];

    OEXConfig* config = self.environment.config;

    //Logging
    [DebugMenuLogger setup];

    //Rechability
    self.reachability = [[InternetReachability alloc] init];
    [_reachability startNotifier];

    //SegmentIO
    OEXSegmentConfig* segmentIO = [config segmentConfig];
    if(segmentIO.apiKey && segmentIO.isEnabled) {
        [SEGAnalytics setupWithConfiguration:[SEGAnalyticsConfiguration configurationWithWriteKey:segmentIO.apiKey]];
    }
    
    //Initialize Firebase
    if (config.isFirebaseEnabled) {
        [FIRApp configure];
        [[FIRAnalyticsConfiguration sharedInstance] setAnalyticsCollectionEnabled:YES];
    }

    //NewRelic Initialization with edx key
    OEXNewRelicConfig* newrelic = [config newRelicConfig];
    if(newrelic.apiKey && newrelic.isEnabled) {
        [NewRelicAgent enableCrashReporting:NO];
        [NewRelicAgent startWithApplicationToken:newrelic.apiKey];
    }

    //Initialize Fabric
    OEXFabricConfig* fabric = [config fabricConfig];
    if(fabric.appKey && fabric.isEnabled) {
        [Fabric with:@[CrashlyticsKit]];
    }
    
}

- (void) configureFabricKits:(NSDictionary*) launchOptions {
    if (self.environment.config.fabricConfig.kits.branchConfig.enabled) {
        [Branch setBranchKey:self.environment.config.fabricConfig.kits.branchConfig.branchKey];
        if ([Branch branchKey]){
            [[Branch getInstance] initSessionWithLaunchOptions:launchOptions andRegisterDeepLinkHandler:^(NSDictionary *params, NSError *error) {
                // params are the deep linked params associated with the link that the user clicked -> was re-directed to this app
                // params will be empty if no data found
            }];
        }
    }
}

#pragma mark Firebase
- (void)messaging:(FIRMessaging *)messaging didReceiveRegistrationToken:(NSString *)fcmToken {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSLog(@"FCM registration token: %@", fcmToken);
    [[FIRMessaging messaging] subscribeToTopic:self.environment.config.mainTopic];
    
    // TODO: If necessary send token to application server.
    // Note: This callback is fired at each app startup and whenever a new token is generated.
}

- (void)applicationReceivedRemoteMessage:(nonnull FIRMessagingRemoteMessage *)remoteMessage {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSLog(@"%@", remoteMessage);
}

@end
