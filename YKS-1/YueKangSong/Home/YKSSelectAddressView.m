//
//  YKSTestView.m
//  YueKangSong
//
//  Created by gongliang on 15/5/22.
//  Copyright (c) 2015年 YKS. All rights reserved.
//

#import "YKSSelectAddressView.h"
#import "YKSConstants.h"
#import "YKSSelectAddressListCell.h"

@interface YKSSelectAddressView() <UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *subAddressViewHeight;
@property (strong, nonatomic) void(^callback)(NSDictionary *dic, BOOL isCreate);

@end

@implementation YKSSelectAddressView

- (void)awakeFromNib {
    self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    self.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCRENN_HEIGHT);
    [self.createButton setTitleColor:kNavigationBar_back_color forState:UIControlStateNormal];
    [self.tableView registerNib:[UINib nibWithNibName:@"YKSSelectAddressListCell" bundle:nil]
         forCellReuseIdentifier:@"YKSSelectAddressListCell"];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideView)];
    tap.delegate = self;
    [self addGestureRecognizer:tap];
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([touch.view isDescendantOfView:self.tableView]) {
        return NO;
    }
    return YES;
}

- (void)hideView {
    [self removeFromSuperview];
    if (_removeViewCallBack) {
        _removeViewCallBack();
    }
}

+ (instancetype)showAddressViewToView:(UIView *)view
                                datas:(NSArray *)datas
                             callback:(void(^)(NSDictionary *info, BOOL isCreate))callback {
    YKSSelectAddressView *addressView = [[[NSBundle mainBundle] loadNibNamed:@"YKSSelectAddressView"
                                                                       owner:self
                                                                     options:nil] firstObject];
    [view addSubview:addressView];
    addressView.callback = callback;
    addressView.datas = [datas mutableCopy];
    return addressView;
    
}

- (void)reloadData {
    _subAddressViewHeight.constant += 60 * (_datas.count - 1);
    [self.tableView reloadData];
}

- (IBAction)createAction:(id)sender {
    if (_callback) {
        [self removeFromSuperview];
        _callback(nil, YES);
    }
}





#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _datas.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    YKSSelectAddressListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"YKSSelectAddressListCell"];
    NSDictionary *dic = _datas[indexPath.row];
    if (indexPath.row == 0) {
        cell.logoImageView.image = [UIImage imageNamed:@"location_icon"];
    } else {
        cell.logoImageView.image = nil;
    }
    cell.nameLabel.text = dic[@"express_username"];
    cell.phoneLabel.text = dic[@"express_mobilephone"];
    if (dic[@"community"]) {
        cell.contentLabel.text = [NSString stringWithFormat:@"%@%@", dic[@"community"], dic[@"express_detail_address"]];
    } else {
        cell.contentLabel.text = dic[@"express_detail_address"];
    }
    return cell;
}

#pragma mark - UITableViewDataSoure 
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_callback) {
        [self removeFromSuperview];
        BOOL isCreate = NO;
        if (indexPath.row == 0) {
            if (!_datas[0][@"id"]) {
                isCreate = YES;
            }
        }
        _callback(_datas[indexPath.row], isCreate);
    }
}

@end