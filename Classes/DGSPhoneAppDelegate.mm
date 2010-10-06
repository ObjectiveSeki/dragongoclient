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

#if defined (CONFIGURATION_Adhoc)
#import "BWHockeyController.h"
#endif

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

- (void)replaceViewController:(UIViewController *)aViewController {
	UIView *oldView = nil;
	if ([[window subviews] count] > 0) {
		oldView = [[window subviews] objectAtIndex:0];
	}
	[self setViewController:aViewController];
	[window addSubview:[aViewController view]];
	if (oldView) {
		[oldView removeFromSuperview];
	}
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
	[FuegoBoard initFuego];
    // Override point for customization after application launch.
	
#if defined (CONFIGURATION_Adhoc)
    [[BWHockeyController sharedHockeyController] setBetaURL:@"http://dgs.uberweiss.net/beta/index.php"];
#endif
	
	[self setBlackStone:[UIImage imageNamed:@"Black.png"]];
	[self setWhiteStone:[UIImage imageNamed:@"White.png"]];
	[self setBoardImage:[UIImage imageNamed:@"Board.png"]];
	[self setMessageOff:[UIImage imageNamed:@"Message off.png"]];
	[self setMessageOn:[UIImage imageNamed:@"Message on.png"]];
	
	
	CurrentGamesController *gamesController = [[CurrentGamesController alloc] initWithNibName:@"CurrentGamesView" bundle:nil];
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:gamesController];
	[self replaceViewController:navigationController];
	[navigationController release];
	[gamesController release];

	[window makeKeyAndVisible];
	
	return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
     */
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
     */
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}


- (void)applicationWillTerminate:(UIApplication *)application {
    /*
     Called when the application is about to terminate.
     See also applicationDidEnterBackground:.
     */
	[FuegoBoard finishFuego];
}


#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
}


- (void)dealloc {
	[blackStone release];
	[whiteStone release];
	[boardImage release];
	[messageOn release];
	[messageOff	release];
    [window release];
    [super dealloc];
}


@end
