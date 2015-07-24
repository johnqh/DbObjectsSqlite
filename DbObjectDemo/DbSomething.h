//
//  DbSomething.h
//  DbObjectDemo
//
//  Created by Qiang Huang on 6/2/15.
//  Copyright (c) 2015 John Huang. All rights reserved.
//

#import "DbObject.h"

@interface DbSomething : DbObject

@property (nonatomic, strong) NSNumber * Id;
@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) NSString * name2;
@property (nonatomic, strong) NSNumber * selected;
@property (nonatomic, strong) NSDate * update_time;

@end
