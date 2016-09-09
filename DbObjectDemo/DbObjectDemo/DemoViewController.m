//
//  DemoViewController.m
//  DbObjectDemo
//
//  Created by Qiang Huang on 9/8/16.
//  Copyright © 2016 John Huang. All rights reserved.
//

#import "DemoViewController.h"

#import "DbDatabases.h"
#import "DbSomething.h"

@implementation DemoViewController

- (IBAction)add:(id)sender
{
    DbSomething * something = [[DbSomething alloc] initWithDb:[DbDatabases singleton]];
    something.name = [NSUUID UUID].UUIDString;
    something.name2 = [NSUUID UUID].UUIDString;
    something.selected = @false;
    something.update_time = [NSDate date];
    [something saveToDb];
}

@end
