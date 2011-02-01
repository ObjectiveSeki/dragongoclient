//
//  Controller showing waiting room game details, with a 'join' button.
//

#import <UIKit/UIKit.h>
#import "NewGame.h"
#import "JWTableViewController.h"
#import "DGS.h"

@interface JoinWaitingRoomGameController : JWTableViewController {
	NewGame *game;
	DGS *dgs;
	NSString *message;
}

@property (nonatomic, retain) NewGame *game;
@property (nonatomic, retain) DGS *dgs;
@property (nonatomic, retain) NSString *message;

@end
