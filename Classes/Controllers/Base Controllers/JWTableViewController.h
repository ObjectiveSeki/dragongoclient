//
//  Handles managing a table view using TableSection and TableRow objects.
//

#import <UIKit/UIKit.h>
#import "RootViewController.h"
#import "TableSection.h"
#import "TableRow.h"

@interface JWTableViewController : RootViewController <UITableViewDelegate, UITableViewDataSource> {
	NSArray *tableSections;
	IBOutlet UITableView *tableView;
	NSIndexPath *selectedIndexPath;
}

@property (nonatomic, retain) NSArray *tableSections;
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, copy) NSIndexPath *selectedIndexPath;

- (TableRow *)rowDataForIndexPath:(NSIndexPath *)indexPath;
- (void)deselectSelectedCell;

@end
