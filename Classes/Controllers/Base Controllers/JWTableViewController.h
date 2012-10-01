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
}

@property (nonatomic, strong) NSArray *tableSections;
@property (nonatomic, strong) IBOutlet UITableView *tableView;

- (TableRow *)rowDataForIndexPath:(NSIndexPath *)indexPath;
- (void)deselectSelectedCell;

@end
