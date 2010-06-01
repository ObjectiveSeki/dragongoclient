//
//  DGSPhoneAppDelegate.h
//  DGSPhone
//
//  Created by Justin Weiss on 6/1/10.
//  Copyright Avvo 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DGSPhoneAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
	UIWindow *loginWindow
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UIWindow *loginWindow;

@end

