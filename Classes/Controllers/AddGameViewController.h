//
//  AddGameViewController.h
//  DGSPhone
//
//  Created by Justin Weiss on 6/28/10.
//  Copyright 2010 Justin Weiss. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TextCell.h"
#import "NewGame.h"
#import "DGS.h"
#import "Player.h"
#import "PickerTableViewCellDelegate.h"

@interface AddGameViewController : UITableViewController <PickerTableViewCellDelegate> {
}

@property (strong, nonatomic) IBOutlet UIBarButtonItem *cancelButton;
@property (nonatomic, strong) TextCell *descriptionCell;
@property (nonatomic, strong) UITableViewCell *createGameButton;
@property (nonatomic, strong) NewGame *game;
@property (nonatomic, strong) Player *player;
- (IBAction)dismiss:(id)sender;

- (void)pickerTableViewCell:(PickerTableViewCell *)pickerCell didSelectRow:(NSInteger)row inComponent:(NSInteger)component;

@end

