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
    self.boardSizeCell.detailTextLabel.text = [NSString stringWithFormat:@"%d", game.boardSize];
    self.handicapStonesCell.detailTextLabel.text = [NSString stringWithFormat:@"%d", game.handicap];
    if (game.rated) {
        self.ratedCell.detailTextLabel.text = @"Yes";
    } else {
        self.ratedCell.detailTextLabel.text = @"No";
    }
    self.timeCell.detailTextLabel.text = game.time;
    if (game.playerColorBlack) {
        self.colorCell.detailTextLabel.text = @"Black";
    } else {
        self.colorCell.detailTextLabel.text = @"White";
    }

    if (game.ruleSet == kRuleSetJapanese) {
        self.rulesCell.detailTextLabel.text = @"Japanese";
    } else {
        self.rulesCell.detailTextLabel.text = @"Chinese";
    }

    self.komiCell.detailTextLabel.text = [NSString stringWithFormat:@"%.1f", game.komi];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
