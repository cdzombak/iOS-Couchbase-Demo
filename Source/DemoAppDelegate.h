//
//  DemoAppDelegate.h
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

#import <UIKit/UIKit.h>
@class CouchDatabase, RootViewController;


@interface DemoAppDelegate : NSObject <UIApplicationDelegate, UIAlertViewDelegate>
{
    UIImageView *splashView;
    NSNetService *netService;
}

@property (nonatomic, retain) CouchDatabase *database;

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;

- (void)showAlert: (NSString*)message error: (NSError*)error fatal: (BOOL)fatal;

@end

