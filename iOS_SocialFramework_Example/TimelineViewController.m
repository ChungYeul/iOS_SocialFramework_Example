//
//  TimelineViewController.m
//  iOS_SocialFramework_Example
//
//  Created by SDT-1 on 2014. 1. 21..
//  Copyright (c) 2014년 T. All rights reserved.
//

#import "TimelineViewController.h"
#import <Social/Social.h>
#import <Accounts/Accounts.h>
#define FACEBOOK_APPID @"618091668226127"

@interface TimelineViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) ACAccount *facebookAccount;
@property (strong, nonatomic) NSArray *data;
@property (weak, nonatomic) IBOutlet UITableView *table;

@end

@implementation TimelineViewController
- (IBAction)doBack:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)showTimeline {
    ACAccountStore *store = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [store accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
    NSDictionary *options = @{ACFacebookAppIdKey:FACEBOOK_APPID,
                              ACFacebookPermissionsKey:@[@"read_stream"],
//                              ACFacebookPermissionsKey:@[@"basic_info"],
                              ACFacebookAudienceKey:ACFacebookAudienceEveryone};
    
    [store requestAccessToAccountsWithType:accountType options:options completion:^(BOOL granted, NSError *error){
        // 승인 요청 결과를 처리할 핸들러(블록)
        if (error) {
            NSLog(@"Error : %@", error);
        }
        if (granted) {
            // 승인 성공
            NSArray *accounts = [store accountsWithAccountType:accountType];
            self.facebookAccount = [accounts lastObject];
            
            [self requestFeed];
        }
        else {
            NSLog(@"권한 승인 실패");
        }
    }];
}

- (void)requestFeed {
    NSString *urlStr = @"https://graph.facebook.com/me/feed";
    NSURL *url = [NSURL URLWithString:urlStr];
    
    NSDictionary *params = nil;

    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeFacebook requestMethod:SLRequestMethodGET URL:url parameters:params];
    request.account = self.facebookAccount;
    
    [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        if (nil != error) {
            NSLog(@"Error : %@", error);
            return;
        }
        
        __autoreleasing NSError *parseError = nil;
        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&parseError];
        
        self.data = result[@"data"];
        // 메인 쓰레드에서 UI 업데이트
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self.table reloadData];
        }];
    }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.data count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FEED_CELL" forIndexPath:indexPath];
    NSDictionary *one = self.data[indexPath.row];
    
    // feed는 사용자가 올린 글에 해당하는 message 와 like등과 같은 이벤트 story로 나뉜다.
    NSString *contents;
    if (one[@"message"]) {
        // 메세지인 경우에는 like의 개수
        NSDictionary *likes = one[@"likes"];
        NSArray *data = likes[@"data"];
//        NSLog(@"message likes : %@ - %@", likes, count");
        contents = [NSString stringWithFormat:@"%@....(%d)", one[@"message"], [data count]];
    }
    else {
        contents = one[@"story"];
        cell.indentationLevel = 2;
    }
    
    cell.textLabel.text = contents;
    return cell;
}

- (void)viewWillAppear:(BOOL)animated {
    [self showTimeline];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
