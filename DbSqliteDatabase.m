//
//  DbSqlite.m
//  DbBridge
//
//  Created by John Huang on 3/18/14.
//  Copyright (c) 2014 John Huang. All rights reserved.
//

#import "DbSqliteDatabase.h"
#import "DbTable.h"
#import "DbField.h"
#import "DbIndex.h"
#import "DbCollection.h"
#import "DbCollection+Private.h"
#import "DbSqliteQuery.h"
#import "DbAppObjectCache.h"
#import "SqliteEntry.h"
#import "DbFileUtils.h"
#import "DebugHelp.h"
#import "DbTextUtils.h"

static bool _initialized = false;
static Class _sqliteEntryClass = nil;

@implementation DbSqliteDatabase

+ (void)initializeSqlite
{
    if (!_initialized)
    {
        if (sqlite3_threadsafe() > 0)
        {
        //    sqlite3_config(SQLITE_CONFIG_MULTITHREAD);
            sqlite3_config(SQLITE_CONFIG_SERIALIZED);
        }
        int error = sqlite3_initialize();
        
        _initialized = (error == SQLITE_OK);
        _sqliteEntryClass = [SqliteEntry class];
    }
}

+ (void)shutdown
{
    if (_initialized)
    {
        _initialized = false;
        sqlite3_shutdown();
    }
}

+ (DbSqliteDatabase *)databaseWithPath:(NSString *)path schemaFile:(NSString *)schemaFile
{
    DbSqliteDatabase * db = [[DbSqliteDatabase alloc] initWithPath:path schemaFile:schemaFile];
    [db connect];
    return db;
}

- (DbQuery *)createQuery
{
    return [[DbSqliteQuery alloc] init];
}

- (DbAppObjectCache *)createCache
{
    return [[DbAppObjectCache alloc] init];
}

- (id)initWithPath:(NSString *)path
{
    [DbSqliteDatabase initializeSqlite];
    
    return [super initWithPath:path];
    
}

- (void)readExistingSchemas
{
    DbTable * table = [[DbTable alloc] initWithDb:self];
    table.name = @"sqlite_master";
    table.className = @"SqliteEntry";
    [table.fields setObject:[[DbField alloc] initWithName:@"name" type:kDbTypeString] forKey:@"name"];
    [table.fields setObject:[[DbField alloc] initWithName:@"type" type:kDbTypeString] forKey:@"type"];
    [table.fields setObject:[[DbField alloc] initWithName:@"sql" type:kDbTypeString] forKey:@"sql"];
    
    [self.tables setObject:table forKey:table.className];
    [table populateObjectMethods];
    
//    DbSqliteCollection * collection = [[DbSqliteCollection alloc] initWithDb:self entityType:table.className];
//    [collection loadFromDb];
    
}

- (void)syncTables
{
	DbCollection * entries = [[DbCollection alloc] initWithDb:self entityType:@"SqliteEntry"];
	[entries loadFromDb];
	
	NSMutableDictionary * sqliteSchema = [NSMutableDictionary dictionary];
	[self parseEntries:entries toSchema:sqliteSchema];
	
	NSArray * classNames = [self.tables allKeys];
	for (int i = 0; i < [classNames count]; i ++)
	{
		NSString * className = (NSString *)[classNames objectAtIndex:i];
		if (![className isEqualToString:@"SqliteEntry"])
		{
			DbTable * table = (DbTable *)[self.tables objectForKey:className];
			DbTable * existingTable = (DbTable *)[sqliteSchema objectForKey:table.name];
			if (existingTable)
			{
				[self updateTable:table existing:existingTable];
			}
			else
			{
				[self createTable:table];
			}
			[self updateIndexForTable:table existing:existingTable];
            
		}
	}
	
}

- (void)createSchemaFromTable
{
    DbCollection * entries = [[DbCollection alloc] initWithDb:self entityType:@"SqliteEntry"];
    [entries loadFromDb];
    
    NSMutableDictionary * sqliteTables = [NSMutableDictionary dictionary];
    [self parseEntries:entries toSchema:sqliteTables];
    
    self.tables = sqliteTables;
    
}

- (bool)createTable:(DbTable *)table
{
	bool pass = false;
	NSString * sql = [self createTableStatement:table];
    
    DebugHelperLog(@"db", sql);
    
	sqlite3_stmt * compiledStatement = nil;
	if(sqlite3_prepare_v2(self.db, [sql UTF8String], -1, &compiledStatement, NULL) == SQLITE_OK)
	{
		if (sqlite3_step(compiledStatement) == SQLITE_ROW)
		{
			pass = true;
		}
	}
	sqlite3_finalize(compiledStatement);
	return pass;
}

