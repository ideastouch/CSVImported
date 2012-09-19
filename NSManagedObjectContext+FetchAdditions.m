//
//  NSManagedObjectContext+FetchAdditions.m
//
//  Created by Matt Gallagher on 26/02/07.
//  Copyright 2007 Matt Gallagher. All rights reserved.
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

#import "NSManagedObjectContext+FetchAdditions.h"

@implementation NSManagedObjectContext (FetchAdditions)

//
// fetchObjectArrayForRequest:
//
// Convenience method to issue a fetch request on the receiver, gather the
// results and return them as a set.
//
- (NSArray *)fetchObjectArrayForRequest:(NSFetchRequest *)request
{
	NSError *error = nil;
	NSArray *results = [self executeFetchRequest:request error:&error];
	
	NSAssert(error == nil, [error description]);
	
	return results;
}

//
// fetchRequestForEntityName:
//
// Convenience method that builds a fetch request for the specified entity
// named, where the entity name is resolved in the receiver.
//
- (NSFetchRequest *)fetchRequestForEntityName:(NSString *)newEntityName
{
	NSEntityDescription *entity =
		[NSEntityDescription
			entityForName:newEntityName
			inManagedObjectContext:self];

	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:entity];
	
	return request;
}

//
// fetchObjectArrayForEntityName:withPredicate:
//
// Convenience method to fetch the array of entities for a given name in
// the context, optionally limiting by a predicate.
//
- (NSArray *)fetchObjectArrayForEntityName:(NSString *)newEntityName
	withPredicate:(id)stringOrPredicate, ...
{
	NSFetchRequest *request =
		[self fetchRequestForEntityName:newEntityName];
	
	if (stringOrPredicate)
	{
		NSPredicate *predicate;
		if ([stringOrPredicate isKindOfClass:[NSString class]])
		{
			va_list variadicArguments;
			va_start(variadicArguments, stringOrPredicate);
			predicate =
				[NSPredicate
					predicateWithFormat:stringOrPredicate
					arguments:variadicArguments];
			va_end(variadicArguments);
		}
		else
		{
			NSAssert2([stringOrPredicate isKindOfClass:[NSPredicate class]],
				@"Second parameter passed to %s is of unexpected class %@",
				sel_getName(_cmd), [stringOrPredicate className]);
			predicate = (NSPredicate *)stringOrPredicate;
		}
		[request setPredicate:predicate];
	}

	NSError *error = nil;
	NSArray *results = [self executeFetchRequest:request error:&error];
	
	NSAssert(error == nil, [error description]);
	
	return results;
}

@end
