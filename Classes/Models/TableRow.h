// 
// Holds information about a particular row in a table view.
//

#import <Foundation/Foundation.h>


@interface TableRow : NSObject {
	Class cellClass;
	UITableViewCell *(^cellInit)();
	void (^cellSetup)(UITableViewCell *cell);
	void (^cellTouched)(UITableViewCell *cell);
	NSString *identifier;
	BOOL selectable;
}

@property (nonatomic, assign) Class cellClass;
@property (nonatomic, copy) UITableViewCell *(^cellInit)();
@property (nonatomic, copy) void (^cellSetup)(UITableViewCell *cell);
@property (nonatomic, copy) void (^cellTouched)(UITableViewCell *cell);
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, assign) BOOL selectable;


@end
