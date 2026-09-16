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
    self.window.tintColor = [UIColor systemOrangeColor];
    self.window.backgroundColor = [UIColor colorNamed:@"AppBackground"];
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
