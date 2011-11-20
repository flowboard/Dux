//
//  DuxLanguageElement.m
//  Dux
//
//  Created by Abhi Beckert on 2011-10-22.
//  
//  This is free and unencumbered software released into the public domain.
//  For more information, please refer to <http://unlicense.org/>
//

#import "DuxLanguageElement.h"
#import "DuxLanguage.h"

@implementation DuxLanguageElement

@synthesize language;

static NSMutableDictionary *sharedInstances = nil;
static NSColor *color = nil;

+ (id)sharedInstance
{
  if (!sharedInstances)
    sharedInstances = [[NSMutableDictionary alloc] init];
  
  NSString *className = NSStringFromClass(self);
  id sharedInstance = [sharedInstances valueForKey:className];
  
  if (!sharedInstance) {
    sharedInstance = [[self alloc] init];
    [sharedInstances setValue:sharedInstance forKey:className];
  }
  
  return sharedInstance;
}

- (id)init
{
  @throw [NSException exceptionWithName:@"cannot create DuxLanguageElement subclasse" reason:@"a subclass must override -init to call -initWithLanguage" userInfo:nil];
  return nil;
}

- (id)initWithLanguage:(DuxLanguage *)_language
{
  if (!(self = [super init])) {
    return nil;
  }
  
  self.language = _language;
  
  return self;
}

- (NSUInteger)lengthInString:(NSAttributedString *)string startingAt:(NSUInteger)startingAt nextElement:(DuxLanguageElement *__strong*)nextElement
{
  return string.length - startingAt;
}

- (NSColor *)color
{
  if (!color)
    color = [NSColor blackColor];
  
  return color;
}

- (BOOL)isComment
{
  return NO;
}

@end
