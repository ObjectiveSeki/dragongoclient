//
//  Controller showing waiting room game details, with a 'join' button.
//

#import <UIKit/UIKit.h>
#import "NewGame.h"
#import "JWTableViewController.h"

@interface JoinWaitingRoomGameController : JWTableViewController {
	NewGame *game;
    UIAlertView *deleteConfirmation;
}

@property (nonatomic, strong) NewGame *game;
@property (nonatomic, strong) UIAlertView *deleteConfirmation;

@end
