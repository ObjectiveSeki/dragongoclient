    //
//  GameViewController.mm
//  DGSPhone
//
//  Created by Justin Weiss on 6/5/10.
//  Copyright 2010 Justin Weiss. All rights reserved.
//

#import "GameViewController.h"
#import "LoginViewController.h"
#import "FuegoBoard.h"

@implementation GameViewController

@synthesize spinnerView;

@synthesize game;
@synthesize board;
@synthesize boardView;
@synthesize scrollView;
@synthesize boardState;
@synthesize undoButton;
@synthesize zoomOutButton;
@synthesize confirmButton;
@synthesize passButton;
@synthesize resignButton;
@synthesize messageButton;
@synthesize messageView;
@synthesize messageTextView;
@synthesize messageField;
@synthesize messageDisplayView;
@synthesize	dgs;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

// Is this board too small to justify zooming?
- (BOOL)smallBoard {
	return [self.board size] < 13;
}

- (float)zoomInScale {
	return (float)[self.board size] / 19.0;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	UIScrollView *tempScrollView=(UIScrollView *)self.scrollView;
    tempScrollView.contentSize=CGSizeMake(self.boardView.bounds.size.height, self.boardView.bounds.size.width);
	currentZoomScale = 1.0;
	self.dgs = [[[DGS alloc] init] autorelease];
	self.navigationItem.title = [NSString stringWithFormat:@"vs. %@", [game opponent]];
	dgs.delegate = self;
}

- (void)updateBoard {
	if ([self.board canUndo]) {
		[self.navigationItem setRightBarButtonItem:[self undoButton] animated:YES];
	} else {
		[self.navigationItem setRightBarButtonItem:nil animated:YES];
	}
	[[self confirmButton] setEnabled:[self.board canSubmit]];
	[[self passButton] setEnabled:[self.board canPassOrResign]];
	[[self resignButton] setEnabled:[self.board canPassOrResign]];
	[[self boardView] setNeedsDisplay]; // show just placed move
}

// Sets the 'message waiting' toolbar indicator based on the value of hasMessage.
- (void)setMessageIconState:(BOOL)hasMessage {
	if (hasMessage) {
		self.messageButton.image = [UIImage imageNamed:@"Message on.png"];
	} else {
		self.messageButton.image = [UIImage imageNamed:@"Message off.png"];
	}
}

- (IBAction)undoMove {
	[self.board undoLastMove];
	[self updateBoard];
}

- (CGRect)zoomRectForScrollView:(UIScrollView *)theScrollView withScale:(float)scale withCenter:(CGPoint)center {
	
    CGRect zoomRect;
	
    // The zoom rect is in the content view's coordinates.
    // At a zoom scale of 1.0, it would be the size of the
    // imageScrollView's bounds.
    // As the zoom scale decreases, so more content is visible,
    // the size of the rect grows.
    zoomRect.size.height = theScrollView.frame.size.height / scale;
    zoomRect.size.width  = theScrollView.frame.size.width  / scale;
	
    // choose an origin so as to get the right center.
    zoomRect.origin.x = center.x - (zoomRect.size.width  / 2.0);
    zoomRect.origin.y = center.y - (zoomRect.size.height / 2.0);
	
    return zoomRect;
}

-(void)lockZoom
{
    maximumZoomScale = self.scrollView.maximumZoomScale;
    minimumZoomScale = self.scrollView.minimumZoomScale;
	
    self.scrollView.maximumZoomScale = currentZoomScale;
    self.scrollView.minimumZoomScale = currentZoomScale;
}

-(void)unlockZoom
{
    self.scrollView.maximumZoomScale = maximumZoomScale;
    self.scrollView.minimumZoomScale = minimumZoomScale;
}

- (void)zoomToScale:(float)scale center:(CGPoint)center animated:(bool)animated {
	[self unlockZoom];
	currentZoomScale = scale;
	//NSLog(@"%f", scale);
	CGRect zoomRect = [self zoomRectForScrollView:[self scrollView] withScale:scale withCenter:center];
	[[self scrollView] zoomToRect:zoomRect animated:animated];
	[self lockZoom];
}

- (void)zoomOut:(CGPoint)center {
	self.boardState = kBoardStateZoomedOut;
	if (currentZoomScale != 0.5) {
		[self zoomToScale:0.5 center:center animated:YES];
	}
	[self updateBoard];
}

- (IBAction)zoomOut {
	[self zoomOut:[self.boardView center]];
}

