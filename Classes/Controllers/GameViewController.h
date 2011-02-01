//
//  GameViewController.h
//  DGSPhone
//
//  Created by Justin Weiss on 6/5/10.
//  Copyright 2010 Justin Weiss. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Game.h"
#import "GoBoardView.h"
#import "MessageView.h"
#import "RootViewController.h"

enum BoardState {
	kBoardStateZoomedOut,
	kBoardStateZoomedIn,
};

@interface GameViewController : RootViewController <LoginProtocol> {
	Game *game;
	FuegoBoard *board;
	IBOutlet GoBoardView *boardView;
	IBOutlet UIScrollView *scrollView;
	IBOutlet UIBarButtonItem *undoButton;
	IBOutlet UIBarButtonItem *zoomOutButton;
	IBOutlet UIBarButtonItem *confirmButton;
	IBOutlet UIBarButtonItem *passButton;
	IBOutlet UIBarButtonItem *resignButton;
	IBOutlet UIBarButtonItem *messageButton;
	IBOutlet MessageView *messageView;
	BoardState boardState;
	float maximumZoomScale;
	float minimumZoomScale;
	float currentZoomScale;
}

@property(nonatomic, retain) Game *game;
@property(nonatomic, retain) FuegoBoard *board;
@property(nonatomic, retain) IBOutlet GoBoardView *boardView;
@property(nonatomic, retain) IBOutlet UIScrollView *scrollView;
@property(nonatomic) BoardState boardState;
@property(nonatomic, retain) IBOutlet UIBarButtonItem *undoButton;
@property(nonatomic, retain) IBOutlet UIBarButtonItem *zoomOutButton;
@property(nonatomic, retain) IBOutlet UIBarButtonItem *confirmButton;
@property(nonatomic, retain) IBOutlet UIBarButtonItem *passButton;
@property(nonatomic, retain) IBOutlet UIBarButtonItem *resignButton;
@property(nonatomic, retain) IBOutlet UIBarButtonItem *messageButton;
@property(nonatomic, retain) IBOutlet MessageView *messageView;

- (IBAction)undoMove;
- (IBAction)zoomOut;
- (IBAction)confirmMove;
- (IBAction)pass;
- (IBAction)resign;
- (IBAction)showMessageWindow;

- (void)notLoggedIn;
- (void)loggedIn;
- (void)requestCancelled;

@end

