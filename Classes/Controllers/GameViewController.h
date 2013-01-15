//
//  GameViewController.h
//  DGSPhone
//
//  Created by Justin Weiss on 6/5/10.
//  Copyright 2010 Justin Weiss. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GoBoardView, MessageView, Game, FuegoBoard;

typedef enum {
	kBoardStateZoomedOut,
	kBoardStateZoomedIn,
} BoardState;

@interface GameViewController : UIViewController <UIActionSheetDelegate>

@property(nonatomic, strong) Game *game;
@property(nonatomic) BOOL readOnly;

@property(nonatomic, strong) IBOutlet GoBoardView *boardView;
@property(nonatomic, strong) IBOutlet UIScrollView *scrollView;
@property(nonatomic, strong) IBOutlet UIBarButtonItem *undoButton;
@property(nonatomic, strong) IBOutlet UIBarButtonItem *zoomOutButton;
@property(nonatomic, strong) IBOutlet UIBarButtonItem *confirmButton;
@property(nonatomic, strong) IBOutlet UIBarButtonItem *passButton;
@property(nonatomic, strong) IBOutlet UIBarButtonItem *resignButton;
@property(nonatomic, strong) IBOutlet UIBarButtonItem *messageButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *nextMoveButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *previousMoveButton;
@property(nonatomic, strong) IBOutlet MessageView *messageView;
@property (strong, nonatomic) IBOutlet UIToolbar *toolbar;

- (IBAction)undoMove;
- (IBAction)zoomOut;
- (IBAction)confirmMove;
- (IBAction)pass;
- (IBAction)resign;
- (IBAction)showPassResignPanel:(id)sender;
- (IBAction)showMessageWindow;
- (IBAction)share:(id)sender;
- (IBAction)goToPreviousMove:(id)sender;
- (IBAction)goToNextMove:(id)sender;

@end

