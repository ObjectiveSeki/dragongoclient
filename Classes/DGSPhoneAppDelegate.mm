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

#ifdef LOG_URL
#import "ASIFormDataRequest.h"
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
@synthesize logFile;

#ifdef LOG_URL
- (void)uploadLogFile
{
    NSURL *url = [NSURL URLWithString:LOG_URL];
    __block ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];

    NSString *logFilePath = [self logFilePath];
    
	if ([[NSFileManager defaultManager] fileExistsAtPath:logFilePath]) {

        NSFileHandle *myHandle = [NSFileHandle fileHandleForUpdatingAtPath:[self logFilePath]];
        NSData *data = [myHandle readDataToEndOfFile];
        NSString *body = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        [request setPostValue:body forKey:@"body"];
        [request setPostValue:[[UIDevice currentDevice] uniqueIdentifier] forKey:@"udid"];
        [body release];
        
        [request setCompletionBlock:^{
            NSFileHandle *myHandle = [NSFileHandle fileHandleForUpdatingAtPath:[self logFilePath]];
            [myHandle truncateFileAtOffset:0];
            if (self.logFile) {
                [self.logFile seekToFileOffset:0];
            }
        }];
        [request setFailedBlock:^{
        }];
        [request startAsynchronous];
    }
}
#endif

#pragma mark -
#pragma mark Application lifecycle

- (NSString *)logFilePath {
	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	if ([paths count] > 0) {
		return [paths[0] stringByAppendingPathComponent:@"dgs-debug.log"];
	}
	return nil;
}

#ifdef LOGGING
- (void)setupLogFile {
	NSString *logFilePath = [self logFilePath];
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:logFilePath]) {
		[[NSFileManager defaultManager] createFileAtPath:logFilePath contents:nil attributes:nil];
	}
	NSFileHandle *myHandle = [NSFileHandle fileHandleForUpdatingAtPath:[self logFilePath]];
	[myHandle seekToEndOfFile];
	
	self.logFile = myHandle;
	JWLog("Writing to log file at %@", [self logFilePath]);
}
#endif

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
	[FuegoBoard initFuego];
    // Override point for customization after application launch.
	
#ifdef LOGGING
	[self setupLogFile];
#endif

	JWLog("Starting Application...");
	
	[self setBlackStone:[UIImage imageNamed:@"Black.png"]];
	[self setWhiteStone:[UIImage imageNamed:@"White.png"]];
	[self setBoardImage:[UIImage imageNamed:@"Board.png"]];
	[self setMessageOff:[UIImage imageNamed:@"Message off.png"]];
	[self setMessageOn:[UIImage imageNamed:@"Message on.png"]];
	JWLog("Loaded Images...");
	JWLog("Initialized controllers...");	

	[window makeKeyAndVisible];
	JWLog("Showing main window...");
	
	return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
	JWLog("Went inactive...");
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PlayerDidLogoutNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PlayerDidLoginNotification object:nil];
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
     */
	JWLog("Went into the background...");
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
     */
	JWLog("Went into the foreground...");
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
	JWLog("Went active...");
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showLogin:) name:PlayerDidLogoutNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissLogin) name:PlayerDidLoginNotification object:nil];
    
#ifdef LOG_URL
    [self uploadLogFile];
#endif
}


- (void)applicationWillTerminate:(UIApplication *)application {
    /*
     Called when the application is about to terminate.
     See also applicationDidEnterBackground:.
     */
	[FuegoBoard finishFuego];
    
	JWLog("Terminating...");
#ifdef LOGGING
	[self.logFile closeFile];
	self.logFile = nil;
#endif
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
	JWLog("Memory warning...");
}




@end
