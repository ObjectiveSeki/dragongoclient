//
//  InviteViewController.m
//  DGSPhone
//
//  Created by Matthew Knippen on 9/25/13.
//  Copyright (c) 2013 Justin Weiss. All rights reserved.
//

#import "InviteViewController.h"
#import "Invite.h"
#import "NewGame.h"

@interface InviteViewController ()

@property (weak, nonatomic) IBOutlet UITableViewCell *opponentNameCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *opponentRatingCell;

@property (weak, nonatomic) IBOutlet UITableViewCell *boardSizeCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *handicapStonesCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *ratedCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *timeCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *colorCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *rulesCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *komiCell;


@end

@implementation InviteViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [self refreshData];
}

- (void)refreshData {
    self.title = [NSString stringWithFormat:@"Invite: %@", self.invite.opponent];
    NewGame *game = self.invite.gameDetails;

    self.opponentNameCell.detailTextLabel.text = game.opponent;
    self.opponentRatingCell.detailTextLabel.text = game.opponentRating;

    self.boardSizeCell.detailTextLabel.text = [NSString stringWithFormat:@"%dx%d", game.boardSize, game.boardSize];
    self.handicapStonesCell.detailTextLabel.text = [NSString stringWithFormat:@"%d", game.handicap];
    if (game.rated) {
        self.ratedCell.detailTextLabel.text = @"Yes";
    } else {
        self.ratedCell.detailTextLabel.text = @"No";
    }
    self.timeCell.detailTextLabel.text = game.time;
    if (game.color == kMovePlayerBlack) {
        self.colorCell.detailTextLabel.text = @"Black";
    } else if (game.color == kMovePlayerWhite) {
        self.colorCell.detailTextLabel.text = @"White";
    } else {
        self.colorCell.detailTextLabel.text = @"Nigiri";
    }

    if (game.ruleSet == kRuleSetJapanese) {
        self.rulesCell.detailTextLabel.text = @"Japanese";
    } else {
        self.rulesCell.detailTextLabel.text = @"Chinese";
    }

    self.komiCell.detailTextLabel.text = [NSString stringWithFormat:@"%.1f", game.komi];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1) {
        BOOL accepted = NO;
        if (indexPath.row == 0) {
            accepted = YES;
        }

        [[GenericGameServer sharedGameServer] answerInvite:self.invite accepted:accepted onSuccess:^(Invite *invite) {
            [self.navigationController popViewControllerAnimated:YES];
        } onError:^(NSError *error) {
            //probably should notify the user
        }];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
