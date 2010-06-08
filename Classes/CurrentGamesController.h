//
//  CurrentGamesController.h
//  DGSPhone
//
//  Created by Justin Weiss on 6/5/10.
//  Copyright 2010 Avvo. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface CurrentGamesController : UITableViewController {
	NSArray *games;
	IBOutlet UIBarButtonItem *refreshButton;
}

@property(nonatomic, retain) NSArray *games;
@property(nonatomic, retain) IBOutlet UIBarButtonItem *refreshButton;

- (IBAction)refreshGames;

@end
