//
//  ViewController.h
//  ContactDemo
//
//  Created by Rana on 4/12/16.
//  Copyright © 2016 Rana. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (nonatomic, strong) NSMutableArray *contactsArray;

- (IBAction)getContactNewFR:(id)sender;
- (IBAction)getContactOldFW:(id)sender;
- (IBAction)newViewCall:(id)sender;

@end

