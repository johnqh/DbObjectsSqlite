//
//  DbSqliteUtils.h
//  DbObjectsSqlite
//
//  Created by Qiang Huang on 3/8/15.
//  Copyright (c) 2015 Qiang Huang. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DbDatabase;

@interface DbSqliteUtils : NSObject

+ (DbDatabase *)setupFile:(NSString *)dbFileName schema:(NSString *)schemaFileName copyFromBundle:(bool)copyFromBundle;
+ (DbDatabase *)setupFile:(NSString *)dbFileName schema:(NSString *)schemaFileName copyFromBundle:(bool)copyFromBundle forced:(bool)forced;

@end
