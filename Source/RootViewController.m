//
//  RootViewController.m
//  Couchbase Mobile
//
//  Created by Jan Lehnardt on 27/11/2010.
//  Copyright 2011 Couchbase, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License"); you may not
// use this file except in compliance with the License. You may obtain a copy of
// the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations under
// the License.
//

#import "RootViewController.h"
#import <CouchCocoa/CouchCocoa.h>
#import <CouchCocoa/RESTBody.h>
#import <Couchbase/CouchbaseEmbeddedServer.h>


@implementation RootViewController


@synthesize items;
@synthesize activityButtonItem;
@synthesize activity;
@synthesize database;
@synthesize tableView;


#pragma mark -
#pragma mark View lifecycle


-(void)couchbaseDidStart:(NSURL *)serverURL {
#if 1    // Change to "0" to run with Couchbase Single on your local workstation (simulator only)
    CouchServer *server = [[CouchServer alloc] initWithURL: serverURL];
#else
    CouchServer *server = [[CouchServer alloc] init];
#endif
    self.database = [[server databaseNamed: @"grocery-sync"] retain];
    self.database.tracksChanges = YES;
    [server release];

    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(loadItemsDueToChanges:)
                                                 name: kCouchDatabaseChangeNotification
                                               object: database];

    [self loadItemsIntoView];
    [self setupSync];
    self.navigationItem.leftBarButtonItem.enabled = YES;
}


- (void)viewDidLoad {
    [super viewDidLoad];

    // start the Couchbase Server
    NSString* dbPath = [[NSBundle mainBundle] pathForResource: @"grocery-sync" ofType: @"couch"];
    NSAssert(dbPath, @"Couldn't find grocery-sync.couch");

    CouchbaseEmbeddedServer* cb = [[CouchbaseEmbeddedServer alloc] init];
    cb.delegate = self;
    [cb installDefaultDatabase: dbPath];
    if (![cb start]) {
        NSLog(@"OMG: Couchbase couldn't start! Exiting! Error = %@", cb.error);
        exit(1);    // Panic!
    }

    self.activity = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite] autorelease];
    [self.activity startAnimating];
    self.activityButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:activity] autorelease];
    self.activityButtonItem.enabled = NO;
    self.navigationItem.rightBarButtonItem = activityButtonItem;

    [self.tableView setBackgroundView:nil];
    [self.tableView setBackgroundColor:[UIColor clearColor]];
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        [addItemBackground setFrame:CGRectMake(45, 8, 680, 44)];
        [addItemTextField setFrame:CGRectMake(56, 8, 665, 43)];
    }
}


- (void)dealloc {
    [items release];
    [database release];
    [super dealloc];
}


-(void)setupSync
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *syncpoint = [defaults objectForKey:@"syncpoint"];
    NSURL *remoteURL = [NSURL URLWithString:syncpoint];

    RESTOperation *pull = [database pullFromDatabaseAtURL: remoteURL
                                                  options: kCouchReplicationContinuous];
    [pull onCompletion:^() {
        if (pull.isSuccessful)
            NSLog(@"continous sync triggered from %@", syncpoint);
        else
            NSLog(@"continuous sync failed from %@: %@", syncpoint, pull.error);
	}];

    RESTOperation *push = [database pushToDatabaseAtURL: remoteURL
                                                options: kCouchReplicationContinuous];
    [push onCompletion:^() {
        if (push.isSuccessful)
            NSLog(@"continous sync triggered to %@", syncpoint);
        else
            NSLog(@"continuous sync failed to %@: %@", syncpoint, push.error);
	}];
}


-(void)loadItemsDueToChanges:(NSNotification*)notification {
    NSLog(@"loadItemsDueToChanges");
    [self refreshItems];
    [self.tableView reloadData];
}


-(void)loadItemsIntoView {
    [self refreshItems];
    [self.tableView reloadData];
}


-(void) refreshItems {
    [self.activity startAnimating];
    CouchQuery *allDocs = [database getAllDocuments];
    allDocs.descending = YES;   // Sort by descending ID, which will imply descending create time
    self.items = allDocs.rows;
    [self.activity stopAnimating];
}


-(void)newItemAdded {
	[self loadItemsIntoView];
}


