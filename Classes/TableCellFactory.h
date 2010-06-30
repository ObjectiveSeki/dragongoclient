//
//  TableCellFactory.h
//  BACEstimator
//
//  Created by Justin Weiss on 7/18/08.
//  Copyright 2008 Avvo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TextCell.h"

@interface TableCellFactory : NSObject {
    IBOutlet TextCell *textCell;
}

- (TextCell *) newTextCell;

+ (TextCell *) textCell;

@end
