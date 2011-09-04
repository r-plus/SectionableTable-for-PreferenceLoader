#import <Preferences/Preferences.h>

#define PREF_PATH @"/var/mobile/Library/Preferences/jp.r-plus.Sleipnizer.plist"
#define DATA_SOURCE_PATH @"/Library/PreferenceBundles/SleipnizerSettings.bundle/DataSource.plist"

// PSSpecifier Class Ref http://hexorcist.com/private_frameworks/html/interface_p_s_specifier.html

// RootClass

__attribute__((visibility("hidden")))
@interface RootPreferenceController : PSListController
+ (id)sharedController;
- (NSDictionary *)valuesDict;
- (NSDictionary *)titlesDict;
- (NSArray *)headers;
- (NSArray *)footers;
- (NSArray *)titlesSource:(id)target;
- (NSArray *)valuesSource:(id)target;
@end

@implementation RootPreferenceController

static RootPreferenceController *controller = nil;

+ (id)sharedController {
  return controller;
}

- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"SleipnizerforSafari" target:self] retain];
    controller = self;
	}
	return _specifiers;
}

- (void)tw:(id)tw {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/r-plus/SectionableTable-for-PreferenceLoader"]];
}

- (NSDictionary *)valuesDict {
  NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:DATA_SOURCE_PATH];
  return [dict objectForKey:@"values"];
}

- (NSDictionary *)titlesDict {
  NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:DATA_SOURCE_PATH];
  return [dict objectForKey:@"titles"];
}

- (NSArray *)headers {
  NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:DATA_SOURCE_PATH];
  return [dict objectForKey:@"sectionHeaders"];
}

- (NSArray *)footers {
  NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:DATA_SOURCE_PATH];
  return [dict objectForKey:@"sectionFooters"];
}

- (NSArray *)valuesSource:(id)target
{
  NSDictionary *dict = [self valuesDict];
  NSMutableArray *valuesArray = [NSMutableArray array];

  for (int i = 0; i < [[dict allKeys] count]; i++) {
    NSArray *sectionArray = [dict objectForKey:[NSString stringWithFormat:@"valueSection%d", i]];
    for (NSString *str in sectionArray)
      [valuesArray addObject:str];
  }
  
  return valuesArray;
}

- (NSArray *)titlesSource:(id)target
{
  NSDictionary *dict = [self titlesDict];
  NSMutableArray *titlesArray = [NSMutableArray array];
  
  for (int i = 0; i < [[dict allKeys] count]; i++) {
    NSArray *sectionArray = [dict objectForKey:[NSString stringWithFormat:@"titleSection%d", i]];
    for (NSString *str in sectionArray)
      [titlesArray addObject:str];
  }
  
  return titlesArray;
}

- (id)generalGetter:(id)specifier
{
  NSString *identifier = [specifier identifier];
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
  NSString *valueString = [dict objectForKey:identifier];
  if (valueString != nil)
    return valueString;
  else
    return [specifier propertyForKey:@"default"];
}

@end

// LicenseController

__attribute__((visibility("hidden")))
@interface SleipnizerLicenseViewController: PSListController
@end

@implementation SleipnizerLicenseViewController
- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"License" target:self] retain];
	}
	return _specifiers;
}
@end

// Protcol

@protocol GroupedListItems
- (NSString *)keyID;
@end

// SuperClass

__attribute__((visibility("hidden")))
@interface GroupedListItemsController : PSViewController <UITableViewDelegate,UITableViewDataSource,GroupedListItems> {
@private
  UITableView *_tableView;
  NSString *_navigationTitle;
}
@property (nonatomic, readonly) UITableView *tableView;
@property (nonatomic, retain) NSString *navigationTitle;

- (void)markCell:(UITableViewCell *)cell check:(BOOL)isCheck;
@end

@implementation  GroupedListItemsController

@synthesize tableView = _tableView, navigationTitle = _navigationTitle;

// for override method.
// return plist's key property. ( necessary same key and id string)
- (NSString *)keyID {
  return @"debug";
}

- (id)initForContentSize:(CGSize)size
{
	if ([[PSViewController class] instancesRespondToSelector:@selector(initForContentSize:)])
		self = [super initForContentSize:size];
	else
		self = [super init];
	if (self) {
		CGRect frame;
		frame.origin = CGPointZero;
		frame.size = size;
    // Plain or Grouped
		_tableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStyleGrouped];
		[_tableView setDataSource:self];
		[_tableView setDelegate:self];
		[_tableView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    id rpc = [RootPreferenceController sharedController];
    [self  setNavigationTitle:[[rpc specifierForID:[self keyID]] propertyForKey:@"label"]];
	}
	return self;
}

- (UIView *)view {
	return _tableView;
}

- (CGSize)contentSize {
	return [_tableView frame].size;
}

- (void)dealloc
{
	[_tableView setDelegate:nil];
	[_tableView setDataSource:nil];
	[_tableView release];
	[_navigationTitle release];
	[super dealloc];
}

