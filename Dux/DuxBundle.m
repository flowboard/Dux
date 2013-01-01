//
//  DuxBundle.m
//  Dux
//
//  Created by Abhi Beckert on 2013-1-1.
//
//

#import "DuxBundle.h"
#import "MyAppDelegate.h"

const NSString *DuxBundleTypeScript = @"Script";
const NSString *DuxBundleInputTypeNone = @"None";
const NSString *DuxBundleOutputTypeNone = @"None";
const NSString *DuxBundleOutputTypeAlert = @"Alert";

static NSArray *loadedBundles;

@interface DuxBundle ()

@property NSString *displayName;
@property NSURL *URL;
@property NSBundle *fileBundle;
@property NSUInteger lastLoadHash; // hash of bundle filenames and modification dates
@property NSMenuItem *menuItem;
@property NSString *inputType;
@property NSString *outputType;
@property NSString *type;
@property NSURL *scriptURL;

+ (void)unloadAllBundles;

// load or unload this bundle. unlike init/dealloc, a bundle object might be loaded/unloaded
// multiple items during it's lifecycle (eg: if the user edits the bundle while dux is open)
- (void)load;
- (void)unload;

// returns YES if bundle has never been loaded or if it has changed on disk and needs to be loaded again (note: these operations are slow and should not be done often)
- (BOOL)needsLoading;
+ (NSUInteger)calculateLoadHashForURL:(NSURL *)URL;

@end

@implementation DuxBundle

+ (void)initialize
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    loadedBundles = [NSArray array];
  });
}

+ (DuxBundle *)bundleForSender:(id)sender
{
  for (DuxBundle *bundle in loadedBundles) {
    if (bundle.menuItem == sender)
      return bundle;
  }
  
  return nil;
}

+ (NSURL *)bundlesURL
{
  static NSURL *bundlesURL = nil;
  if (bundlesURL) {
    return bundlesURL;
  }
  
  NSURL *appSupportDir = [[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:NULL];
  
  bundlesURL = [appSupportDir URLByAppendingPathComponent:@"Dux/Bundles" isDirectory:YES];
  
  BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:bundlesURL.path];
  if (!exists) {
    [[NSFileManager defaultManager] createDirectoryAtURL:bundlesURL withIntermediateDirectories:YES attributes:nil error:NULL];
  }
  
  return bundlesURL;
}

+ (NSArray *)allBundles
{
  return [loadedBundles copy];
}

+ (void)loadBundles
{
  NSFileManager *fileManager = [[NSFileManager alloc] init];
  NSURL *bundlesDir = [[self class] bundlesURL];
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
    // create a copy of loadedBundles, so we can iterate it on a background thread to find
    // already loaded bundles, removing each one from this array as we process them, and
    // finally unloading any bundle still in this array at the end.
    __block NSMutableArray *previouslyLoadedBundles;
    dispatch_sync(dispatch_get_main_queue(), ^{
      previouslyLoadedBundles = [loadedBundles mutableCopy];
    });
    
    NSDirectoryEnumerator *bundlesDirEnumerator = [fileManager enumeratorAtURL:[bundlesDir URLByResolvingSymlinksInPath] includingPropertiesForKeys:@[NSURLIsPackageKey] options:NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsHiddenFiles errorHandler:NULL];
    for (NSURL *bundleURL in bundlesDirEnumerator) {
      if (![bundleURL.pathExtension isEqualToString:@"duxbundle"]) {
        continue;
      }
      
      DuxBundle *bundle = nil;
      for (DuxBundle *previouslyLoadedBundle in previouslyLoadedBundles) {
        if ([previouslyLoadedBundle.URL isEqual:bundleURL]) {
          bundle = previouslyLoadedBundle;
          [previouslyLoadedBundles removeObject:bundle];
          break;
        }
      }
      
      if (!bundle) {
        bundle = [[DuxBundle alloc] init];
        bundle.URL = bundleURL;
        
        dispatch_sync(dispatch_get_main_queue(), ^{
          loadedBundles = [loadedBundles arrayByAddingObject:bundle];
        });
      }
      
      dispatch_sync(dispatch_get_main_queue(), ^{
        if ([bundle needsLoading]) {
          [bundle load];
        }
      });
      
      [bundlesDirEnumerator skipDescendants];
    }
    
    for (DuxBundle *bundle in previouslyLoadedBundles) {
      dispatch_sync(dispatch_get_main_queue(), ^{
        [bundle unload];
        
        NSMutableArray *mutableBundles = [loadedBundles mutableCopy];
        [mutableBundles removeObject:bundle];
        loadedBundles = [mutableBundles copy];
      });
    }
  });
}

