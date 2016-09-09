//
//  SomethingCell.h
//  DbObjectDemo
//
//  Created by Qiang Huang on 6/2/15.
//  Copyright (c) 2015 John Huang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "InteractiveObjectPresenter.h"

@class DbSomething;

@interface SomethingCell : UITableViewCell<InteractiveObjectPresenter>

@property (nonatomic, strong) IBOutlet UILabel * textLabel;
@property (nonatomic, strong) IBOutlet UILabel * detailTextLabel;

@end
