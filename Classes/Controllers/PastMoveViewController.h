//
//  PastMoveViewController.h
//  DGSPhone
//
//  Created by Frank Prößdorf on 9/4/12.
//  Copyright (c) 2012 Justin Weiss. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Game.h"
#import "Move.h"
#import "GoBoardView.h"
#import "MessageView.h"
#import "RootViewController.h"
#import "PastMovesViewController.h"
#import "GameStatusProtocol.h"

@interface PastMoveViewController : RootViewController <LoginProtocol> {
	Game *game;
    int moveNumber;
	FuegoBoard *board;
	IBOutlet GoBoardView *boardView;
	IBOutlet UIScrollView *scrollView;
	IBOutlet UIBarButtonItem *undoButton;
	IBOutlet UIBarButtonItem *zoomOutButton;
    IBOutlet UIBarButtonItem *historyButton;
	IBOutlet UIBarButtonItem *confirmButton;
	IBOutlet UIBarButtonItem *passButton;
	IBOutlet UIBarButtonItem *resignButton;
	IBOutlet UIBarButtonItem *messageButton;
	IBOutlet MessageView *messageView;
	float maximumZoomScale;
	float minimumZoomScale;
	float currentZoomScale;
}

@property(nonatomic, retain) Game *game;
@property(nonatomic, assign) int moveNumber;
@property(nonatomic, retain) FuegoBoard *board;
@property(nonatomic, retain) IBOutlet GoBoardView *boardView;
@property(nonatomic, retain) IBOutlet UIScrollView *scrollView;
@property(nonatomic, retain) IBOutlet UIBarButtonItem *undoButton;
@property(nonatomic, retain) IBOutlet UIBarButtonItem *zoomOutButton;
@property(nonatomic, retain) IBOutlet UIBarButtonItem *historyButton;
@property(nonatomic, retain) IBOutlet UIBarButtonItem *confirmButton;
@property(nonatomic, retain) IBOutlet UIBarButtonItem *passButton;
@property(nonatomic, retain) IBOutlet UIBarButtonItem *resignButton;
@property(nonatomic, retain) IBOutlet UIBarButtonItem *messageButton;
@property(nonatomic, retain) IBOutlet MessageView *messageView;
@property(nonatomic, assign) id <GameStatusProtocol> delegate;

- (IBAction)undoMove;
- (IBAction)zoomOut;
- (IBAction)showHistory;
- (IBAction)confirmMove;
- (IBAction)pass;
- (IBAction)resign;
- (IBAction)showMessageWindow;

@end

