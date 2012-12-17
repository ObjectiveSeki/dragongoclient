//
//  Table of waiting room games.
//

#import <UIKit/UIKit.h>

@class GameList;

@interface WaitingRoomGamesController : UITableViewController

@property (nonatomic, strong) IBOutlet UIView *noGamesView;
@property (nonatomic, strong) GameList *gameList;

@end
