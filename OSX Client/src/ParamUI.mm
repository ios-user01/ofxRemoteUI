
#import "ParamUI.h"
#include "ofxRemoteUI.h"
#include "AppDelegate.h"
#import <QuartzCore/QuartzCore.h>

@implementation ParamUI

-(void)dealloc{
	deleting = true;
	[widget setTarget:nil];
	[ui removeFromSuperviewWithoutNeedingDisplay];
	[ui release];
	[super dealloc];
}

-(id)initWithParam: (RemoteUIParam)p paramName:(string)name ID:(int)n{
	waitingForMidiTimer = nil;
	midiHighlightAnim = false;
	self = [super init];
	numberID = n;
	widget = nil;
	param = p;
	deleting = false;
	paramName = name;
	AppDelegate * delegate = (AppDelegate *) [NSApp delegate];
	RowHeightSize rowH = [delegate getRowHeight];
	BOOL didLoad = FALSE;
	switch (rowH) {
		case LARGE_34: didLoad = [NSBundle loadNibNamed:@"View34" owner:self];
			break;
		case SMALL_26: didLoad = [NSBundle loadNibNamed:@"View26" owner:self];
			break;
		case TINY_20: didLoad = [NSBundle loadNibNamed:@"View20" owner:self];
			break;

		default:
			break;
	}
	if(!didLoad){
		NSLog(@"can't load Nib for Parameter View!");
		return nil;
	}

	[ui setWantsLayer:YES];
	CALayer *viewLayer = [CALayer layer];
	[ui setLayer:viewLayer];

	[paramLabel setButtonType:NSMomentaryChangeButton];


	CALayer * l = [CALayer layer];
	[l setContents: (id)[[NSImage imageNamed:@"warning@2x"] CGImageForProposedRect:Nil context:[NSGraphicsContext currentContext] hints:nil]];
	[warningSign setLayer:l];
	[warningSign setWantsLayer:YES];
	[warningSign layer].opacity = 0.0f;

	//disable implicit caAnims
	NSMutableDictionary *newActions = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
									   [NSNull null], @"onOrderIn",
									   [NSNull null], @"onOrderOut",
									   [NSNull null], @"sublayers",
									   [NSNull null], @"contents",
									   [NSNull null], @"bounds",
									   nil];
	viewLayer.actions = newActions;
	l.actions = newActions;
	[newActions release];
	return self;
}

-(void)fadeOut{
	[ui setWantsLayer:YES];
	[ui layer].opacity = 0.25;
}


-(void)fadeIn{
	[ui layer].opacity = 1;
	[ui setWantsLayer:NO];
}