- (bool)updateTable:(DbTable *)table existing:(DbTable *)existingTable
{
	bool pass = true;
    for (NSString * fieldName in table.fields)
    {
		DbField * existingField = nil;
		if (existingTable.fields)
		{
			existingField = (DbField *)[existingTable.fields objectForKey:fieldName];
		}
		if (!existingField)
		{
			DbField * field = (DbField *)[table.fields objectForKey:fieldName];
			
			NSString * sql = [self addColumeStatement:table field:field];
            
            DebugHelperLog(@"db", sql);
			
			sqlite3_stmt * compiledStatement = nil;
			if(sqlite3_prepare_v2(self.db, [sql UTF8String], -1, &compiledStatement, NULL) == SQLITE_OK)
			{
				if (sqlite3_step(compiledStatement) != SQLITE_ROW)
				{
					pass = false;
				}
			}
			sqlite3_finalize(compiledStatement);
		}
	}
	
	return pass;
}

- (NSString *)createTableStatement:(DbTable *)table
{
	NSMutableString * builder = [[NSMutableString alloc] initWithCapacity:128];
	[builder appendString:@"CREATE TABLE "];
	[builder appendString:table.name];
	
    [builder appendString:@"("];
    bool first = true;
    for (NSString * fieldName in table.fields)
    {
		if (first)
		{
            first = false;
		}
		else
		{
			[builder appendString:@", "];
		}
        
		DbField * field = [table.fields objectForKey:fieldName];
		[builder appendString:[field createText]];
		
	}
    [builder appendString:@")"];
	return builder;
}

- (NSString *)addColumeStatement:(DbTable *)table field:(DbField *)field;
{
	NSMutableString * builder = [[NSMutableString alloc] initWithCapacity:128];
	[builder appendString:@"ALTER TABLE "];
	[builder appendString:table.name];
	[builder appendString:@" ADD COLUMN "];
	[builder appendString:[field createText]];
	return builder;
}

- (void)parseEntries:(DbCollection *)entries toSchema:(NSMutableDictionary *)sqliteSchema
{
	for (int i = 0; i < entries.entries.count; i ++)
	{
		SqliteEntry * entry = (SqliteEntry *)[entries.entries objectAtIndex:i];
		[self parseEntry:entry toSchema:sqliteSchema];
	}
}

- (void)parseEntry:(SqliteEntry *)entry toSchema:(NSMutableDictionary *)sqliteSchema
{
	if ([entry.type isEqualToString:@"table"])
	{
		[self parseTable:entry toSchema:sqliteSchema];
	}
	else if ([entry.type isEqualToString:@"index"])
	{
		[self parseIndex:entry toSchema:sqliteSchema];
	}
}

- (void)parseTable:(SqliteEntry *)entry toSchema:(NSMutableDictionary *)sqliteSchema
{
    if (![entry.name hasPrefix:@"sqlite"])
    {
        DbTable * table = [[DbTable alloc] initWithDb:self];
        table.name = entry.name;
        [sqliteSchema setObject:table forKey:entry.name];
        
        NSString * statement = entry.sql;
        
        [self parseText:statement toTable:table];
    }
}

