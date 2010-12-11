//
//  MainTabViewController.h
//  DGSPhone
//
//  Created by Justin Weiss on 12/9/10.
//

#import <UIKit/UIKit.h>
#import "CurrentGamesController.h"

@interface MainTabViewController : UIViewController {
	CurrentGamesController *currentGamesController;
	UIViewController *selectedViewController;
	UITabBar *tabBar;
	UITabBarItem *currentGamesTab;
	UITabBarItem *otherGamesTab;
}

@property(nonatomic, retain) CurrentGamesController *currentGamesController;
@property(nonatomic, retain) UIViewController *selectedViewController;
@property(nonatomic, retain) IBOutlet UITabBar *tabBar;
@property(nonatomic, retain) IBOutlet UITabBarItem *currentGamesTab;
@property(nonatomic, retain) IBOutlet UITabBarItem *otherGamesTab;

- (void)setViewController:(UIViewController *)viewController callbacks:(BOOL)callbacks;

@end
