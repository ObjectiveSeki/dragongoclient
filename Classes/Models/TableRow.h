// 
// Holds information about a particular row in a table view.
//

#import <Foundation/Foundation.h>


@interface TableRow : NSObject {
	Class cellClass;
	void (^cellSetup)(UITableViewCell *cell);
}

@property (nonatomic, assign) Class cellClass;
@property (nonatomic, retain) void (^cellSetup)(UITableViewCell *cell);

@end
