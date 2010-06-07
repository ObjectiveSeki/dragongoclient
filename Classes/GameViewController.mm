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
@synthesize boardView;
@synthesize scrollView;

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

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.boardView;
}

- (void)scrollViewDidEndZooming:(UIScrollView *)theScrollView withView:(UIView *)view atScale:(float)scale {
	
	float zoomScale=theScrollView.zoomScale;
	CGSize newContentSize=theScrollView.contentSize;
	CGPoint newContentOffset=theScrollView.contentOffset;
	CGSize oldContentViewSize=[boardView frame].size;
	
	float xMult=newContentSize.width/oldContentViewSize.width;
	float yMult=newContentSize.height/oldContentViewSize.height;
	
	newContentOffset.x *=xMult;
	newContentOffset.y *=yMult;
	
	float currentMinZoom=theScrollView.minimumZoomScale;
	float currentMaxZoom=theScrollView.maximumZoomScale;
	
	float newMinZoom=currentMinZoom/zoomScale;
	float newMaxZoom=currentMaxZoom/zoomScale;
	
	[theScrollView setMinimumZoomScale:1.0];
	[theScrollView setMaximumZoomScale:1.0];
	[theScrollView setZoomScale:1.0 animated:NO];
	
	[boardView setFrame:CGRectMake(0,0,newContentSize.width,newContentSize.height)];
	theScrollView.contentSize=newContentSize;
	[theScrollView setContentOffset:newContentOffset animated:NO];
	
	[theScrollView setMinimumZoomScale:newMinZoom];
	[theScrollView setMaximumZoomScale:newMaxZoom];
	
	[boardView setNeedsDisplay];
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
	Board *board = [[Board alloc] initWithSGFString:[game sgfString] boardSize:19];
	[[self boardView] setBoard:board];
	[board release];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
	self.boardView = nil;
	self.game = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end
