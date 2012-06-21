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

@property (nonatomic, retain) NewGame *game;
@property (nonatomic, retain) UIAlertView *deleteConfirmation;

@end
