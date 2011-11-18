//
//  DuxLanguage.m
//  Dux
//
//  Created by Abhi Beckert on 2011-10-22.
//  
//  This is free and unencumbered software released into the public domain.
//  For more information, please refer to <http://unlicense.org/>
//

#import "DuxLanguage.h"

@implementation DuxLanguage

static NSMutableDictionary *sharedInstances = nil;

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

- (DuxLanguageElement *)baseElement
{
  @throw [NSException exceptionWithName:@"not defined" reason:@"baseElement must be implemented by a subclass" userInfo:nil];
}

- (void)wrapCommentsAroundRange:(NSRange)commentRange ofTextView:(NSTextView *)textView
{
  @throw [NSException exceptionWithName:@"not defined" reason:@"wrapCommentsAroundRange:ofTextStorage: must be implemented by a subclass" userInfo:nil];
}

- (void)prepareToParseTextStorage:(NSTextStorage *)textStorage
{
}

@end