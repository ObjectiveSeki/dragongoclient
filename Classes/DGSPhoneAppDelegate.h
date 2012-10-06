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
}

@property (nonatomic, strong) IBOutlet UIWindow *window;
@property (nonatomic, strong) IBOutlet UIViewController *viewController;
@property (nonatomic, strong) UIImage *blackStone;
@property (nonatomic, strong) UIImage *whiteStone;
@property (nonatomic, strong) UIImage *boardImage;
@property (nonatomic, strong) UIImage *messageOff;
@property (nonatomic, strong) UIImage *messageOn;
@property (nonatomic, strong) NSFileHandle *logFile;

- (NSString *)logFilePath;

@end
