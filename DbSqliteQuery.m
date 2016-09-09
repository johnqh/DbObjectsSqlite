//
//  DbSqliteQuery.m
//  DbBridge
//
//  Created by John Huang on 3/18/14.
//  Copyright (c) 2014 John Huang. All rights reserved.
//

#import "DbSqliteQuery.h"
#import <sqlite3.h>

#import "DbObject.h"
#import "DbCollection.h"
#import "DbCollection+Private.h"
#import "DbSqliteDatabase.h"
#import "DbTable.h"
#import "DbField.h"
#import "DbSortDescriptor.h"
#import "DbObjectUtils.h"

#import "DebugHelp.h"

@implementation DbSqliteQuery

- (bool)connectDatabase:(DbDatabase *)db
{
    DbSqliteDatabase * sqliteDb = (DbSqliteDatabase *)db;
    sqlite3 * sqlite = nil;
    sqlite3_open_v2([sqliteDb.path UTF8String], &sqlite, SQLITE_OPEN_FULLMUTEX | SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, NULL);
    //int error = sqlite3_open([_path UTF8String], &db);
    sqlite3_exec(sqlite, "PRAGMA synchronous = NORMAL", NULL, NULL, NULL);
    sqlite3_exec(sqlite, "PRAGMA journal_mode = OFF;", NULL, NULL, NULL);
    sqlite3_exec(sqlite, "PRAGMA cache_size = 16384;", NULL, NULL, NULL);
    sqliteDb.db = sqlite;
    
    int error = sqlite3_errcode(sqlite);
    return (error == SQLITE_OK);
}

- (void)disconnectDatabase:(DbDatabase *)db
{
    DbSqliteDatabase * sqliteDb = (DbSqliteDatabase *)db;
    if (sqliteDb.db)
    {
        sqlite3_close(sqliteDb.db);
        sqliteDb.db = nil;
    }
}


- (id)loadObject:(DbObject *)object
{
    NSString * sql = [self loadStatement:object];
	if (sql)
    {
        DebugHelperLog(@"db", sql);
        
		sqlite3_stmt * compiledStatement = nil;
		
		DbSqliteDatabase * database = (DbSqliteDatabase *)object.db;
		if(sqlite3_prepare_v2(database.db, [sql UTF8String], -1, &compiledStatement, NULL) == SQLITE_OK)
		{
			NSMutableArray * fields = [[NSMutableArray alloc] init];
			int count = sqlite3_column_count(compiledStatement);
			for (int i = 0; i < count; i ++)
			{
				NSString * name = [NSString stringWithUTF8String:sqlite3_column_name(compiledStatement, i)];
				[fields addObject:name];
			}
            int result = sqlite3_step(compiledStatement);
			if (result == SQLITE_ROW)
            {
                NSMutableDictionary * data = [NSMutableDictionary dictionary];
                
                for (int i = 0; i < count; i ++)
                {
                    char * rawValue = (char *)sqlite3_column_text(compiledStatement, i);
                    if (rawValue)
                    {
                        NSString * value = [NSString stringWithUTF8String:rawValue];
                        NSString * field = [fields objectAtIndex:i];
                        data[field] = value;
                    }
                }
                NSString * keyField = object.keyField;
                NSString * keyValue = data[keyField];
                
                object = [object cachedOrMe:keyValue];
                for (NSString * field in data)
                {
                    NSString * value = data[field];
                    [object setPrivate:field data:value];
                }
                object.saved = true;
			}
		}
		int errorCode = sqlite3_finalize(compiledStatement);
        for (int i = 0; i < 3 && errorCode == SQLITE_BUSY; i ++)
        {
            errorCode = sqlite3_finalize(compiledStatement);
        }
	}
    return object;
}