-(void)fadeOutSlowly{
	[CATransaction begin];
	[CATransaction setAnimationDuration:5];
	[CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
	[warningSign layer].opacity = 0.0;
	[CATransaction commit];
}

-(NSPopUpButton*)getPresetsMenu{
	return groupPresetMenu;
}


-(void)hideWarning{
	//[CATransaction flush];
	[warningSign layer].opacity = 0.0;
	shouldBeFlashing = false;
}

-(void)flashWarning:(NSNumber *) times{

	__block int localTimes = (int)[times integerValue];
	if([times intValue] == NUM_FLASH_WARNING) shouldBeFlashing = true; //this is the 1st call, force flash
	else{	//not first call, we've been flashing for a while!
		if (shouldBeFlashing == false){
			[self hideWarning];
			return;
		}
	}
	float duration = 0.2;
	[CATransaction begin];
	[CATransaction setAnimationDuration: duration];
	[CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
		[CATransaction setCompletionBlock:^{

			[CATransaction begin];
			[CATransaction setAnimationDuration:duration];
			[CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
			[CATransaction setCompletionBlock:^{
				localTimes--;
				//NSLog(@"flash %d times", localTimes);
				if(localTimes > 0){
					[self performSelector:@selector(flashWarning:) withObject:[NSNumber numberWithInt:localTimes] afterDelay:0.2f];
				}else{ //last fadeout is really long
					[CATransaction begin];
					[CATransaction setAnimationDuration: duration];
					[warningSign layer].opacity = 1.0;
					[CATransaction commit];
					[self performSelector:@selector(fadeOutSlowly) withObject:nil afterDelay:5.0f];
					//[self performSelectorOnMainThread:@selector(fadeOutSlowly) withObject:nil waitUntilDone:NO];
				}
			}];
			[warningSign layer].opacity = 0.0;
			[CATransaction commit];
		}];
		[warningSign layer].opacity = 1.0;
	[CATransaction commit];
	//[[NSRunLoop currentRunLoop] performSelector:@selector(commit) target:[CATransaction class] argument:nil order:0 modes:[NSArray arrayWithObjects:NSDefaultRunLoopMode, NSEventTrackingRunLoopMode, nil]];
}

-(void)flashBackground:(NSNumber *) times{

	__block int localTimes = (int)[times integerValue];
	if([times intValue] == NUM_BOUND_FLASH) shouldBeFlashing = true; //this is the 1st call, force flash
	else{	//not first call, we've been flashing for a while!
		if (shouldBeFlashing == false){
			[bg setBackgroundColor:[NSColor colorWithDeviceRed: param.r/255.
														 green: param.g/255.
														  blue: param.b/255.
														 alpha: param.a/255.]];
			return;
		}
	}
	float duration = 0.1;
	[CATransaction begin];
	[CATransaction setAnimationDuration: duration];
	[CATransaction setCompletionBlock:^{

		[CATransaction begin];
		[CATransaction setAnimationDuration:duration];
		[CATransaction setCompletionBlock:^{
			localTimes--;
			if(localTimes > 0){

				[self performSelector:@selector(flashBackground:) withObject:[NSNumber numberWithInt:localTimes] afterDelay:duration];

			}else{ //last fadeout is really long
				[CATransaction begin];
				[CATransaction setAnimationDuration: duration];
				[bg setBackgroundColor:[NSColor colorWithDeviceRed: param.r/255.
															 green: param.g/255.
															  blue: param.b/255.
															 alpha: param.a/255.]];
				[CATransaction commit];
			}
		}];
		if(localTimes%2 == 1){
			[bg setBackgroundColor:[NSColor colorWithDeviceRed: param.r/255.
														 green: param.g/255.
														  blue: param.b/255.
														 alpha: 0.7]];
		}else{
			[bg setBackgroundColor:[NSColor colorWithDeviceRed: param.r/255.
														 green: param.g/255.
														  blue: param.b/255.
														 alpha: param.a/255.]];
		}
		[CATransaction commit];
	}];
	[CATransaction commit];
}

-(void)awakeFromNib{

	// create alternating row look
	if (numberID%2 == 1)
		[bg setBackgroundColor:[NSColor whiteColor]];
	else
		[bg setBackgroundColor:[NSColor colorWithDeviceRed:0.950 green:0.950 blue:1 alpha:1.000]];

	if (param.a > 0 ){
		[bg setBackgroundColor: [NSColor colorWithDeviceRed: param.r/255.
														  green: param.g/255.
														   blue: param.b/255.
														  alpha: param.a/255.]
		 ];
	}
	[self setupUI];
}


-(void)disableChanges;{
	[widget setEnabled:false];
}


-(void)enableChanges;{
	[widget setEnabled:true];
}

-(string)getParamName{
	return paramName;
}


-(void)remapSlider;{
	if ([widget isKindOfClass: [NSSlider class]]){
		NSSlider * s = (NSSlider*)widget;
		float w = [s frame].size.width;
		int numTicks = w / 7;

		RowHeightSize rowH = [(AppDelegate *)[NSApp delegate] getRowHeight];
		if(rowH == LARGE_34){
			if ([s allowsTickMarkValuesOnly]){ // for int sliders, lets make sure there arent more marks than possible values
				int range = 1 + [s maxValue] - [s minValue];
				if (numTicks > range){
					numTicks = range;
				}
			}
			[s setNumberOfTickMarks: numTicks];
		}
	}
}

-(void)waitForMIDIAnimationTrigger{
	[ui setWantsLayer:YES];
	[CATransaction begin];
	[CATransaction setAnimationDuration: 0.33];
		if([ui layer].opacity < 0.66 || !midiHighlightAnim){
			[ui layer].opacity = 1.0;
		}else{
			[ui layer].opacity = 0.33;
		}
		[CATransaction commit];
	[CATransaction commit];
	if(!midiHighlightAnim){
		[waitingForMidiTimer invalidate];
		waitingForMidiTimer = nil;
		[ui setWantsLayer:NO];
	}
}

-(void)stopMidiAnim{
	[ui setWantsLayer:NO];
	midiHighlightAnim = false;
}


-(IBAction)clickOnLabel:(id)sender;{

	if (param.type == REMOTEUI_PARAM_INT || param.type == REMOTEUI_PARAM_FLOAT ||
		param.type == REMOTEUI_PARAM_BOOL || param.type == REMOTEUI_PARAM_ENUM || param.type == REMOTEUI_PARAM_COLOR
		){
		if(!midiHighlightAnim){
			waitingForMidiTimer = [NSTimer scheduledTimerWithTimeInterval:0.33 target:self selector:@selector(waitForMIDIAnimationTrigger) userInfo:Nil repeats:YES];
			midiHighlightAnim = true;
			[self waitForMIDIAnimationTrigger];
		}else{
			midiHighlightAnim = false; //stop anim
		}
		[[[NSApp delegate] getExternalDevices] userClickedOnParamForDeviceBinding: self]; //ugly! TODO
	}
}

- (void)controlTextDidBeginEditing:(NSNotification *)obj;{}
- (void)controlTextDidEndEditing:(NSNotification *)obj;{}

- (void)controlTextDidChange:(NSNotification *)aNotification{
	[self updateString:textView]; //send an update on each typed character
}


-(void)setupUI{

	[paramLabel setAction:@selector(clickOnLabel:)];
	[paramLabel setTarget:self];
	[paramLabel setBezelStyle:NSSmallSquareBezelStyle];

	switch (param.type) {
		case REMOTEUI_PARAM_FLOAT:
			widget = slider;
			[widget setAction:@selector(updateFloat:)];
			[sliderVal setAction:@selector(updateFloatManually:)];
			[sliderVal setTarget:self];
			//[[sliderVal cell] setBackgroundStyle:NSBackgroundStyleRaised];
			[slider setMaxValue:param.maxFloat];
			[slider setMinValue:param.minFloat];
			[button removeFromSuperviewWithoutNeedingDisplay];
			[textView removeFromSuperviewWithoutNeedingDisplay];
			[slider setAllowsTickMarkValuesOnly:false];
			[enumeratorMenu removeFromSuperviewWithoutNeedingDisplay];
			[colorWell removeFromSuperviewWithoutNeedingDisplay];
			[spacerTitle removeFromSuperviewWithoutNeedingDisplay];
			[groupPresetMenu removeFromSuperviewWithoutNeedingDisplay];
			[groupPresetAddButton removeFromSuperviewWithoutNeedingDisplay];
			[groupPresetDeleteButton removeFromSuperviewWithoutNeedingDisplay];
			break;

		case REMOTEUI_PARAM_INT:
			widget = slider;
			//[[sliderVal cell] setBackgroundStyle:NSBackgroundStyleRaised];
			[slider setMaxValue:param.maxInt];
			[slider setMinValue:param.minInt];
			[sliderVal setAction:@selector(updateIntManually:)];
			[sliderVal setTarget:self];
			[slider setAllowsTickMarkValuesOnly:true];
			[widget setAction:@selector(updateInt:)];
			[button removeFromSuperviewWithoutNeedingDisplay];
			[textView removeFromSuperviewWithoutNeedingDisplay];
			[enumeratorMenu removeFromSuperviewWithoutNeedingDisplay];
			[colorWell removeFromSuperviewWithoutNeedingDisplay];
			[spacerTitle removeFromSuperviewWithoutNeedingDisplay];
			[groupPresetMenu removeFromSuperviewWithoutNeedingDisplay];
			[groupPresetAddButton removeFromSuperviewWithoutNeedingDisplay];
			[groupPresetDeleteButton removeFromSuperviewWithoutNeedingDisplay];
			break;

		case REMOTEUI_PARAM_COLOR:
			widget = colorWell;
			[widget setAction:@selector(updateColor:)];
			[button removeFromSuperviewWithoutNeedingDisplay];
			[slider removeFromSuperviewWithoutNeedingDisplay];
			[sliderMax removeFromSuperviewWithoutNeedingDisplay];
			[sliderMin removeFromSuperviewWithoutNeedingDisplay];
			[sliderVal removeFromSuperviewWithoutNeedingDisplay];
			[textView removeFromSuperviewWithoutNeedingDisplay];
			[enumeratorMenu removeFromSuperviewWithoutNeedingDisplay];
			[spacerTitle removeFromSuperviewWithoutNeedingDisplay];
			[groupPresetMenu removeFromSuperviewWithoutNeedingDisplay];
			[groupPresetAddButton removeFromSuperviewWithoutNeedingDisplay];
			[groupPresetDeleteButton removeFromSuperviewWithoutNeedingDisplay];
			break;

		case REMOTEUI_PARAM_ENUM:{
			widget = enumeratorMenu;
			[widget setAction:@selector(updateEnum:)];
			[button removeFromSuperviewWithoutNeedingDisplay];
			[slider removeFromSuperviewWithoutNeedingDisplay];
			[textView removeFromSuperviewWithoutNeedingDisplay];
			[sliderMax removeFromSuperviewWithoutNeedingDisplay];
			[sliderMin removeFromSuperviewWithoutNeedingDisplay];
			[sliderVal removeFromSuperviewWithoutNeedingDisplay];
			[colorWell removeFromSuperviewWithoutNeedingDisplay];
			[spacerTitle removeFromSuperviewWithoutNeedingDisplay];
			[groupPresetMenu removeFromSuperviewWithoutNeedingDisplay];
			[groupPresetAddButton removeFromSuperviewWithoutNeedingDisplay];
			[groupPresetDeleteButton removeFromSuperviewWithoutNeedingDisplay];
			[enumeratorMenu removeAllItems];
			for(int i = 0; i < param.enumList.size(); i++){
				[enumeratorMenu addItemWithTitle:[NSString stringWithFormat:@"%s", param.enumList[i].c_str()]];
			}
			}break;

		case REMOTEUI_PARAM_BOOL:
			widget = button;
			[button setAction:@selector(updateBool:)];
			[slider removeFromSuperviewWithoutNeedingDisplay];
			[textView removeFromSuperviewWithoutNeedingDisplay];
			[sliderMax removeFromSuperviewWithoutNeedingDisplay];
			[sliderMin removeFromSuperviewWithoutNeedingDisplay];
			[sliderVal removeFromSuperviewWithoutNeedingDisplay];
			[colorWell removeFromSuperviewWithoutNeedingDisplay];
			[enumeratorMenu removeFromSuperviewWithoutNeedingDisplay];
			[spacerTitle removeFromSuperviewWithoutNeedingDisplay];
			[groupPresetMenu removeFromSuperviewWithoutNeedingDisplay];
			[groupPresetAddButton removeFromSuperviewWithoutNeedingDisplay];
			[groupPresetDeleteButton removeFromSuperviewWithoutNeedingDisplay];
			break;

		case REMOTEUI_PARAM_STRING:
			widget = textView;
			[textView setAction:@selector(updateString:)];
			[textView setDelegate:self];
			[slider removeFromSuperviewWithoutNeedingDisplay];
			[button removeFromSuperviewWithoutNeedingDisplay];
			[sliderMax removeFromSuperviewWithoutNeedingDisplay];
			[sliderMin removeFromSuperviewWithoutNeedingDisplay];
			[sliderVal removeFromSuperviewWithoutNeedingDisplay];
			[colorWell removeFromSuperviewWithoutNeedingDisplay];
			[enumeratorMenu removeFromSuperviewWithoutNeedingDisplay];
			[spacerTitle removeFromSuperviewWithoutNeedingDisplay];
			[groupPresetMenu removeFromSuperviewWithoutNeedingDisplay];
			[groupPresetAddButton removeFromSuperviewWithoutNeedingDisplay];
			[groupPresetDeleteButton removeFromSuperviewWithoutNeedingDisplay];
			break;

		case REMOTEUI_PARAM_SPACER:
			widget = spacerTitle;
			[spacerTitle setToolTip:[self stringFromString: param.stringVal]];
			[spacerTitle setStringValue:[self stringFromString: param.stringVal]];
			[[spacerTitle cell] setBackgroundStyle:NSBackgroundStyleLowered];
			[spacerTitle setTextColor:[NSColor whiteColor]];
			[groupPresetAddButton setAction:@selector(userPressedAddGroupPreset:)];
			[groupPresetAddButton setTarget:self];
			[groupPresetDeleteButton setAction:@selector(userPressedDeleteGroupPreset:)];
			[groupPresetDeleteButton setTarget:self];
			[groupPresetMenu setAction:@selector(userChoseGroupPreset:)];
			[groupPresetMenu setTarget:self];
			[textView removeFromSuperviewWithoutNeedingDisplay];
			[slider removeFromSuperviewWithoutNeedingDisplay];
			[button removeFromSuperviewWithoutNeedingDisplay];
			[sliderMax removeFromSuperviewWithoutNeedingDisplay];
			[sliderMin removeFromSuperviewWithoutNeedingDisplay];
			[sliderVal removeFromSuperviewWithoutNeedingDisplay];
			[colorWell removeFromSuperviewWithoutNeedingDisplay];
			[enumeratorMenu removeFromSuperviewWithoutNeedingDisplay];
			[paramLabel setHidden:YES];
			break;

		default:NSLog(@"wtf is this?");
			break;
	}
	paramLabel.title = [self stringFromString:paramName];
	int t = param.type;
	if (t == REMOTEUI_PARAM_FLOAT || t == REMOTEUI_PARAM_INT || t == REMOTEUI_PARAM_BOOL || t == REMOTEUI_PARAM_ENUM ){
		[paramLabel setToolTip: [NSString stringWithFormat:@"\"%@\" Parameter\nPress Button to start controller binding process", paramLabel.title]];
	}else{
		[paramLabel setToolTip: [NSString stringWithFormat:@"\"%@\" Parameter\nNot bindable to a controller", paramLabel.title]];
	}
	[paramLabel sizeToFit];
	
	[widget setTarget:self];
}


-(void)updateParam:(RemoteUIParam)p;{
	param = p;
}


-(void)updatePresetMenuSelectionToCurrent{
	if(currentPreset == ""){
		[groupPresetMenu selectItemAtIndex:0];
	}else{
		[groupPresetMenu selectItemWithTitle:[NSString stringWithFormat:@"%s",currentPreset.c_str()]];
	}
}

-(void)resetSelectedPreset{
	[groupPresetMenu selectItemAtIndex:0];
	currentPreset = "";
}

-(IBAction)userPressedAddGroupPreset:(id)sender;{

	AppDelegate* del = (AppDelegate *)[NSApp delegate];
	NSString * msg = [NSString stringWithFormat:@"Add a Preset For the '%s' Group", param.group.c_str() ];
	NSString * newPreset = [del showAlertWithInput:msg defaultValue:@"myGroupPreset"];

	if(newPreset != nil){
		currentPreset = [newPreset UTF8String];
		[del getClient]->saveGroupPresetWithName(currentPreset, param.group);
	}
}


-(IBAction)userPressedDeleteGroupPreset:(id)sender;{

	int index = (int)[groupPresetMenu indexOfSelectedItem];
	if (index == 0) {
		NSBeep();
		return; //empty preset does nothing, cant be deleted
	}
	NSString * preset = [[groupPresetMenu itemAtIndex:index] title];
	NSLog(@"user delete group preset: %@", preset );
	AppDelegate* del = (AppDelegate *)[NSApp delegate];
	[groupPresetMenu selectItemAtIndex:index];
	[del getClient]->deleteGroupPreset([preset UTF8String], param.group);
	currentPreset = "";
}


-(IBAction)userChoseGroupPreset:(id)sender;{
	int index = (int)[sender indexOfSelectedItem];
	if (index == 0) {
		return; //empty preset does nothing
		currentPreset = "";
	}
	NSString * preset = [[sender itemAtIndex:index] title];
	[groupPresetMenu selectItemAtIndex:index];
	currentPreset = [preset UTF8String];
	AppDelegate* del = (AppDelegate *)[NSApp delegate];
	[del clearSelectionPresetMenu];
	[del getClient]->setGroupPreset(currentPreset, param.group);
	NSLog(@"user chose group preset: %s", currentPreset.c_str() );
}


-(void)updateUI{
	switch (param.type) {
		case REMOTEUI_PARAM_FLOAT:
			[slider setFloatValue:param.floatVal];
			[sliderVal setStringValue:[self formatedFloat:param.floatVal]];
			[sliderMax setStringValue:[self formatedFloat:param.maxFloat]];
			[sliderMin setStringValue:[self formatedFloat:param.minFloat]];
			break;

		case REMOTEUI_PARAM_INT:
			[slider setIntegerValue:param.intVal];
			[sliderVal setStringValue:[NSString stringWithFormat:@"%d", param.intVal ]];
			[sliderMax setStringValue:[NSString stringWithFormat:@"%d", param.maxInt ]];
			[sliderMin setStringValue:[NSString stringWithFormat:@"%d", param.minInt ]];
			break;

		case REMOTEUI_PARAM_COLOR:{
			NSColor * col = [NSColor colorWithSRGBRed:param.redVal/255. green:param.greenVal/255. blue:param.blueVal/255. alpha:param.alphaVal/255.];
			//col = [col colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
			//CGFloat comp[] = {param.redVal/255., param.greenVal/255., param.blueVal/255., param.alphaVal/255. };
			//NSColor * col = [NSColor colorWithColorSpace:[NSColorSpace sRGBColorSpace] components:comp count:4];
			col = [col colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
			[colorWell setColor:col];
			}break;

		case REMOTEUI_PARAM_ENUM:
			[enumeratorMenu selectItemAtIndex: param.intVal - param.minInt];
			break;

		case REMOTEUI_PARAM_BOOL:
			[button setState:param.boolVal];
			button.title = param.boolVal ? @"ON" : @"OFF";
			break;

		case REMOTEUI_PARAM_STRING:
			[textView setStringValue: [self stringFromString: param.stringVal]];
			//[textView setStringValue: [NSString stringWithFormat:@"%@", [NSDate date]]];
			break;
		case REMOTEUI_PARAM_SPACER:
			break;
		default:
			NSLog(@"updateUI wtf");
			break;
	}
}

-(IBAction)updateColor:(id)sender{

	NSColor * col = [sender color];
	//NSLog(@"colorSP: %@", [col colorSpaceName]);
	//col = [col colorUsingColorSpaceName:NSCalibratedRGBColorSpace device:[[NSApp mainWindow] deviceDescription]];
	//NSString*	myColorSpace = [col colorSpaceName];
	col = [col colorUsingColorSpaceName: NSCalibratedRGBColorSpace device:[[NSApp mainWindow] deviceDescription]];
	//[sender setColor:col];
	//NSColor * col2 = [col colorUsingColorSpace:[NSColorSpace sRGBColorSpace] ];
	//[sender performSelector:@selector(setColor:) withObject:col2 afterDelay:1];

	//NSLog(@"colorSP2: %@", [col colorSpaceName]);
	param.redVal = [col redComponent] * 255.0f;
	param.greenVal = [col greenComponent] * 255.0f;
	param.blueVal = [col blueComponent] * 255.0f;
	param.alphaVal = [col alphaComponent] * 255.0f;
	if ([[NSApp delegate] respondsToSelector:@selector(userChangedParam:paramName:)]){
		[[NSApp delegate] userChangedParam: param paramName: paramName];  //blindly send message to App Delegate (TODO!)
	}
}


-(NSString*)formatedFloat:(float) f;{
	NSNumber *num = [NSNumber numberWithFloat:f];
	NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
	[formatter setUsesGroupingSeparator:NO];
	[formatter setDecimalSeparator:@"."];
	[formatter setMinimumIntegerDigits:1];
	[formatter setGroupingSeparator:@"."];
	[formatter setMaximumFractionDigits:2];
	NSString *formattedNumber = [formatter stringFromNumber:num];
	[formatter release];
	return formattedNumber;
}

-(IBAction)updateIntManually:(id)sender{
	param.intVal = [sender intValue];
	[slider setIntValue:param.intVal];
	if ([[NSApp delegate] respondsToSelector:@selector(userChangedParam:paramName:)]){
		[[NSApp delegate] userChangedParam: param paramName: paramName];  //blindly send message to App Delegate (TODO!)
	}
}

-(IBAction)updateFloatManually:(id)sender{
	NSString * userTyped = [sender stringValue]; //whatever user types for input float (, or .), we convert back to "."
	userTyped = [userTyped stringByReplacingOccurrencesOfString:@"," withString:@"."];
	[sender setStringValue:userTyped];
	param.floatVal = [userTyped floatValue];
	[slider setFloatValue:param.floatVal];
	if ([[NSApp delegate] respondsToSelector:@selector(userChangedParam:paramName:)]){
		[[NSApp delegate] userChangedParam: param paramName: paramName];  //blindly send message to App Delegate (TODO!)
	}
	[[NSApp mainWindow] makeFirstResponder:nil];
}

-(IBAction)updateFloat:(id)sender{
	param.floatVal = [sender floatValue];
	[sliderVal setStringValue:[self formatedFloat:param.floatVal]];
	if ([[NSApp delegate] respondsToSelector:@selector(userChangedParam:paramName:)]){
		 [[NSApp delegate] userChangedParam: param paramName: paramName];  //blindly send message to App Delegate (TODO!)
	}
}

-(IBAction)updateEnum:(id)sender{
	int index = (int)[sender indexOfSelectedItem];
	param.intVal = param.minInt + index;
	if ([[NSApp delegate] respondsToSelector:@selector(userChangedParam:paramName:)]){
		[[NSApp delegate] userChangedParam: param paramName: paramName];  //blindly send message to App Delegate (TODO!)
	}
}

-(IBAction)updateInt:(id)sender{
	param.intVal = [sender intValue];
	[sliderVal setStringValue:[NSString stringWithFormat:@"%d", param.intVal ]];
	if ([[NSApp delegate] respondsToSelector:@selector(userChangedParam:paramName:)]){
		[[NSApp delegate] userChangedParam: param paramName: paramName];  //blindly send message to App Delegate (TODO!)
	}
}


-(IBAction)updateBool:(id)sender{
	//printf("%d\n", [sender intValue]);
	param.boolVal = [sender intValue];
	button.title = param.boolVal ? @"ON" : @"OFF";
	if ([[NSApp delegate] respondsToSelector:@selector(userChangedParam:paramName:)]){
		[[NSApp delegate] userChangedParam: param paramName: paramName];  //blindly send message to App Delegate (TODO!)
	}
}

-(IBAction)updateString:(id)sender{
	param.stringVal = string([[sender stringValue] UTF8String]);
	if ([[NSApp delegate] respondsToSelector:@selector(userChangedParam:paramName:)]){
		[[NSApp delegate] userChangedParam: param paramName: paramName];  //blindly send message to App Delegate (TODO!)
	}
}

-(NSString*)stringFromString:(string) s{
	return  [NSString stringWithCString:s.c_str() encoding:[NSString defaultCStringEncoding]];
}

@end
