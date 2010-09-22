//
//  TableCellFactory.h
//  BACEstimator
//
//  Created by Justin Weiss on 7/18/08.
//  Copyright 2008 Justin Weiss. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TextCell.h"
#import "SelectCell.h"

@interface TableCellFactory : NSObject {
    IBOutlet TextCell *textCell;
	IBOutlet SelectCell *selectCell;
}

- (TextCell *) textCell;
+ (TextCell *) textCell;
- (SelectCell *) selectCell;
+ (SelectCell *) selectCell;
@end