#pragma mark -
#pragma mark Table view data source


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.items count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell;

    cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"ListItem" owner:self options:nil];
        cell = [topLevelObjects objectAtIndex:0];
        UIImageView *backgroundImage = (UIImageView*)[cell viewWithTag:1];
        UIImageView *listBorder = (UIImageView*)[cell viewWithTag:4];

        if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            [backgroundImage setImage:[UIImage imageNamed:@"list_area___background___middle~ipad.png"]];
            [backgroundImage setFrame:CGRectMake(backgroundImage.frame.origin.x, backgroundImage.frame.origin.y, 681, 53)];
            [listBorder setFrame:CGRectMake(listBorder.frame.origin.x, listBorder.frame.origin.y, 678, 2)];
        }

        if (indexPath.row == 0) {

            if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
            {
                [backgroundImage setImage:[UIImage imageNamed:@"list_area___background___top.png"]];
            }
            else
            {
                [backgroundImage setImage:[UIImage imageNamed:@"list_area___background___top~ipad.png"]];
                [backgroundImage setFrame:CGRectMake(backgroundImage.frame.origin.x, backgroundImage.frame.origin.y, 681, 53)];
            }
        }
        if (indexPath.row == [self.items count]-1) {
            UIImageView *backgroundImage = (UIImageView*)[cell viewWithTag:1];
            if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
            {
                [backgroundImage setImage:[UIImage imageNamed:@"list_area___background___bottom.png"]];
            }
            else
            {
                [backgroundImage setImage:[UIImage imageNamed:@"list_area___background___bottom~ipad.png"]];
                [backgroundImage setFrame:CGRectMake(backgroundImage.frame.origin.x, backgroundImage.frame.origin.y, 681, 53)];
            }
            UIImageView *line_doted = (UIImageView*)[cell viewWithTag:4];
            [line_doted setAlpha:0];
        }

    }

    // Configure the cell.
    CouchQueryRow *row = [self.items rowAtIndex:indexPath.row];
    UIImageView *checkBoxImageView = (UIImageView*)[cell viewWithTag:3];

    UILabel *labelWIthText = (UILabel*)[cell viewWithTag:2];
    labelWIthText.text = [row.documentProperties valueForKey:@"text"];

    if ([[row.documentProperties valueForKey:@"check"] boolValue]) {
        [checkBoxImageView setImage:[UIImage imageNamed:@"list_area___checkbox___checked"]];
        [checkBoxImageView setFrame:CGRectMake(14, 9, 32, 29)];
        labelWIthText.textColor = [UIColor grayColor];
    } else {
        [checkBoxImageView setImage:[UIImage imageNamed:@"list_area___checkbox___unchecked"]];
        [checkBoxImageView setFrame:CGRectMake(14, 13, 24, 25)];
        labelWIthText.textColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:1];
    };

    return cell;
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {

    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source.
        RESTOperation* op = [[[items rowAtIndex:indexPath.row] document] DELETE];
        [op onCompletion: ^{
            [self refreshItems]; // BLOCKING
            // TODO return to the smooth style of deletion (eg animate the delete before the server responds...)
            //		[items removeRowAtIndex: position];
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }];
        [op start];
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}


#pragma mark -
#pragma mark Table view delegate


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    CouchQueryRow *row = [self.items rowAtIndex:indexPath.row];
    CouchDocument *doc = [row document];

    // Toggle the document's 'checked' property:
    NSMutableDictionary *docContent = [[row.documentProperties mutableCopy] autorelease];
    BOOL wasChecked = [[docContent valueForKey:@"check"] boolValue];
    [docContent setObject:[NSNumber numberWithBool:!wasChecked] forKey:@"check"];

    // Save changes, asynchronously:
    RESTOperation* op = [doc putProperties:docContent];
    [op onCompletion: ^{
        if (op.error)
            NSLog(@"error updating doc %@", [op.error description]);
        else
            NSLog(@"updated doc! %@", [op description]);
        [self loadItemsIntoView];
    }];
    [op start];
}


#pragma mark -
#pragma mark UITextField delegate


- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
    [addItemBackground setImage:[UIImage imageNamed:@"textfield___inactive.png"]];

	return YES;
}


- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [addItemBackground setImage:[UIImage imageNamed:@"textfield___active.png"]];
}


-(void)textFieldDidEndEditing:(UITextField *)textField
{
    // Get the name of the item from the text field:
	NSString *text = addItemTextField.text;
    if (text.length == 0) {
        return;
    }
    [addItemTextField setText:nil];

    // Construct a unique document ID that will sort chronologically:
    CFUUIDRef uuid = CFUUIDCreate(nil);
    NSString *guid = (NSString*)CFUUIDCreateString(nil, uuid);
    CFRelease(uuid);
	NSString *docId = [NSString stringWithFormat:@"%f-%@", CFAbsoluteTimeGetCurrent(), guid];
    [guid release];

    // Create the new document's properties:
	NSDictionary *inDocument = [NSDictionary dictionaryWithObjectsAndKeys:text, @"text"
                                , [NSNumber numberWithBool:NO], @"check"
                                , [[NSDate date] description], @"created_at"
                                , nil];

    // Save the document, asynchronously:
    CouchDocument* doc = [[self getDatabase] documentWithID: docId];
    RESTOperation* op = [doc putProperties:inDocument];
    [op onCompletion: ^{
        if (op.error)
            NSLog(@"error saving doc %@", [op.error description]);
        else
            NSLog(@"saved doc! %@", [op description]);
		[self newItemAdded];
	}];
    [op start];
}


@end
