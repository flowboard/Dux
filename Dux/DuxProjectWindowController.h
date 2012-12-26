//
//  DuxProjectWindowController.h
//  Dux
//
//  Created by Abhi Beckert on 2012-12-26.
//
//

#import <Cocoa/Cocoa.h>
#import "DuxTextView.h"

@interface DuxProjectWindowController : NSWindowController

@property (nonatomic, strong) NSMutableArray *documents;

@property (unsafe_unretained) IBOutlet NSWindow *editorWindow;

@property (unsafe_unretained) IBOutlet DuxTextView *textView;
@property (weak) IBOutlet NSTextField *documentPathLabel;
@property (weak) IBOutlet NSPopUpButton *documentHistoryPopUp;

@property (weak) IBOutlet NSToolbarItem *historyToolbarItem;
@property (strong) IBOutlet NSView *historyToolbarItemView;
@property (weak) IBOutlet NSToolbarItem *pathToolbarItem;
@property (strong) IBOutlet NSView *pathToolbarItemView;


- (void)reloadDocumentHistoryPopUp;
- (IBAction)loadDocumentFromHistoryPopUp:(NSPopUpButton *)sender;

@end
