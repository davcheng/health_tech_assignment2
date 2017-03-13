//
//  ViewController.h
//  AWARE
//
//  Created by David and Jill on 3/7/17.
//  Copyright © 2017 David and Jill. All rights reserved.
//


#import <UIKit/UIKit.h>
#import <MQTTKit/MQTTKit.h>
#import <CoreLocation/CoreLocation.h>
#import <SVProgressHUD.h>

#import "EAIntroView.h"
#import "AWARESensorManager.h"

 
@interface ViewController : UITableViewController <UITableViewDelegate,UITableViewDataSource, UITabBarControllerDelegate, UINavigationBarDelegate, UIAlertViewDelegate, EAIntroDelegate>

- (IBAction)pushedStudyRefreshButton:(id)sender;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *refreshButton;
- (IBAction)pushedEsmButtonOnNavigationBar:(id)sender;

@property (nonatomic,strong) NSMutableArray *sensors;
@property MQTTClient *client;

@end

