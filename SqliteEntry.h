//
//  SqliteEntry.h
//  DbBridge
//
//  Created by John Huang on 3/18/14.
//  Copyright (c) 2014 John Huang. All rights reserved.
//

#import "DbObject.h"

@interface SqliteEntry : DbObject

@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * sql;

@end