- (id)loadCollection:(DbCollection *)collection
{
	NSString * sql = [self loadStatementForCollection:collection];
	if (sql && [collection verifyTable])
    {
        DebugHelperLog(@"db", sql);
        
		sqlite3_stmt * compiledStatement = nil;
		
		DbSqliteDatabase * database = (DbSqliteDatabase *)collection.db;
//        DbTable * table = collection.table;
		if(sqlite3_prepare_v2(database.db, [sql UTF8String], -1, &compiledStatement, NULL) == SQLITE_OK)
		{
			NSMutableArray * fields = [[NSMutableArray alloc] init];
			int count = sqlite3_column_count(compiledStatement);
			for (int i = 0; i < count; i ++)
			{
				NSString * name = [NSString stringWithUTF8String:sqlite3_column_name(compiledStatement, i)];
				[fields addObject:name];
			}
            int result = sqlite3_step(compiledStatement);
			while (result == SQLITE_ROW)
            {
                NSMutableDictionary * data = [NSMutableDictionary dictionary];
                
                for (int i = 0; i < count; i ++)
                {
                    char * rawValue = (char *)sqlite3_column_text(compiledStatement, i);
                    if (rawValue)
                    {
                        NSString * value = [NSString stringWithUTF8String:rawValue];
                        NSString * field = [fields objectAtIndex:i];
                        data[field] = value;
                    }
                }
                
                NSString * keyField = collection.keyField;
                NSString * keyValue = data[keyField];
                
                DbObject * object = [collection createObjectWithKeyValue:keyValue];
				if (object)
				{
                    for (NSString * field in data)
                    {
                        NSString * value = data[field];
                        [object setPrivate:field data:value];
                    }
                    object.saved = true;
					[collection.entries addObject:object];
                }
                result = sqlite3_step(compiledStatement);
            }
            collection.saved = true;
		}
		int errorCode = sqlite3_finalize(compiledStatement);
        for (int i = 0; i < 3 && errorCode == SQLITE_BUSY; i ++)
        {
            errorCode = sqlite3_finalize(compiledStatement);
        }
	}
    return collection;
}

- (bool)saveObject:(DbObject *)object
{
    bool pass = false;
    NSString * sql = nil;
    if (object.saved)
    {
        sql = [self updateStatement:object];
    }
    else
    {
        sql = [self insertStatement:object];
    }
	if (sql)
	{
        DebugHelperLog(@"db", sql);
        
		sqlite3_stmt * compiledStatement = nil;
		
		DbSqliteDatabase * database = (DbSqliteDatabase *)object.db;
		if(sqlite3_prepare_v2(database.db, [sql UTF8String], -1, &compiledStatement, NULL) == SQLITE_OK)
		{
            @synchronized(database)
            {
                int result = sqlite3_step(compiledStatement);
                if (result == SQLITE_DONE)
                {
                    if (!object.saved)
                    {
                        DbField * keyField = object.table.autoIncrementField;
                        if (keyField)
                        {
                            sqlite3_int64 entryId = sqlite3_last_insert_rowid(database.db);
                            [object setPrivate:keyField.sqlFieldName data:[NSString stringWithFormat:@"%lld", entryId]];
                        }
                    }
                    object.saved = true;
                    pass = true;
                }
            }
		}
		int errorCode = sqlite3_finalize(compiledStatement);
        for (int i = 0; i < 3 && errorCode == SQLITE_BUSY; i ++)
        {
            errorCode = sqlite3_finalize(compiledStatement);
        }
	}
    return pass;
}

- (bool)removeObject:(DbObject *)object
{
    bool pass = false;
    NSString * sql = [self removeStatement:object];
    if (sql)
    {
        //        NSLog(@"Sqlite:%@", sql);
        
        sqlite3_stmt * compiledStatement = nil;
        
        DbSqliteDatabase * database = (DbSqliteDatabase *)object.db;
        if(sqlite3_prepare_v2(database.db, [sql UTF8String], -1, &compiledStatement, NULL) == SQLITE_OK)
        {
            @synchronized(database)
            {
                if (sqlite3_step(compiledStatement) == SQLITE_DONE)
                {
                    object.saved = false;
                    pass = true;
                }
            }
        }
        int errorCode = sqlite3_finalize(compiledStatement);
        for (int i = 0; i < 3 && errorCode == SQLITE_BUSY; i ++)
        {
            errorCode = sqlite3_finalize(compiledStatement);
        }
    }
    return pass;

}

- (int)count:(DbCollection *)collection
{
	int itemCount = 0;
	NSString * sql = [self countStatement:collection];
	if (sql)
	{
        //        NSLog(@"Sqlite:%@", sql);
        
		sqlite3_stmt * compiledStatement = nil;
		
		DbSqliteDatabase * database = (DbSqliteDatabase *)collection.db;
		if(sqlite3_prepare_v2(database.db, [sql UTF8String], -1, &compiledStatement, NULL) == SQLITE_OK)
		{
			if (sqlite3_step(compiledStatement) == SQLITE_ROW)
			{
				char * rawValue = (char *)sqlite3_column_text(compiledStatement, 0);
				if (rawValue)
				{
					NSString * value = [NSString stringWithUTF8String:rawValue];
					itemCount = [value intValue];
				}
			}
		}
		int errorCode = sqlite3_finalize(compiledStatement);
        for (int i = 0; i < 3 && errorCode == SQLITE_BUSY; i ++)
        {
            errorCode = sqlite3_finalize(compiledStatement);
        }
	}
	return itemCount;
}


- (NSString *)sqlEncode:(NSString *)text
{
    if (text)
    {
        return [text stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
    }
    return @"NULL";
}



@end
