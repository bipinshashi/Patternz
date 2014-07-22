//
//  PZAppDelegate.m
//  Patternz
//
//  Created by Bipen Sasi on 6/7/14.
//  Copyright (c) 2014 Bipen Sasi. All rights reserved.
//

#import "PZAppDelegate.h"
#import "TestFlight.h"
#import "Mixpanel.h"
#import "iRate.h"

#define MIXPANEL_TOKEN @"f242ee7d36033a9beae043dee1a49c99"

@implementation PZAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    [TestFlight takeOff:@"5e5cccb7-d2d6-4025-b98f-5a3eccce3804"];
    [Mixpanel sharedInstanceWithToken:MIXPANEL_TOKEN];
    NSString *uniqueID = [NSString stringWithFormat:@"%@",[UIDevice currentDevice].identifierForVendor.UUIDString];
    [[Mixpanel sharedInstance] identify:uniqueID];
    return YES;
}

+ (void)initialize
{
    [iRate sharedInstance].daysUntilPrompt = 3;
    [iRate sharedInstance].usesUntilPrompt = 5;
}

							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)iRateUserDidAttemptToRateApp
{
    [[Mixpanel sharedInstance] track:@"App rating" properties:@{@"type": @"Attempted"}];
}

-(void)iRateUserDidRequestReminderToRateApp
{
    [[Mixpanel sharedInstance] track:@"App rating" properties:@{@"type": @"Reminder"}];
}

-(void)iRateUserDidDeclineToRateApp
{
    [[Mixpanel sharedInstance] track:@"App rating" properties:@{@"type": @"Decline"}];
}
@end