+ (void)unloadAllBundles
{
  
}

- (void)load
{
  if (self.lastLoadHash != 0)
    [self unload];
  
  NSDictionary *infoDictionary = [[NSBundle bundleWithURL:self.URL] infoDictionary];
  
  self.displayName = [[self.URL lastPathComponent] stringByDeletingPathExtension];
  NSURL *bundlesURL = [[self class] bundlesURL];
  if (![self.URL.path.stringByDeletingLastPathComponent isEqualToString:bundlesURL.path]) {
    NSArray *relativePathComponents = [self.URL.path.stringByDeletingLastPathComponent substringFromIndex:[[self class] bundlesURL].path.length + 1].pathComponents;
    
    for (NSString *folderName in relativePathComponents) {
      self.displayName = [NSString stringWithFormat:@"%@ › %@", folderName, self.displayName];
    }
  }
  
  self.type = [infoDictionary valueForKey:@"Type"];
  
  if ([self.type isEqualToString:(NSString *)DuxBundleTypeScript]) {
    self.scriptURL = [self.URL URLByAppendingPathComponent:[NSString stringWithFormat:@"Contents/%@", [infoDictionary valueForKey:@"Script"]]];
  } else {
    self.scriptURL = nil;
  }
  
  self.inputType = [infoDictionary valueForKey:@"Input"];
  self.outputType = [infoDictionary valueForKey:@"Output"];
  
  self.menuItem = [[NSMenuItem alloc] init];
  self.menuItem.title = [[self.URL lastPathComponent] stringByDeletingPathExtension];
  self.menuItem.action = @selector(performDuxBundle:);
  
  for (NSDictionary *trigger in [infoDictionary valueForKey:@"Triggers"]) {
    if (![[trigger valueForKey:@"Type"] isEqualToString:@"Key"])
      continue;
    
    self.menuItem.keyEquivalentModifierMask = 0;
    for (NSString *keyComponent in [[trigger valueForKey:@"Key"] componentsSeparatedByString:@"+"]) {
      if ([keyComponent isEqualToString:@"Control"]) {
        self.menuItem.keyEquivalentModifierMask = self.menuItem.keyEquivalentModifierMask | NSControlKeyMask;
      } else if ([keyComponent isEqualToString:@"Option"]) {
        self.menuItem.keyEquivalentModifierMask = self.menuItem.keyEquivalentModifierMask | NSAlternateKeyMask;
      } else if ([keyComponent isEqualToString:@"Command"]) {
        self.menuItem.keyEquivalentModifierMask = self.menuItem.keyEquivalentModifierMask | NSCommandKeyMask;
      } else {
        self.menuItem.keyEquivalent = keyComponent;
      }
    }
  }
  
  [self insertBundleMenuItem]; // inserts the menu item into the correct (alphabetically sorted) location
  
  self.lastLoadHash = [[self class] calculateLoadHashForURL:self.URL];
}

- (void)unload
{
  [self.menuItem.menu removeItem:self.menuItem];
  
  self.lastLoadHash = 0;
}

