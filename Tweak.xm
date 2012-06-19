
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIGestureRecognizerSubclass.h>


@interface DOMNode : NSObject
@end

@interface UIThreadSafeNode : NSObject {
	DOMNode *_node; 
}
-(id)_realNode;
@end

@interface DOMHTMLInputElement : NSObject
-(NSString*)text;

-(void)setSelectionRange:(int)start end:(int)end;
-(void)setSelectionEnd:(int)arg1;
-(int)selectionEnd;
-(void)setSelectionStart:(int)arg1;
-(int)selectionStart;
@end

@interface DOMHTMLTextAreaElement : NSObject
-(NSString*)text;

-(void)setSelectionRange:(int)start end:(int)end;
-(void)setSelectionEnd:(int)arg1;
-(int)selectionEnd;
-(void)setSelectionStart:(int)arg1;
-(int)selectionStart;
@end


@protocol UITextInputPrivate <UITextInput>//, UITextInputTokenizer, UITextInputTraits_Private, UITextSelectingContainer>
-(BOOL)shouldEnableAutoShift;
-(NSRange)selectionRange;
-(CGRect)rectForNSRange:(NSRange)nsrange;
-(NSRange)_markedTextNSRange;
//-(id)selectedDOMRange;
//-(id)wordInRange:(id)range;
//-(void)setSelectedDOMRange:(id)range affinityDownstream:(BOOL)downstream;
//-(void)replaceRangeWithTextWithoutClosingTyping:(id)textWithoutClosingTyping replacementText:(id)text;
//-(CGRect)rectContainingCaretSelection;
-(void)moveBackward:(unsigned)backward;
-(void)moveForward:(unsigned)forward;
-(unsigned short)characterBeforeCaretSelection;
-(id)wordContainingCaretSelection;
-(id)wordRangeContainingCaretSelection;
-(id)markedText;
-(void)setMarkedText:(id)text;
-(BOOL)hasContent;
-(void)selectAll;
-(id)textColorForCaretSelection;
-(id)fontForCaretSelection;
-(BOOL)hasSelection;
@end

@interface UIKeyboardLayout : UIView
//new
- (void)updateThis:(UIEvent *)event;
@end

@interface UIKeyboardImpl : UIView
+(id)sharedInstance;
@property(readonly, assign, nonatomic) UIResponder <UITextInputPrivate> *privateInputDelegate;
-(BOOL)isLongPress;
-(id)_layout;
-(BOOL)callLayoutIsShiftKeyBeingHeld;
//new
- (void)updateThis:(UIEvent *)event;
@end

@interface UIWebDocumentView : UIView {
    id m_parentTextView;
}
-(NSString*)text;
@end

@interface UIFieldEditor : UIView
-(NSRange)selectionRange;
-(void)setSelection:(NSRange)range;
-(NSString*)text;

-(BOOL)keyboardInput:(id)arg1 shouldInsertText:(id)arg2 isMarkedText:(BOOL)arg3;
-(BOOL)keyboardInputShouldDelete:(id)arg1;
-(BOOL)keyboardInputChanged:(id)arg1;
-(void)keyboardInputChangedSelection:(id)arg1;
-(void)selectAll;
-(void)selectionChanged;
@end


@interface KHPanGestureRecognizer : UIPanGestureRecognizer
@end

%hook UIKeyboardLayout

static CGPoint startPoint;
static NSRange startRange;
static NSRange newRange;

// Basic info
static BOOL shiftHeldDown = NO;
static int numberOfTouches = 0;
static BOOL hasStarted = NO;
static BOOL longPress = NO;
static BOOL handWriting = NO;
static BOOL haveCheckedHand = NO;

static BOOL tracked = NO;

id <UITextInputPrivate, NSObject, NSCoding> privateInputDelegate = nil;