- (void)parseText:(NSString *)text toTable:(DbTable *)table
{
	NSRange start = [text rangeOfString:@"("];
	NSRange end = [text rangeOfString:@")"];
	NSString * innerText = [text substringWithRange:NSMakeRange(start.location + 1, end.location - start.location - 1)];
	NSArray * lines = [innerText componentsSeparatedByString:@","];
	
    for (__strong NSString * line in lines)
    {
        line = [DbTextUtils trim:line];
        for (int i = 0; i < 10; i ++)
        {
            line = [line stringByReplacingOccurrencesOfString:@"  " withString:@" "];
        }
		NSArray * elements = [line componentsSeparatedByString:@" "];
		DbField * field = [[DbField alloc] init];
		field.name = [[DbTextUtils trim:[elements objectAtIndex:0]] stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        if (elements.count >= 2)
        {
            field.type = [self typeFromText:[elements objectAtIndex:1] fieldName:field.name];
            if ([field.name isEqualToString:@"id"])
            {
                field.key = true;
                field.autoIncrement = true;
                field.optional = false;
            }
        }
        else
        {
            field.type = kDbTypeString;
        }
		[table.fields setObject:field forKey:field.sqlFieldName];
	}
	
}

- (void)parseIndex:(SqliteEntry *)entry toSchema:(NSMutableDictionary *)sqliteSchema
{
	NSString * text = entry.sql;
	NSRange pos1 = [text rangeOfString:@"CREATE INDEX "];
	NSRange pos2 = [text rangeOfString:@" ON "];
	NSRange pos3 = [text rangeOfString:@" ("];
	NSRange pos4 = [text rangeOfString:@")"];
	NSString * indexName = [text substringWithRange:NSMakeRange(pos1.location + 13, pos2.location - pos1.location - 13)];
	NSString * tableName = [text substringWithRange:NSMakeRange(pos2.location + 4, pos3.location - pos2.location - 4)];
	NSString * fieldText = [text substringWithRange:NSMakeRange(pos3.location + 2, pos4.location - pos3.location - 2)].lowercaseString;
	
	DbTable * table = [sqliteSchema objectForKey:tableName];
	if (table)
	{
		NSString * prefix = [NSString stringWithFormat:@"%@_", tableName];
		NSRange pos = [indexName rangeOfString:prefix];
		if (pos.location == 0)
		{
			DbIndex * index = [[DbIndex alloc] init];
			index.name = [indexName substringFromIndex:tableName.length + 1].lowercaseString;
			[table.indice setObject:index forKey:indexName];
			[self parseText:fieldText toIndex:index];
		}
	}
}


- (void)parseText:(NSString *)text toIndex:(DbIndex *)index
{
	NSArray * fields = [text componentsSeparatedByString:@", "];
    for (NSString * field in fields)
    {
		if (!index.fields)
		{
			index.fields = [[NSMutableArray alloc] init];
		}
		[index.fields addObject:field.lowercaseString];
	}
}

- (EDbType)typeFromText:(NSString *)text fieldName:(NSString *)name
{
    text = [DbTextUtils trim:text.uppercaseString];
	if ([text isEqualToString:@"INTEGER"])
	{
        if ([name isEqualToString:@"id"])
        {
            return kDbTypeInt64;
        }
        else if ([name containsString:@"_id"])
        {
            return kDbTypeInt64;
        }
        else if ([name hasPrefix:@"on_"] ||
                 [name hasPrefix:@"has_"] ||
                 [name hasPrefix:@"is_"] ||
                 [name hasSuffix:@"ed"] ||
                 [name isEqualToString:@"active"])
        {
            return kDbTypeBoolean;
        }
        else
        {
            return kDbTypeInt32; //@"Integer 32";
        }
    }
    else if ([text isEqualToString:@"BOOLEAN"])
    {
        return kDbTypeBoolean; // @"String";
    }
	else if ([text isEqualToString:@"TEXT"])
	{
		return kDbTypeString; // @"String";
	}
	else if ([text isEqualToString:@"NUMERIC"])
	{
		return kDbTypeFloat; // @"Float";
    }
    else if ([text isEqualToString:@"DATE"])
    {
        return kDbTypeDate; // @"Date";
    }
	else if ([text isEqualToString:@"DATETIME"])
	{
		return kDbTypeDateTime; // @"Date";
	}
	else
	{
		return kDbTypeString; // @"String";
	}
    
}

- (NSString *)trimText:(NSString *)text
{
	NSArray * elements = [text componentsSeparatedByString:@" "];
	NSMutableString * newText = [[NSMutableString alloc] initWithCapacity:128];
	for (int i = 0; i < [elements count]; i ++)
	{
		NSString * element = [elements objectAtIndex:i];
		if (![element isEqualToString:@" "])
		{
			[newText appendString:element];
		}
	}
	return newText;
}

- (void)updateIndexForTable:(DbTable *)table existing:(DbTable *)existingTable
{
	if (table.indice)
	{
		NSArray * keys = [table.indice allKeys];
		for (int i = 0; i < [keys count]; i ++)
		{
			NSString * key = (NSString *)[keys objectAtIndex:i];
			DbIndex * existingIndex = nil;
			if (existingTable && existingTable.indice)
			{
                NSString * indexName = [NSString stringWithFormat:@"%@_%@", table.name, key];
				existingIndex = [existingTable.indice objectForKey:indexName];
			}
			if (!existingIndex)
			{
				DbIndex * index = (DbIndex *)[table.indice objectForKey:key];
				[self addIndex:index toTable:table];
			}
		}
	}
}

- (bool)addIndex:(DbIndex *)index toTable:(DbTable *)table
{
	bool pass = false;
	NSString * sql = [self addIndexStatement:index toTable:table];
    
    DebugHelperLog(@"db", sql);
    
	sqlite3_stmt * compiledStatement = nil;
	if(sqlite3_prepare_v2(self.db, [sql UTF8String], -1, &compiledStatement, NULL) == SQLITE_OK)
	{
		if (sqlite3_step(compiledStatement) == SQLITE_ROW)
		{
			pass = true;
		}
	}
	sqlite3_finalize(compiledStatement);
	return pass;
}

- (NSString *)addIndexStatement:(DbIndex *)index toTable:(DbTable *)table
{
	NSMutableString * builder = [[NSMutableString alloc] initWithCapacity:128];
	[builder appendString:@"CREATE INDEX "];
	[builder appendString:table.name];
	[builder appendString:@"_"];
	[builder appendString:index.name];
	[builder appendString:@" ON "];
	[builder appendString:table.name];
	[builder appendString:@" ("];
	[builder appendString:[index fieldsText]];
	[builder appendString:@")"];
	return builder;
}

- (void)beginTransactions
{
    sqlite3_exec(self.db, "BEGIN", 0, 0, 0);
}

- (void)commitTransactions
{
    sqlite3_exec(self.db, "COMMIT", 0, 0, 0);
}

- (void)dealloc
{
    self.path = nil;
    self.tables = nil;
    self.db = nil;
}

@end
