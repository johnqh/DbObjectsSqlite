//
//  DbSqliteUtils.m
//  DbObjectsSqlite
//
//  Created by Qiang Huang on 3/8/15.
//  Copyright (c) 2015 Qiang Huang. All rights reserved.
//

#import "DbSqliteUtils.h"
#import "DbSqliteDatabase.h"

#import "DbDirectoryUtils.h"
#import "DbFileUtils.h"

@implementation DbSqliteUtils

+ (DbDatabase *)setupFile:(NSString *)dbFileName schema:(NSString *)schemaFileName copyFromBundle:(bool)copyFromBundle
{
    return [self setupFile:dbFileName schema:schemaFileName copyFromBundle:copyFromBundle forced:false];
}

+ (DbDatabase *)setupFile:(NSString *)dbFileName schema:(NSString *)schemaFileName copyFromBundle:(bool)copyFromBundle forced:(bool)forced;
{
    NSString * bundlePath = [DbDirectoryUtils getBundleFolder];
    NSString * schemaFile = [bundlePath stringByAppendingPathComponent:schemaFileName];
    NSString * docPath = [DbDirectoryUtils getDocumentFolder];
    NSString * dbFile = [docPath stringByAppendingPathComponent:dbFileName];
    
    if (copyFromBundle)
    {
        NSString * bundledDbFile = [bundlePath stringByAppendingPathComponent:dbFileName];
        [DbFileUtils copyFile:dbFile from:bundledDbFile forced:forced];
    }
    return [DbSqliteDatabase databaseWithPath:dbFile schemaFile:schemaFile];
}

@end
