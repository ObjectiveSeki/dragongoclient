    //
//  GameViewController.mm
//  DGSPhone
//
//  Created by Justin Weiss on 6/5/10.
//  Copyright 2010 Avvo. All rights reserved.
//

#import "GameViewController.h"
#import "LoginViewController.h"
#import "Board.h"

@implementation GameViewController

@synthesize game;
@synthesize board;
@synthesize boardView;
@synthesize scrollView;
@synthesize boardState;
@synthesize undoButton;
@synthesize confirmButton;
@synthesize passButton;
@synthesize resignButton;
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


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	UIScrollView *tempScrollView=(UIScrollView *)self.scrollView;
    tempScrollView.contentSize=CGSizeMake(self.boardView.bounds.size.height, self.boardView.bounds.size.width);
	currentZoomScale = 1.0;
	self.dgs = [[DGS alloc] init];
	dgs.delegate = self;
}

- (IBAction)undoMove {
	[board undoLastMove];
	[self setBoardState:kBoardStateStoneNotPlaced];
	[[self navigationItem] setRightBarButtonItem:nil animated:YES];
	[[self confirmButton] setEnabled:NO];
	[[self boardView] setNeedsDisplay];
	[[self passButton] setEnabled:YES];
	[[self resignButton] setEnabled:YES];
}


- (void)setMoveMade {
	[[self navigationItem] setRightBarButtonItem:[self undoButton] animated:YES];
	[[self confirmButton] setEnabled:YES];
	[[self passButton] setEnabled:NO];
	[[self resignButton] setEnabled:NO];
	[[self boardView] setNeedsDisplay]; // show just placed move
	[self setBoardState:kBoardStateStonePlaced];
}

- (IBAction)confirmMove {
	[[self dgs] playMove:[[self board] currentMove] lastMove:[[self board] lastMove] moveNumber:[[self board] moveNumber] comment:nil gameId:[game gameId]];
}

- (void)playedMove {

	[[self navigationController] popViewControllerAnimated:YES];
}

- (IBAction)pass {
	[board pass];
	[self setMoveMade];
}

- (IBAction)resign {
	[board resign];
	[self setMoveMade];
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
	CGRect zoomRect = [self zoomRectForScrollView:[self scrollView] withScale:scale withCenter:center];
	[[self scrollView] zoomToRect:zoomRect animated:animated];
	[self lockZoom];
}

- (void)handleGoBoardTouch:(UITouch *)touch inView:(GoBoardView *)view {
	
	if ([self boardState] == kBoardStateStoneNotPlaced) {
		[self zoomToScale:1.0 center:[touch locationInView:view] animated:YES];
		[self setBoardState:kBoardStateZoomedIn];
		[[self passButton] setEnabled:NO];
		[[self resignButton] setEnabled:NO];
	} else if ([self boardState] == kBoardStateZoomedIn) {
		if ([view playStoneAtPoint:[touch locationInView:view]]) {
			[self setMoveMade];
			[self zoomToScale:0.5 center:[touch locationInView:view] animated:YES];
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
	[self setBoardState:kBoardStateStoneNotPlaced];
	Board *theBoard = [[Board alloc] initWithSGFString:[game sgfString] boardSize:19];
	[[self boardView] setBoard:theBoard];
	[self setBoard:theBoard];
	[theBoard release];
	[self lockZoom];
	[self zoomToScale:0.5 center:[[self boardView] center] animated:NO];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
	self.boardView = nil;
	self.game = nil;
	self.board = nil;
	self.undoButton = nil;
	self.confirmButton = nil;
	self.passButton = nil;
	self.dgs = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end
