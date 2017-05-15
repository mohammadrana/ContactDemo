//
//  ViewController.m
//  ContactDemo
//
//  Created by Rana on 4/12/16.
//  Copyright © 2016 Rana. All rights reserved.
//

#import "ViewController.h"

#import <AddressBook/ABAddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

#import <Contacts/Contacts.h>
#import <ContactsUI/ContactsUI.h>

#import "NewViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// Get the contacts.
- (IBAction)getContactNewFR:(id)sender {
    self.contactsArray = [[NSMutableArray alloc] init];
    
    //ios 9+
    CNContactStore *store = [[CNContactStore alloc] init];
    [store requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error) {
        if (granted == YES) {
            //keys with fetching properties
            NSArray *keys = @[CNContactFamilyNameKey, CNContactGivenNameKey, CNContactPhoneNumbersKey, CNContactImageDataKey];
            NSString *containerId = store.defaultContainerIdentifier;
            NSPredicate *predicate = [CNContact predicateForContactsInContainerWithIdentifier:containerId];
            NSError *error;
            NSArray *cnContacts = [store unifiedContactsMatchingPredicate:predicate keysToFetch:keys error:&error];
            if (error) {
                NSLog(@"error fetching contacts %@", error);
            } else {
                NSString *phone;
                NSString *fullName;
                NSString *firstName;
                NSString *lastName;
                UIImage *profileImage;
                NSMutableArray *contactNumbersArray;
                NSMutableDictionary *personDict;
                
                for (CNContact *contact in cnContacts) {
                    personDict = [[NSMutableDictionary alloc] init];
                    
                    // copy data to my custom Contacts class.
                    firstName = contact.givenName;
                    lastName = contact.familyName;
                    if (lastName == nil) {
                        fullName=[NSString stringWithFormat:@"%@",firstName];
                    }else if (firstName == nil){
                        fullName=[NSString stringWithFormat:@"%@",lastName];
                    }
                    else{
                        fullName=[NSString stringWithFormat:@"%@ %@",firstName,lastName];
                    }
                    [personDict setValue:fullName forKey:@"fullName"];
                    
                    UIImage *image = [UIImage imageWithData:contact.imageData];
                    if (image != nil) {
                        profileImage = image;
                    }else{
                        profileImage = [UIImage imageNamed:@"person-icon.png"];
                    }
                    [personDict setValue:profileImage forKey:@"userImage"];
                    
                    for (CNLabeledValue *label in contact.phoneNumbers) {
                        phone = [label.value stringValue];
                        if ([phone length] > 0) {
                            [contactNumbersArray addObject:phone];
                            [personDict setValue:phone forKey:@"PhoneNumbers"];
                        }
                        NSLog(@"phone: %@", phone);
                    }
                    
                    //NSDictionary* personDict = [[NSDictionary alloc] initWithObjectsAndKeys: fullName,@"fullName",profileImage,@"userImage",phone,@"PhoneNumbers", nil];
                    NSLog(@"personDict  %@", personDict);
                    [self.contactsArray addObject:personDict];
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [self showResult];
                });
            }
        }
    }];
    
    
}

- (void)showResult{
    NSLog(@"Get Result successfully.");
     //NSLog(@"ContactsArray new %@", self.contactsArray);
}

- (IBAction)getContactOldFW:(id)sender {
    self.contactsArray = [[NSMutableArray alloc] init];
    
    ABAddressBookRef addressBook = ABAddressBookCreate();
    
    __block BOOL accessGranted = NO;
    
    if (&ABAddressBookRequestAccessWithCompletion != NULL) { // We are on iOS 6
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
            accessGranted = granted;
            dispatch_semaphore_signal(semaphore);
        });
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    }
    
    else { // We are on iOS 5 or Older
        accessGranted = YES;
        [self getContactsWithAddressBook:addressBook];
    }
    
    if (accessGranted) {
        [self getContactsWithAddressBook:addressBook];
    }
}

- (IBAction)newViewCall:(id)sender {
    NSLog(@"newViewCall " );
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    NewViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"newViewController"];
    vc.getList = self.contactsArray;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)getContactsWithAddressBook:(ABAddressBookRef )addressBook {
    CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeople(addressBook);
    CFIndex nPeople = ABAddressBookGetPersonCount(addressBook);
    
    for (int i=0;i < nPeople;i++) {
        NSMutableDictionary *dOfPerson=[NSMutableDictionary dictionary];
        
        ABRecordRef ref = CFArrayGetValueAtIndex(allPeople,i);
        
        //For username and surname
        ABMultiValueRef phones =(__bridge ABMultiValueRef)((__bridge NSString*)ABRecordCopyValue(ref, kABPersonPhoneProperty));
        
        CFStringRef firstName, lastName;
        firstName = ABRecordCopyValue(ref, kABPersonFirstNameProperty);
        lastName  = ABRecordCopyValue(ref, kABPersonLastNameProperty);
        [dOfPerson setObject:[NSString stringWithFormat:@"%@ %@", firstName, lastName] forKey:@"name"];
        
        //For Email ids
        ABMutableMultiValueRef eMail  = ABRecordCopyValue(ref, kABPersonEmailProperty);
        if(ABMultiValueGetCount(eMail) > 0) {
            [dOfPerson setObject:(__bridge NSString *)ABMultiValueCopyValueAtIndex(eMail, 0) forKey:@"email"];
        }
        
        //For Phone number
        NSString* mobileLabel;
        
        for(CFIndex i = 0; i < ABMultiValueGetCount(phones); i++) {
            mobileLabel = (__bridge NSString*)ABMultiValueCopyLabelAtIndex(phones, i);
            if([mobileLabel isEqualToString:(NSString *)kABPersonPhoneMobileLabel])
            {
                [dOfPerson setObject:(__bridge NSString*)ABMultiValueCopyValueAtIndex(phones, i) forKey:@"Phone"];
            }
            else if ([mobileLabel isEqualToString:(NSString*)kABPersonPhoneIPhoneLabel])
            {
                [dOfPerson setObject:(__bridge NSString*)ABMultiValueCopyValueAtIndex(phones, i) forKey:@"Phone"];
                break ;
            }
            
        }
        [self.contactsArray addObject:dOfPerson];
        
    }
    NSLog(@"ContactsArray old = %@", self.contactsArray);
}

@end
