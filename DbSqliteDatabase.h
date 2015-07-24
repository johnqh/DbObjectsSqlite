//
//  DbSqlite.h
//  DbBridge
//
//  Created by John Huang on 3/18/14.
//  Copyright (c) 2014 John Huang. All rights reserved.
//

#import "DbFileDatabase.h"
#import <sqlite3.h>

@interface DbSqliteDatabase : DbFileDatabase

@property (nonatomic, assign) sqlite3 * db;

+ (DbSqliteDatabase *)databaseWithPath:(NSString *)path schemaFile:(NSString *)schemaFile;

+ (void)shutdown;

@end
