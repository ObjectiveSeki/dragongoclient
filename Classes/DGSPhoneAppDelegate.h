//
//  DGSPhoneAppDelegate.h
//  DGSPhone
//
//  Created by Justin Weiss on 6/1/10.
//  Copyright Justin Weiss 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DGSPhoneAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
	UIViewController *viewController;
	UIImage *blackStone;
	UIImage *whiteStone;
	UIImage *boardImage;
	UIImage *messageOff;
	UIImage *messageOn;
	NSFileHandle *logFile;
	NSDate *lastRefreshTime;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UIViewController *viewController;
@property (nonatomic, retain) UIImage *blackStone;
@property (nonatomic, retain) UIImage *whiteStone;
@property (nonatomic, retain) UIImage *boardImage;
@property (nonatomic, retain) UIImage *messageOff;
@property (nonatomic, retain) UIImage *messageOn;
@property (nonatomic, retain) NSFileHandle *logFile;
@property(nonatomic, retain) NSDate *lastRefreshTime;

- (NSString *)logFilePath;

- (void)invalidateThrottle;
- (void)resetThrottle;
- (BOOL)refreshThrottled;
- (BOOL)refreshShortThrottled;

@end

