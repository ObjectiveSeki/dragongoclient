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
#import "DGS.h"
#import "SpinnerView.h"

enum BoardState {
	kBoardStateZoomedOut,
	kBoardStateZoomedIn,
};

@interface GameViewController : UIViewController <LoginProtocol> {
	Game *game;
	FuegoBoard *board;
	DGS *dgs;
	IBOutlet GoBoardView *boardView;
	IBOutlet UIScrollView *scrollView;
	IBOutlet UIBarButtonItem *undoButton;
	IBOutlet UIBarButtonItem *zoomOutButton;
	IBOutlet UIBarButtonItem *confirmButton;
	IBOutlet UIBarButtonItem *passButton;
	IBOutlet UIBarButtonItem *resignButton;
	IBOutlet UIBarButtonItem *messageButton;
	IBOutlet UIView *messageView;
	IBOutlet UITextView *messageTextView;
	IBOutlet UITextField *messageField;
	IBOutlet UIView *messageDisplayView;
	IBOutlet UIView *messageInputView;
	BoardState boardState;
	float maximumZoomScale;
	float minimumZoomScale;
	float currentZoomScale;
	SpinnerView *spinnerView;
}

@property (nonatomic, retain) SpinnerView *spinnerView;

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
@property(nonatomic, retain) IBOutlet UIView *messageView;
@property(nonatomic, retain) IBOutlet UITextView *messageTextView;
@property(nonatomic, retain) IBOutlet UITextField *messageField;
@property(nonatomic, retain) IBOutlet UIView *messageDisplayView;
@property(nonatomic, retain) IBOutlet UIView *messageInputView;
@property(nonatomic, retain) DGS *dgs;

- (IBAction)undoMove;
- (IBAction)zoomOut;
- (IBAction)confirmMove;
- (IBAction)pass;
- (IBAction)resign;
- (IBAction)showMessageWindow;
- (IBAction)hideMessageWindow;

- (void)notLoggedIn;
- (void)loggedIn;
- (void)requestCancelled;

@end

