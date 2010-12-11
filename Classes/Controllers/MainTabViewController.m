//
//  MainTabViewController.m
//  DGSPhone
//
//  Created by Justin Weiss on 12/9/10.
//

#import "MainTabViewController.h"
#import "CurrentGamesController.h"

@implementation MainTabViewController

@synthesize currentGamesController;
@synthesize selectedViewController;
@synthesize tabBar;
@synthesize currentGamesTab;
@synthesize otherGamesTab;

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	self.currentGamesController = [[CurrentGamesController alloc] initWithNibName:@"CurrentGamesView" bundle:nil];
	self.currentGamesController.tabViewController = self;
	self.tabBar.selectedItem = self.currentGamesTab;
	[self setViewController:self.currentGamesController callbacks:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	[self.selectedViewController viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
	[self.selectedViewController viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[self.selectedViewController viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.selectedViewController viewDidDisappear:animated];
}


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
	self.currentGamesController = nil;
	self.selectedViewController = nil;
	self.tabBar = nil;
	self.otherGamesTab = nil;
	self.currentGamesTab = nil;
}

- (void)setViewController:(UIViewController *)viewController callbacks:(BOOL)callbacks {
	
	
	if (callbacks) {
		[self.selectedViewController viewWillDisappear:true];	
	}
	[self.selectedViewController.view removeFromSuperview];
	if (callbacks) {
		[self.selectedViewController viewDidDisappear:true];	
	}
	
	self.selectedViewController = viewController;
	
	if (callbacks) {
		[self.selectedViewController viewWillAppear:true];	
	}
	[self.view addSubview:self.selectedViewController.view];
	self.title = self.selectedViewController.title;
	self.navigationItem.leftBarButtonItem = self.selectedViewController.navigationItem.leftBarButtonItem;
	self.navigationItem.rightBarButtonItem = self.selectedViewController.navigationItem.rightBarButtonItem;	
	if (callbacks) {
		[self.selectedViewController viewDidAppear:true];		
	}
}

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item {

	if (item == self.currentGamesTab) {
		[self setViewController:self.currentGamesController callbacks:YES];
	} else {
		[self setViewController:nil callbacks:YES];
	}
}

- (void)dealloc {
    [super dealloc];
}


@end