- (void)setNavigationTitle:(NSString *)navigationTitle
{
	[_navigationTitle autorelease];
	_navigationTitle = [navigationTitle retain];
	if ([self respondsToSelector:@selector(navigationItem)])
		[[self navigationItem] setTitle:_navigationTitle];
}

- (void)markCell:(UITableViewCell *)cell check:(BOOL)isCheck
{
  if (isCheck) {
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    cell.textLabel.textColor = [UIColor colorWithRed:81/255.0 green:102/255.0 blue:145/255.0 alpha:1];
  } else {
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.textLabel.textColor = [UIColor blackColor];
  }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  id cell = [tableView cellForRowAtIndexPath:indexPath];

  // cell mark None/Check and Black/Blue color string
  for (UITableViewCell *otherCell in [tableView visibleCells])
    [self markCell:otherCell check:NO];
  [self markCell:cell check:YES];
  
  // Save and PostNotification
  RootPreferenceController *rpc = [RootPreferenceController sharedController];
  PSSpecifier *spec = [rpc specifierForID:[self keyID]];
  [rpc setPreferenceValue:[[[rpc valuesDict] objectForKey:[NSString stringWithFormat:@"valueSection%d", indexPath.section]] objectAtIndex:indexPath.row] specifier:spec];
  [[NSUserDefaults standardUserDefaults] synchronize];
  CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("jp.r-plus.SleipnizerforSafari.settingschanged"), NULL, NULL, true);
  
  // refresh RootView's title
  [rpc reloadSpecifier:spec];

  [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
  
  if (cell == nil) {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"] autorelease];
  }
  // Set Text
  RootPreferenceController *rpc = [RootPreferenceController sharedController];
  cell.textLabel.text = [[[rpc titlesDict] objectForKey:[NSString stringWithFormat:@"titleSection%d", indexPath.section]] objectAtIndex:indexPath.row];
  
  // cell mark None/Check and Black/Blue color string
  NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
  NSString *setedString = [dict objectForKey:[self keyID]];// e.g. (NSString *)@"0"
  if (setedString == nil)
    setedString = [[rpc specifierForID:[self keyID]] propertyForKey:@"default"];
  NSArray *values = [rpc valuesSource:nil];
  int i = 0;
  for (NSString *str in values) {
    if ([str isEqualToString:setedString])
      break;
    i++;
  }
  if ([[[rpc titlesSource:nil] objectAtIndex:i] isEqualToString:cell.textLabel.text])
    [self markCell:cell check:YES];
  else
    [self markCell:cell check:NO];

  return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
  id rpc = [RootPreferenceController sharedController];
  NSArray *headers = [rpc headers];
  return [headers objectAtIndex:section];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
  id rpc = [RootPreferenceController sharedController];
  NSArray *footers = [rpc footers];
  return [footers objectAtIndex:section];
}

- (int)numberOfSectionsInTableView:(UITableView *)tableView {
  id rpc = [RootPreferenceController sharedController];
  NSDictionary *dict = [rpc valuesDict];
	return [[dict allKeys] count];
}

- (int)tableView:(UITableView *)tableView numberOfRowsInSection:(int)section
{
  id rpc = [RootPreferenceController sharedController];
  NSDictionary *dict = [rpc valuesDict];
  return [[dict objectForKey:[NSString stringWithFormat:@"valueSection%d", section]] count];
}

@end

// necesary same 'id' and 'key' property.
@interface ULActionController : GroupedListItemsController <GroupedListItems>
@end
@implementation ULActionController
- (NSString *)keyID { return @"ULAction"; }
@end

@interface URActionController : GroupedListItemsController <GroupedListItems>
@end
@implementation URActionController
- (NSString *)keyID { return @"URAction"; }
@end

@interface DLActionController : GroupedListItemsController <GroupedListItems>
@end
@implementation DLActionController
- (NSString *)keyID { return @"DLAction"; }
@end

@interface DRActionController : GroupedListItemsController <GroupedListItems>
@end
@implementation DRActionController
- (NSString *)keyID { return @"DRAction"; }
@end

@interface ULDActionController : GroupedListItemsController <GroupedListItems>
@end
@implementation ULDActionController
- (NSString *)keyID { return @"ULDAction"; }
@end

@interface URDActionController : GroupedListItemsController <GroupedListItems>
@end
@implementation URDActionController
- (NSString *)keyID { return @"URDAction"; }
@end

@interface DLUActionController : GroupedListItemsController <GroupedListItems>
@end
@implementation DLUActionController
- (NSString *)keyID { return @"DLUAction"; }
@end

@interface DRUActionController : GroupedListItemsController <GroupedListItems>
@end
@implementation DRUActionController
- (NSString *)keyID { return @"DRUAction"; }
@end

@interface UDActionController : GroupedListItemsController <GroupedListItems>
@end
@implementation UDActionController
- (NSString *)keyID { return @"UDAction"; }
@end

@interface DUActionController : GroupedListItemsController <GroupedListItems>
@end
@implementation DUActionController
- (NSString *)keyID { return @"DUAction"; }
@end

