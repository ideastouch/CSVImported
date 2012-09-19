//
//  CSVImporter.m
//  CSVImporter
//
//  Created by Matt Gallagher on 2009/11/30.
//  Copyright Matt Gallagher 2009 . All rights reserved.
//
//  This software is provided 'as-is', without any express or implied
//  warranty. In no event will the authors be held liable for any damages
//  arising from the use of this software. Permission is granted to anyone to
//  use this software for any purpose, including commercial applications, and to
//  alter it and redistribute it freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//     claim that you wrote the original software. If you use this software
//     in a product, an acknowledgment in the product documentation would be
//     appreciated but is not required.
//  2. Altered source versions must be plainly marked as such, and must not be
//     misrepresented as being the original software.
//  3. This notice may not be removed or altered from any source
//     distribution.
//

#import "EntryReceiver.h"
#import "CSVParser.h"
#import "NSManagedObjectContext+FetchAdditions.h"

int main (int argc, const char *argv[])
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSError *error = nil;    
	
	if ([[[NSProcessInfo processInfo] arguments] count] != 4)
	{
		printf("Usage: %s <pathToCoreDataMOMFile> <pathForCoreDataSQLOutputFile> <pathToInputCSVFile>",
			[[[NSProcessInfo processInfo] processName] UTF8String]);
		[pool drain];
		exit(1);
	}
	
	NSString *modelPath = [[[NSProcessInfo processInfo] arguments] objectAtIndex:1];
	NSURL *modelURL = [NSURL fileURLWithPath:modelPath];
    NSManagedObjectModel *model = [[[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL] autorelease];

	if (!model)
	{
		printf("Couldn't open Core Data MOM file at path %s",
			[modelPath UTF8String]);
		[pool drain];
		exit(1);
	}

    NSManagedObjectContext *context = [[[NSManagedObjectContext alloc] init] autorelease];
    NSPersistentStoreCoordinator *coordinator = [[[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model] autorelease];

	if (!coordinator)
	{
		printf("Couldn't create coordinator for model at path %s",
			[modelPath UTF8String]);
		[pool drain];
		exit(1);
	}

    [context setPersistentStoreCoordinator:coordinator];
	
	NSLog(@"context undomanager is %@", [context undoManager]);
	[context setUndoManager:nil];
	
	NSString *storagePath = [[[NSProcessInfo processInfo] arguments] objectAtIndex:2];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:storagePath] &&
		![[NSFileManager defaultManager] removeItemAtPath:storagePath error:&error])
	{
		printf("Couldn't remove existing file at path %s\n. Error: %s",
			[storagePath UTF8String],
			[[error localizedDescription] ? [error localizedDescription] : [error description] UTF8String]);
		[pool drain];
		exit(1);
	}
	
	NSURL *storageURL = [NSURL fileURLWithPath:storagePath];
    NSPersistentStore *newStore = [coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storageURL options:nil error:&error];
	
	if (!newStore)
	{
		printf("Couldn't open Core Data SQL output file at path %s\n. Error: %s",
			[storagePath UTF8String],
			[[error localizedDescription] ? [error localizedDescription] : [error description] UTF8String]);
		[pool drain];
		exit(1);
	}
	
	NSString *inputPath = [[[NSProcessInfo processInfo] arguments] objectAtIndex:3];
	NSString *csvString = [NSString stringWithContentsOfFile:inputPath encoding:NSUTF8StringEncoding error:&error];

	if (!csvString)
	{
		printf("Couldn't read file at path %s\n. Error: %s",
			[inputPath UTF8String],
			[[error localizedDescription] ? [error localizedDescription] : [error description] UTF8String]);
		[pool drain];
		exit(1);
	}
	
	NSDate *startDate = [NSDate date];
	
	EntryReceiver *receiver =
		[[[EntryReceiver alloc]
			initWithContext:context
			entityName:@"Postcode"] autorelease];
	CSVParser *parser =
		[[[CSVParser alloc]
			initWithString:csvString
			separator:@","
			hasHeader:NO
			fieldNames:
				[NSArray arrayWithObjects:
					@"postcode",
					@"suburb",
					@"state",
					@"postOffice",
					@"type",
					@"latitude",
					@"longitude",
				nil]]
		autorelease];
	[parser parseRowsForReceiver:receiver selector:@selector(receiveRecord:)];
		
	NSDate *endDate = [NSDate date];

	NSLog(@"%ld postcode entries successfully imported in %f seconds.",
		[[context fetchObjectArrayForEntityName:@"Postcode" withPredicate:nil] count],
		[endDate timeIntervalSinceDate:startDate]);

    if (![context save:&error])
	{
		printf("Error while saving\n%s",
			[[error localizedDescription] ?
				[error localizedDescription] : [error description] UTF8String]);
		[pool drain];
		exit(1);
    }
	
	[pool drain];
	
    return 0;
}
