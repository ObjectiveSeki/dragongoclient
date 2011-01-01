//
// Holds information necessary for the sub-controllers of the main 
// tabviewcontroller.
//

#import <UIKit/UIKit.h>


@interface RootViewController : UIViewController {
	UIViewController *tabViewController;
}

@property(nonatomic, assign) UIViewController *tabViewController;

@end
