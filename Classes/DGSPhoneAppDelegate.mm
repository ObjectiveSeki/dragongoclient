//
//  DGSPhoneAppDelegate.m
//  DGSPhone
//
//  Created by Justin Weiss on 6/1/10.
//  Copyright Justin Weiss 2010. All rights reserved.
//

#import "DGSPhoneAppDelegate.h"
#import "CurrentGamesController.h"
#import "FuegoBoard.h"
#import "LoginViewController.h"

#ifdef CACHING
#import "CachingGameServer.h"
#endif

NSString * const PlayerDidLoginNotification = @"PlayerDidLoginNotification";
NSString * const PlayerDidLogoutNotification = @"PlayerDidLogoutNotification";

@interface DGSPhoneAppDelegate ()
@property (nonatomic, strong) LoginViewController *loginController;
@end

@implementation DGSPhoneAppDelegate

@synthesize window;
@synthesize viewController;
@synthesize blackStone;
@synthesize whiteStone;
@synthesize boardImage;
@synthesize messageOff;
@synthesize messageOn;

#pragma mark -
#pragma mark Application lifecycle

- (NSString *)logFilePath {
	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	if ([paths count] > 0) {
		return [paths[0] stringByAppendingPathComponent:@"dgs-debug.log"];
	}
	return nil;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
	[FuegoBoard initFuego];
    // Override point for customization after application launch.

#ifdef TESTFLIGHT_UUID_TRACKING
    TF([TestFlight setDeviceIdentifier:[[UIDevice currentDevice] uniqueIdentifier]]);
#endif
    
    TF([TestFlight takeOff:TESTFLIGHT_APP_TOKEN]);

	NSLog(@"Starting Application...");
	
	[self setBlackStone:[UIImage imageNamed:@"Black.png"]];
	[self setWhiteStone:[UIImage imageNamed:@"White.png"]];
	[self setBoardImage:[UIImage imageNamed:@"Board.png"]];
	[self setMessageOff:[UIImage imageNamed:@"Message off.png"]];
	[self setMessageOn:[UIImage imageNamed:@"Message on.png"]];
	NSLog(@"Loaded Images...");
	NSLog(@"Initialized controllers...");

	[window makeKeyAndVisible];
	NSLog(@"Showing main window...");
	
	return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
	NSLog(@"Went inactive...");
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PlayerDidLogoutNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PlayerDidLoginNotification object:nil];
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
     */
	NSLog(@"Went into the background...");
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
     */
	NSLog(@"Went into the foreground...");
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
	NSLog(@"Went active...");
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showLogin:) name:PlayerDidLogoutNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissLogin) name:PlayerDidLoginNotification object:nil];
}


- (void)applicationWillTerminate:(UIApplication *)application {
    /*
     Called when the application is about to terminate.
     See also applicationDidEnterBackground:.
     */
	[FuegoBoard finishFuego];
    
	NSLog(@"Terminating...");
}

#pragma mark - Login

- (void)showLoginAnimated:(NSNotification *)notification {
    [self showLogin:YES];
}

- (void)showLogin:(BOOL)animated {
    if (!self.loginController) {
        self.loginController = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
        [self.window.rootViewController presentViewController:self.loginController animated:animated completion:^() {}];
    }
}

- (void)dismissLogin {
    [self.loginController dismissModalViewControllerAnimated:YES];
    self.loginController = nil;
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
