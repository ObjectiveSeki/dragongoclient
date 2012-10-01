//
//  Table of waiting room games.
//

#import <UIKit/UIKit.h>
#import "JWTableViewController.h"
#import "DGS.h"
#import "GameList.h"

@interface WaitingRoomGamesController : JWTableViewController {
    UIView *noGamesView;
}

@property (nonatomic, strong) IBOutlet UIView *noGamesView;

- (void)setGames:(GameList *)gameList;
- (IBAction)addGame:(id)sender;

@end
