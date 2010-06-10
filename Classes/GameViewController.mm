    //
//  GameViewController.mm
//  DGSPhone
//
//  Created by Justin Weiss on 6/5/10.
//  Copyright 2010 Avvo. All rights reserved.
//

#import "GameViewController.h"
#import "Board.h"

@implementation GameViewController

@synthesize game;
@synthesize board;
@synthesize boardView;
@synthesize scrollView;
@synthesize boardState;
@synthesize undoButton;
@synthesize confirmButton;


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
}

- (IBAction)undoMove {
	[board undoLastMove];
	[self setBoardState:kBoardStateStoneNotPlaced];
	[[self navigationItem] setRightBarButtonItem:nil animated:YES];
	[[self confirmButton] setEnabled:NO];
	[[self boardView] setNeedsDisplay];
}

- (IBAction)confirmMove {
	[[self game] playMove:[[self board] currentMove] lastMove:[[self board] lastMove] comment:nil];
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

- (void)handleGoBoardTouch:(UITouch *)touch inView:(GoBoardView *)view {
	
	if ([self boardState] == kBoardStateStoneNotPlaced) {
		CGRect zoomRect = [self zoomRectForScrollView:[self scrollView] withScale:2.0 withCenter:[touch locationInView:view]];
		[[self scrollView] zoomToRect:zoomRect animated:YES];
		[self setBoardState:kBoardStateZoomedIn];
	} else if ([self boardState] == kBoardStateZoomedIn) {
		if ([view playStoneAtPoint:[touch locationInView:view]]) {
			[[self navigationItem] setRightBarButtonItem:[self undoButton] animated:YES];
			[[self confirmButton] setEnabled:YES];
			[view setNeedsDisplay];
			CGRect zoomRect = [self zoomRectForScrollView:[self scrollView] withScale:0.5 withCenter:[touch locationInView:view]];
			[[self scrollView] zoomToRect:zoomRect animated:YES];
			[self setBoardState:kBoardStateStonePlaced];
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
	CGRect zoomRect = [self zoomRectForScrollView:[self scrollView] withScale:0.5 withCenter:[[self boardView] center]];
	[[self scrollView] zoomToRect:zoomRect animated:NO];
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
}


- (void)dealloc {
    [super dealloc];
}


@end
