//
//  DGSSceneDelegate.m
//  DGSPhone
//

#import "DGSSceneDelegate.h"
#import "DGSPhoneAppDelegate.h"

@implementation DGSSceneDelegate

- (DGSPhoneAppDelegate *)appDelegate {
    return (DGSPhoneAppDelegate *)[UIApplication sharedApplication].delegate;
}

- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions {
    if (![scene isKindOfClass:[UIWindowScene class]]) return;

    self.appDelegate.window = self.window;
    [self.window setTintColor:[UIColor colorWithRed:0.92 green:0.60 blue:0.29 alpha:1.0]];
    [self.window makeKeyAndVisible];

    UNNotificationResponse *notificationResponse = connectionOptions.notificationResponse;
    if (notificationResponse) {
        [self.appDelegate userNotificationCenter:[UNUserNotificationCenter currentNotificationCenter]
                  didReceiveNotificationResponse:notificationResponse
                           withCompletionHandler:^{}];
    }
}

- (void)sceneWillResignActive:(UIScene *)scene {
    [self.appDelegate applicationWillResignActive:[UIApplication sharedApplication]];
}

- (void)sceneDidEnterBackground:(UIScene *)scene {
    [self.appDelegate applicationDidEnterBackground:[UIApplication sharedApplication]];
}

- (void)sceneWillEnterForeground:(UIScene *)scene {
    [self.appDelegate applicationWillEnterForeground:[UIApplication sharedApplication]];
}

- (void)sceneDidBecomeActive:(UIScene *)scene {
    [self.appDelegate applicationDidBecomeActive:[UIApplication sharedApplication]];
}

@end
