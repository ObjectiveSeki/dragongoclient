//
//  Table of waiting room games.
//

#import <UIKit/UIKit.h>
#import "JWTableViewController.h"
#import "DGS.h"

@interface WaitingRoomGamesController : JWTableViewController {
    UIView *noGamesView;
}

@property (nonatomic, retain) IBOutlet UIView *noGamesView;

- (void)setGames:(NSArray *)games;
- (IBAction)addGame:(id)sender;

@end