- (IBAction)confirmMove {
	self.spinnerView = [SpinnerView showInView:self.view];
	self.spinnerView.label.text = @"Submitting...";
	self.confirmButton.enabled = NO;
	if ([self.board beginningOfHandicapGame]) {
		[self.dgs playHandicapStones:[self.board handicapStones] comment:self.messageField.text gameId:self.game.gameId];
	} else if ([self.board gameEnded]) {
		[self.dgs markDeadStones:[self.board changedStones] moveNumber:[self.board moveNumber] comment:self.messageField.text gameId:self.game.gameId];
	} else {
		[self.dgs playMove:[self.board currentMove] lastMove:[self.board lastMove] moveNumber:[self.board moveNumber] comment:self.messageField.text gameId:self.game.gameId];
	}
}

- (void)playedMove {
	[self.spinnerView dismiss:YES];
	self.spinnerView = nil;
	[[self navigationController] popViewControllerAnimated:YES];
}

- (IBAction)pass {
	[self.board pass];
	[self updateBoard];
}

- (IBAction)resign {
	[self.board resign];
	[self updateBoard];
}

- (IBAction)showMessageWindow {
	[self.navigationController.view addSubview:self.messageView];
	[self.messageField becomeFirstResponder];
	[UIView animateWithDuration:0.3 animations:^() {
		self.messageView.alpha = 1.0;
	}];
}

- (IBAction)hideMessageWindow {
	[self.messageField resignFirstResponder];
	[self setMessageIconState:([self.board comment] || self.messageField.text.length > 0)];
	
	[UIView animateWithDuration:0.3 animations:^() {
		self.messageView.alpha = 0.0;
	} completion:^(BOOL completion) {
		[self.messageView removeFromSuperview];
	}];
}

- (void)notLoggedIn {
	LoginViewController *loginViewController = [[LoginViewController alloc] initWithNibName:@"LoginView" bundle:nil];
	loginViewController.delegate = self;
	[self presentModalViewController:loginViewController animated:YES];
	[loginViewController notLoggedIn];
	[loginViewController release];
}

- (void)loggedIn {
	[self dismissModalViewControllerAnimated:YES];
	[[self navigationController] popViewControllerAnimated:YES];
}

- (void)requestCancelled {
	[self.spinnerView dismiss:NO];
	self.spinnerView = nil;
	self.confirmButton.enabled = YES;
}

- (void)handleGoBoardTouch:(UITouch *)touch inView:(GoBoardView *)view {
	
	BOOL canZoomIn = [self.board canPlayMove] || [self.board gameEnded];
	
	if (![self smallBoard] && [self boardState] == kBoardStateZoomedOut && canZoomIn) {
		[self zoomToScale:[self zoomInScale] center:[touch locationInView:view] animated:YES];
		[self setBoardState:kBoardStateZoomedIn];
		[[self passButton] setEnabled:NO];
		[[self resignButton] setEnabled:NO];
		[self.navigationItem setRightBarButtonItem:self.zoomOutButton animated:YES];
	} else if ([self smallBoard] || [self boardState] == kBoardStateZoomedIn) {
		BOOL markedDeadStones = [self.board gameEnded] && [view markDeadStonesAtPoint:[touch locationInView:view]];
		
		BOOL playedStone = !markedDeadStones && [view playStoneAtPoint:[touch locationInView:view]];
		if (markedDeadStones || playedStone) {
			[self zoomOut:[touch locationInView:view]];
		}
	}
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.boardView;
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self setBoardState:kBoardStateZoomedOut];
	FuegoBoard *theBoard = [[FuegoBoard alloc] initWithSGFString:[game sgfString]];
	[[self boardView] setBoard:theBoard];
	[self setBoard:theBoard];
	
	if ([theBoard comment]) {
		[self setMessageIconState:YES];
		self.messageTextView.text = [theBoard comment];
	} else {
		self.messageDisplayView.hidden = YES;
	}

	[theBoard release];
	currentZoomScale = [self zoomInScale];
	[self lockZoom];
	[self zoomToScale:0.5 center:[[self boardView] center] animated:NO];
	[self updateBoard];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self.boardView setBoard:nil];
	self.board = nil;
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
	self.boardView = nil;
	self.game = nil;
	self.undoButton = nil;
	self.zoomOutButton = nil;
	self.confirmButton = nil;
	self.passButton = nil;
	self.resignButton = nil;
	self.messageButton = nil;
	self.messageView = nil;
	self.messageTextView = nil;
	self.messageField = nil;
	self.messageDisplayView = nil;
	self.dgs = nil;
	self.spinnerView = nil;
    [super viewDidUnload];
}


- (void)dealloc {

    [super dealloc];
}


@end

