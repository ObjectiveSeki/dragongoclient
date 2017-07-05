//
//  DGSPhoneAppDelegate.m
//  DGSPhone
//
//  Created by Justin Weiss on 6/1/10.
//  Copyright Justin Weiss 2010. All rights reserved.
//

#import "DGSPhoneAppDelegate.h"
#import "FuegoBoard.h"
#import "LoginViewController.h"
#import "DGSPushServer.h"
#import "Player.h"

NSString * const PlayerDidLoginNotification = @"PlayerDidLoginNotification";
NSString * const PlayerDidLogoutNotification = @"PlayerDidLogoutNotification";
NSString * const NetworkErrorNotification = @"NetworkErrorNotification";

NSString * const ReceivedNewGamesNotification = @"ReceivedNewGamesNotification";

NSString * const kLastKnownMoveKey = @"LastKnownMove";

@interface DGSPhoneAppDelegate ()
@property (nonatomic, strong) LoginViewController *loginController;

// I have to catch moves that were played while the app was closed /
// backgrounded, but I don't need to check if I already got push notifications.
// Unfortunately, there's no good activation hook method I can check to only
// check for outstanding notifications if we didn't receive a push notification.
@property (nonatomic) BOOL receivedRemoteNotification;
@end

@implementation DGSPhoneAppDelegate

#pragma mark - Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
	[FuegoBoard initFuego];
    self.receivedRemoteNotification = NO;
    
	NSLog(@"Starting Application...");
    NSDictionary *notificationUserInfo = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
    if (notificationUserInfo) {
        NSLog(@"Received remote notification: %@", notificationUserInfo);
        self.receivedRemoteNotification = YES;
        [self application:application handleRemoteNotification:notificationUserInfo];
    }
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reportMemoryLow) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    
    [self setupRemoteNotifications];
    
    if (!self.receivedRemoteNotification) {
        NSLog(@"Checking for outstanding moves...");
        [self checkForMissedGameNotificationsForApplication:application];
    }
    
	[self.window makeKeyAndVisible];
	NSLog(@"Showing main window...");
    
	return YES;
}

- (void)reportMemoryLow {
    NSLog(@"Low memory!");
}

- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
	NSLog(@"Went inactive...");
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PlayerDidLogoutNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PlayerDidLoginNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NetworkErrorNotification object:nil];
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
     */
	NSLog(@"Went into the background...");
    self.receivedRemoteNotification = NO;
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
     */
	NSLog(@"Went into the foreground...");
    
    if (!self.receivedRemoteNotification) {
        NSLog(@"Checking for outstanding moves...");
        [self checkForMissedGameNotificationsForApplication:application];
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
	NSLog(@"Went active...");
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showLoginAnimated:) name:PlayerDidLogoutNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clearPlayerData) name:PlayerDidLogoutNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissLogin) name:PlayerDidLoginNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(presentNetworkError:) name:NetworkErrorNotification object:nil];
}


- (void)applicationWillTerminate:(UIApplication *)application {
    /*
     Called when the application is about to terminate.
     See also applicationDidEnterBackground:.
     */
	[FuegoBoard finishFuego];
    
	NSLog(@"Terminating...");
}

#pragma mark - Move tracking for forcing game refreshes after starting manually
- (NSString *)lastKnownMove {
    return [[NSUserDefaults standardUserDefaults] valueForKey:kLastKnownMoveKey];
}

- (void)setLastKnownMove:(NSString *)lastKnownMove {
    NSString *latestMove = [lastKnownMove compare:self.lastKnownMove] == NSOrderedDescending ? lastKnownMove : self.lastKnownMove;
    [[NSUserDefaults standardUserDefaults] setValue:latestMove forKey:kLastKnownMoveKey];
}

- (void)clearPlayerData {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kLastKnownMoveKey];
}

- (void)checkForMissedGameNotificationsForApplication:(UIApplication *)application {
    [[DGSPushServer sharedPushServer] fetchGamesUpdatedSince:self.lastKnownMove completionHandler:^(NSArray *games) {
        if (games.count > 0) {
            [self application:application handleRemoteNotification:@{}];
        }
    } errorHandler:^(NSError *error) {
        NSLog(@"%@", error);
    }];
}

#pragma mark - Navigation

- (void)goToCurrentGamesViewControllerAnimated:(BOOL)animated {
    UIViewController *rootViewController = [self.window rootViewController];
    [rootViewController dismissViewControllerAnimated:animated completion:^{ }];
    
    if ([rootViewController isKindOfClass:[UINavigationController class]]) {
        [((UINavigationController *)rootViewController) popToRootViewControllerAnimated:animated];
    }
}

#pragma mark - Login

- (void)showLoginAnimated:(NSNotification *)notification {
    [self unregisterForRemoteNotifications:notification];
    [self showLogin:YES];
}

- (void)showLogin:(BOOL)animated {
    if (!self.loginController) {
        self.loginController = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
        [self.window.rootViewController presentViewController:self.loginController animated:animated completion:^() {}];
    }
}

- (void)dismissLogin {
    [self setupRemoteNotifications];
    [self.loginController dismissViewControllerAnimated:YES completion:^{}];
    self.loginController = nil;
}

#pragma mark - Error handling

- (void)presentNetworkError:(NSNotification *)notification {
    NSError *error = notification.object;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                             message:[error localizedDescription]
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Dismiss", @"Dismiss")
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * action) {}]];
    [[self.window rootViewController] presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Push notifications

- (void)setupRemoteNotifications {
    [[DGSPushServer sharedPushServer] setupRemoteNotifications];
}

- (void)unregisterForRemoteNotifications:(NSNotification *)notification {
    Player *oldPlayer = [notification object];
    [[DGSPushServer sharedPushServer] deleteAPNSDeviceTokenForPlayerId:oldPlayer.userId completionHandler:^() { } errorHandler:^(NSError *error) {
        NSLog(@"Error clearing push token: %@", error);
    }];
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    [[UIApplication sharedApplication] registerForRemoteNotifications];
    
}

- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)token {
    [[DGSPushServer sharedPushServer] createLoginCookies:[[GenericGameServer sharedGameServer] cookiesForCurrentUser]
    completionHandler:^{
        [[DGSPushServer sharedPushServer] updateAPNSDeviceToken:token completionHandler:^{
        } errorHandler:^(NSError *error) {
            NSLog(@"Error updating push token: %@", error);
        }];
    } errorHandler:^(NSError *error) {
        NSLog(@"Error updating session: %@", error);
    }];
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"Error updating push token: %@", error);
    [[DGSPushServer sharedPushServer] didFailToRegisterForRemoteNotificationsWithError:error];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    NSLog(@"Received remote notification: %@", userInfo);
    self.receivedRemoteNotification = YES;
    [self application:application handleRemoteNotification:userInfo];
}

- (void)application:(UIApplication *)application handleRemoteNotification:(NSDictionary *)userInfo {
    NSLog(@"Handling remote notification: %@", userInfo);

    if (application.applicationState == UIApplicationStateInactive) {
        [self goToCurrentGamesViewControllerAnimated:NO];
    } else {
        NSLog(@"App was running in the foreground");
    }
    // Make sure the game server is awake, since it will probably care about this notification.
    [GenericGameServer sharedGameServer];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ReceivedNewGamesNotification object:userInfo];
}

#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
	NSLog(@"Memory warning...");
}

@end