%new
- (void)updateThis:(UIEvent *)event {
    
    int touchesCount = [[event allTouches] count];
    if (touchesCount > numberOfTouches) {
        numberOfTouches = touchesCount;
    }
    
    UIKeyboardImpl *keyboardImpl = [%c(UIKeyboardImpl) sharedInstance];
    
    if ([keyboardImpl respondsToSelector:@selector(isLongPress)]) {
        BOOL nLongTouch = [keyboardImpl isLongPress];
        if (nLongTouch) {
            longPress = nLongTouch;
        }
    }
    
    id currentLayout = nil;
    if ([keyboardImpl respondsToSelector:@selector(_layout)]) {
        currentLayout = [keyboardImpl _layout];
    }
    
    // Chinese handwriting check - (hacky)
    if ([currentLayout respondsToSelector:@selector(subviews)] && !handWriting && !haveCheckedHand) {
        NSArray *subviews = [((UIView*)currentLayout) subviews];
        for (UIView *subview in subviews) {
            
            if ([subview respondsToSelector:@selector(subviews)]) {
                NSArray *arrayToCheck = [subview subviews];
                
                for (id view in arrayToCheck) {
                    NSString *classString = [NSStringFromClass([view class]) lowercaseString];
                    NSString *substring = [@"Handwriting" lowercaseString];
                    
                    if ([classString rangeOfString:substring].location != NSNotFound) {
                        handWriting = YES;
                        break;
                    }
                }
            }
        }
        haveCheckedHand = YES;
    }
    
    
    if ([keyboardImpl respondsToSelector:@selector(callLayoutIsShiftKeyBeingHeld)] && !shiftHeldDown) {
        shiftHeldDown = [keyboardImpl callLayoutIsShiftKeyBeingHeld];
    }
    
    if ([keyboardImpl respondsToSelector:@selector(privateInputDelegate)]) {
        privateInputDelegate = (id)keyboardImpl.privateInputDelegate;
    }
}
- (void)touchesBegan:(id)arg1 withEvent:(id)arg2 {
    %orig;
    
    [self updateThis:arg2];
    
    startPoint = [[[arg2 allTouches] anyObject] locationInView:(UIView *)self];
    
    hasStarted = YES;
    
    Class webDocumentViewClass = %c(UIWebDocumentView);
    Class textFieldClass = %c(UIFieldEditor);
    Class threadSafeNode = %c(UIThreadSafeNode);
    
    if (privateInputDelegate) {
        if ([privateInputDelegate isKindOfClass:textFieldClass]) {
            UIFieldEditor *textField = (UIFieldEditor*)privateInputDelegate;
            if ([textField respondsToSelector:@selector(selectionRange)]) {
                startRange = [textField selectionRange];
            }
        }
        else if ([privateInputDelegate isKindOfClass:webDocumentViewClass]) {
            UITextView *textView = MSHookIvar<UITextView *>(privateInputDelegate, "m_parentTextView");
            
            if (textView) {
                if ([textView respondsToSelector:@selector(selectedRange)]) {
                    startRange = [textView selectedRange];
                }
            }
        }
        else if ([privateInputDelegate isKindOfClass:threadSafeNode]) {
            DOMHTMLInputElement *textView = privateInputDelegate;
            
            int start = 0;
            if ([textView respondsToSelector:@selector(selectionStart)]) {
                start = [textView selectionStart];
            }
            
            int end = 0;
            if ([textView respondsToSelector:@selector(selectionEnd)]) {
                end = [textView selectionEnd];
            }
            
            startRange = NSMakeRange(start, (end - start));
        }    
        
    }

}
- (void)touchesMoved:(id)arg1 withEvent:(id)arg2 {
    %orig;
    
    [self updateThis:arg2];
    
    if (/*(longPress && !tracked) || */handWriting) {
        return;
    }
    
    CGPoint thisPoint = [[[arg2 allTouches] anyObject] locationInView:(UIView *)self];
    CGPoint offset = CGPointMake(thisPoint.x-startPoint.x, thisPoint.y-startPoint.y);
    
    if (!hasStarted && fabs(offset.x) < 10) {
        return;
    }
    
    Class webDocumentViewClass = %c(UIWebDocumentView);
    Class textFieldClass = %c(UIFieldEditor);
    Class threadSafeNode = %c(UIThreadSafeNode);
    
    int scale = 16;
    if (numberOfTouches >= 2) {
        scale = 8; // make it go faster
    }
    
    // Get caracters back it should go
    int pointsChanged = offset.x / scale;
    int newLocation = startRange.location;
    int newLength = startRange.length;
    
    // Get total length of text
    int textLength = -1;
    if ([privateInputDelegate respondsToSelector:@selector(text)]) {
        NSString *text = [(UIFieldEditor*)privateInputDelegate text];
        if ([text respondsToSelector:@selector(length)]) {
            textLength = [text length];
        }
    }
    
    if (shiftHeldDown) {
        if (pointsChanged > 0) {
            newLength += pointsChanged;
            
            if ((newLength + newLocation) > textLength) {
                newLength = textLength - newLocation;
            }
        }
        else {
            newLocation += pointsChanged;
            newLength -= pointsChanged;
            
            int startPosition = newLocation + newLength;
            if (newLocation < 0) {
                newLocation = 0;
                newLength = startPosition;
            }
        }
    }
    else {
        newLength = 0;
        newLocation += pointsChanged;
        
        if (newLocation > textLength) {
            newLocation = textLength;
        }
        else if (newLocation < 0) {
            newLocation = 0;
        }
    }
    
    newRange = NSMakeRange(newLocation, newLength);
    
    if (privateInputDelegate) {
        if ([privateInputDelegate isKindOfClass:textFieldClass]) {
            UIFieldEditor *textField = (UIFieldEditor*)privateInputDelegate;
            if ([textField respondsToSelector:@selector(setSelection:)]) {
                tracked = YES;
                [textField setSelection:newRange];
            }
        }
        else if ([privateInputDelegate isKindOfClass:webDocumentViewClass]) {
            UITextView *textView = MSHookIvar<UITextView *>(privateInputDelegate, "m_parentTextView");
            if (textView) {
                if ([textView respondsToSelector:@selector(setSelectedRange:)]) {
                    tracked = YES;
                    [textView setSelectedRange:newRange];
                }
            }
        }
        else if ([privateInputDelegate isKindOfClass:threadSafeNode]) {
            DOMHTMLInputElement *textView = privateInputDelegate;
            
            if ([textView respondsToSelector:@selector(setSelectionStart:)]) {
                tracked = YES;
                [textView setSelectionStart:newRange.location];
            }
            if ([textView respondsToSelector:@selector(setSelectionEnd:)]) {
                tracked = YES;
                [textView setSelectionEnd:(newRange.location + newRange.length)];
            }
        }
    }
}
- (void)touchesCancelled:(id)arg1 withEvent:(id)arg2 {
    %orig;
    shiftHeldDown = NO;
    longPress = NO;
    hasStarted = NO;
    numberOfTouches = 0;
    handWriting = NO;
    haveCheckedHand = NO;
    tracked = NO;
}
- (void)touchesEnded:(id)arg1 withEvent:(id)arg2 {
    %orig;
    shiftHeldDown = NO;
    longPress = NO;
    hasStarted = NO;
    numberOfTouches = 0;
    handWriting = NO;
    haveCheckedHand = NO;
    tracked = NO;
}

%end
