//
//  ViewController.m
//  iOS_SocialFramework_Example
//
//  Created by SDT-1 on 2014. 1. 21..
//  Copyright (c) 2014년 T. All rights reserved.
//

#import "ViewController.h"
#import <Accounts/Accounts.h>
#import <Social/Social.h>
#define FACEBOOK_APPID @"618091668226127"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *genderLabel;
@property (weak, nonatomic) IBOutlet UITextView *aboutView;
@property (weak, nonatomic) IBOutlet UIImageView *profileImage;
@property (weak, nonatomic) IBOutlet UILabel *linkLabel;
@property (weak, nonatomic) IBOutlet UILabel *updateLabel;

@property (strong, nonatomic) ACAccount *facebookAccount;
@end

@implementation ViewController
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self showMyProfile];
}

- (void)showMyProfile {
    // 계정 정보를 담은 스토어 객체 형성
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    
    // 페이스북의 계정 타입
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
    
    // 앱 아이디와 권한 지정
    NSDictionary *options = @{ACFacebookAppIdKey:FACEBOOK_APPID,
                              ACFacebookPermissionsKey:@[@"user_about_me"],
//                              ACFacebookPermissionsKey:@[@"basic_info"],
                              ACFacebookAudienceKey:ACFacebookAudienceEveryone};
    
    //계정과 권한에 대한 승인 요청
    [accountStore requestAccessToAccountsWithType:accountType options:options completion:^(BOOL granted, NSError *error){
        // 승인 요청 결과를 처리할 핸들러(블록)
        if (granted) {
            // 승인 성공
            NSArray *accounts = [accountStore accountsWithAccountType:accountType];
            self.facebookAccount = [accounts lastObject];
            
            [self requestProfile];
        }
        else {
            // 승인 실패
            NSLog(@"승인 실패 : %@", error);
        }
    }];
}

- (void)requestProfile {
    // 페이스북 서비스 타입 지정
    NSString *serviceType = SLServiceTypeFacebook;
    // 정보를 얻어오기 위한 GET
    SLRequestMethod method = SLRequestMethodGET;
    // 그래프 API를 적용한 URL
    NSURL *url  = [NSURL URLWithString:@"https://graph.facebook.com/me"];
    // 파라미터
    NSDictionary *param = @{@"fields": @"picture,name,about,gender,link,updated_time"};
    SLRequest *request = [SLRequest requestForServiceType:serviceType requestMethod:method URL:url parameters:param];
    request.account = self.facebookAccount;
    
    // 페이스북 서비스에 요청을 수행한다. 핸들러를 이용해서 요청의 결과를 처리한다ㅏ.
    [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        if (nil != error) {
            NSLog(@"프로필 정보 얻기 실패 : %@", error);
        }
        // 요청 결과를 처리하기 위한 코드 작성
        __autoreleasing NSError *parseError = nil;
        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&parseError];
        
        NSDictionary *picture = result[@"picture"][@"data"];
        NSString *imageUrlStr = picture[@"url"];
        
        NSURL *url = [NSURL URLWithString:imageUrlStr];
        NSData *data = [NSData dataWithContentsOfURL:url];
        UIImage *image = [UIImage imageWithData:data];
        
        // 메인 쓰레드에서 UI 업데이트
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            self.nameLabel.text = result[@"name"];
            self.aboutView.text = result[@"about"];
            self.genderLabel.text = result[@"gender"];
            self.updateLabel.text = result[@"updated_time"];
            self.linkLabel.text = result[@"link"];
            self.profileImage.image = image;
        }];
    }];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
