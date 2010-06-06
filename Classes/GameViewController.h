//
//  GameViewController.h
//  DGSPhone
//
//  Created by Justin Weiss on 6/5/10.
//  Copyright 2010 Avvo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Game.h"
#import "GoBoardView.h"

@interface GameViewController : UIViewController {
	Game *game;
	IBOutlet GoBoardView *boardView;
}

@property(nonatomic, retain) Game *game;
@property(nonatomic, retain) IBOutlet GoBoardView *boardView;

@end