+ (NSUInteger)calculateLoadHashForURL:(NSURL *)URL
{
  // init a hash of this load operation
  NSUInteger prime = 31;
  NSUInteger loadHash = 1;
  
  // iterate through all files, loading each one
  NSDirectoryEnumerator *dirEnumerator = [[NSFileManager defaultManager] enumeratorAtURL:URL includingPropertiesForKeys:nil options:0 errorHandler:NULL];
  for (NSURL *childURL in dirEnumerator) {
    // get details
    NSString *fileName;
    NSNumber *fileSize;
    NSDate *fileModified;
    [childURL getResourceValue:&fileName forKey:NSURLNameKey error:NULL];
    [childURL getResourceValue:&fileSize forKey:NSURLFileSizeKey error:NULL];
    [childURL getResourceValue:&fileModified forKey:NSURLContentModificationDateKey error:NULL];
    
    // update hash
    loadHash = prime * loadHash + childURL.hash;
    loadHash = prime * loadHash + fileName.hash;
    loadHash = prime * loadHash + fileSize.hash;
    loadHash = prime * loadHash + fileModified.hash;
  }
  
  return loadHash;
}

- (BOOL)needsLoading
{
  if (self.lastLoadHash == 0)
    return YES;
  
  return (self.lastLoadHash != [[self class] calculateLoadHashForURL:self.URL]);
}

- (void)insertBundleMenuItem
{
  NSMenu *menu = [(MyAppDelegate *)[NSApplication sharedApplication].delegate bundlesMenu];
  
  // figure out the submenu path
  NSURL *bundlesURL = [[self class] bundlesURL];
  if (![self.URL.path.stringByDeletingLastPathComponent isEqualToString:bundlesURL.path]) {
    NSArray *relativePathComponents = [self.URL.path.stringByDeletingLastPathComponent substringFromIndex:[[self class] bundlesURL].path.length + 1].pathComponents;
    
    for (NSString *submenuTitle in relativePathComponents) {
      NSMenuItem *submenuItem = [menu itemWithTitle:submenuTitle];
      if (!submenuItem) {
        submenuItem = [[NSMenuItem alloc] init];
        submenuItem.title = submenuTitle;
        submenuItem.submenu = [[NSMenu alloc] init];
        
        NSUInteger index = 0;
        for (NSMenuItem *existingMenuItem in menu.itemArray) {
          if (existingMenuItem.isSeparatorItem)
            break;
          if ([existingMenuItem.title compare:submenuTitle options:NSNumericSearch] == NSOrderedDescending)
            break;
          
          index++;
        }
        [menu insertItem:submenuItem atIndex:index];
      }
      
      menu = submenuItem.submenu;
    }
  }
  
  // find either the separator item, or the first item who's title is NSOrderedDescending compared to ours, and insert it there
  NSUInteger index = 0;
  for (NSMenuItem *existingMenuItem in menu.itemArray) {
    if (existingMenuItem.isSeparatorItem)
      break;
    
    if ([existingMenuItem.title compare:self.menuItem.title options:NSNumericSearch] == NSOrderedDescending) {
      break;
    }
    
    index++;
  }
  
  [menu insertItem:self.menuItem atIndex:index];
}

- (NSString *)runWithWorkingDirectory:(NSURL *)workingDirectoryURL
{
  NSTask *task = [[NSTask alloc] init];
  task.launchPath = self.scriptURL.path;
  task.standardOutput = [NSPipe pipe];
  task.currentDirectoryPath = workingDirectoryURL.path;
  task.environment = @{@"foo": @"bar"};

  [task launch];
  [task waitUntilExit];

  NSData *standardOutput = [[(NSPipe *)task.standardOutput fileHandleForReading] readDataToEndOfFile];
  NSString *output = [[NSString alloc] initWithData:standardOutput encoding:NSUTF8StringEncoding];
  
  
  if ([self.outputType isEqualToString:(NSString *)DuxBundleOutputTypeAlert]) {
    NSAlert *alert = [NSAlert alertWithMessageText:self.displayName defaultButton:@"Dismiss" alternateButton:nil otherButton:nil informativeTextWithFormat:@"%@", output];
    [alert runModal];
    return nil;
  }
  
  return output;
}

@end