//
//  ViewController.m
//  RCNSOperationDemo
//
//  Created by RongCheng on 2019/3/7.
//  Copyright © 2019年 RongCheng. All rights reserved.
//

#import "ViewController.h"
#import "RCOperation.h"
@interface ViewController ()
/** 队列 */
@property (nonatomic, strong) NSOperationQueue *queue;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@end

@implementation ViewController

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self downloadImage];
}
#pragma mark ------- 下载图片，绘制 -----------------
- (void)downloadImage{
    
    __block UIImage *image1;
    __block UIImage *image2;
    
    //1.创建队列
    NSOperationQueue *queue = [[NSOperationQueue alloc]init];
    
    //2.封装操作下载图片1
    NSBlockOperation *op1 = [NSBlockOperation blockOperationWithBlock:^{
        
        NSURL *url = [NSURL URLWithString:@"https://ss3.bdstatic.com/70cFv8Sh_Q1YnxGkpoWK1HF6hhy/it/u=1907928680,2774802011&fm=26&gp=0.jpg"];
        NSData *data = [NSData dataWithContentsOfURL:url];
        
        //拿到图片数据
        image1 = [UIImage imageWithData:data];
    }];
    
    
    //3.封装操作下载图片2
    NSBlockOperation *op2 = [NSBlockOperation blockOperationWithBlock:^{
        NSURL *url = [NSURL URLWithString:@"https://ss3.bdstatic.com/70cFv8Sh_Q1YnxGkpoWK1HF6hhy/it/u=1412439743,1735171648&fm=26&gp=0.jpg"];
        NSData *data = [NSData dataWithContentsOfURL:url];
        
        //拿到图片数据
        image2 = [UIImage imageWithData:data];
    }];
    
    //4.合成图片
    NSBlockOperation *drawOp = [NSBlockOperation blockOperationWithBlock:^{
        
        //4.1 开启图形上下文
        UIGraphicsBeginImageContext(CGSizeMake(200, 200));
        
        //4.2 画image1
        [image1 drawInRect:CGRectMake(0, 0, 200, 100)];
        
        //4.3 画image2
        [image2 drawInRect:CGRectMake(0, 100, 200, 100)];
        
        //4.4 根据图形上下文拿到图片数据
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        //        NSLog(@"%@",image);
        
        //4.5 关闭图形上下文
        UIGraphicsEndImageContext();
        
        //7.回到主线程刷新UI
        [[NSOperationQueue mainQueue]addOperationWithBlock:^{
            self.imageView.image = image;
            NSLog(@"刷新UI---%@",[NSThread currentThread]);
        }];
        
    }];
    
    //5.设置操作依赖
    [drawOp addDependency:op1];
    [drawOp addDependency:op2];
    
    //6.添加操作到队列中执行
    [queue addOperation:op1];
    [queue addOperation:op2];
    [queue addOperation:drawOp];
}
#pragma mark ------- 添加操作依赖和监听 -----------------
- (void)dependencyTest{
    //1.创建队列
    NSOperationQueue *queue = [[NSOperationQueue alloc]init];
    NSOperationQueue *queue2 = [[NSOperationQueue alloc]init];
    
    //2.封装操作
    NSBlockOperation *op1 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"1---%@",[NSThread currentThread]);
    }];
    
    NSBlockOperation *op2 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"2---%@",[NSThread currentThread]);
    }];
    
    NSBlockOperation *op3 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"3---%@",[NSThread currentThread]);
    }];
    
    //操作监听
    op3.completionBlock = ^{
        NSLog(@"3已经执行完了------%@",[NSThread currentThread]);
    };
    
    //添加操作依赖
    [op1 addDependency:op3]; //跨队列依赖,op1属于queue，op3属于queue2
    [op2 addDependency:op1];
    
    //添加操作到队列
    [queue addOperation:op1];
    [queue addOperation:op2];
    [queue2 addOperation:op3];
}

#pragma mark ------- 队列的暂停和恢复以及取消 -----------------

- (IBAction)startBtnClick:(id)sender{
    //1.创建队列
    //默认是并发队列
    self.queue = [[NSOperationQueue alloc]init];
    
    //2.设置最大并发数量 maxConcurrentOperationCount
    self.queue.maxConcurrentOperationCount = 1;
    
    RCOperation *op = [[RCOperation alloc]init];
    
    //4.添加到队列
    [self.queue addOperation:op];
}

- (IBAction)suspendBtnClick:(id)sender{
    //设置暂停和恢复
    //suspended设置为YES表示暂停，suspended设置为NO表示恢复
    //暂停表示不继续执行队列中的下一个任务，暂停操作是可以恢复的
    /*
     队列中的任务也是有状态的:已经执行完毕的 | 正在执行 | 排队等待状态
     */
    //不能暂停当前正在处于执行状态的任务
    [self.queue setSuspended:YES];
}

- (IBAction)goOnBtnClick:(id)sender{
    //继续执行
    [self.queue setSuspended:NO];
}

- (IBAction)cancelBtnClick:(id)sender{
    //取消队列里面的所有操作
    //取消之后，当前正在执行的操作的下一个操作将不再执行，而且永远都不在执行，就像后面的所有任务都从队列里面移除了一样
    //取消操作是不可以恢复的
    //该方法内部调用了所有操作的cancel方法
    [self.queue cancelAllOperations];
}
#pragma mark ------- 设置最大并发数 -----------------
-(void)maxConcurrentTest {
    //1.创建队列
    //默认是并发队列
    NSOperationQueue *queue = [[NSOperationQueue alloc]init];
    
    //2.设置最大并发数量 maxConcurrentOperationCount
    /*
     同一时间最多有多少个任务可以执行
     串行执行任务!=只开一条线程 (线程同步)
     maxConcurrentOperationCount >1 那么就是并发队列
     maxConcurrentOperationCount == 1 那就是串行队列
     maxConcurrentOperationCount == 0  不会执行任务
     maxConcurrentOperationCount == -1 特殊意义 最大值 表示不受限制
     */
    queue.maxConcurrentOperationCount = 1;
    
    //3.封装操作
    NSBlockOperation *op1 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"1----%@",[NSThread currentThread]);
    }];
    
    NSBlockOperation *op2 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"2----%@",[NSThread currentThread]);
    }];
    
    NSBlockOperation *op3 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"3----%@",[NSThread currentThread]);
    }];
    
    NSBlockOperation *op4 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"4----%@",[NSThread currentThread]);
    }];
    
    //4.添加到队列
    [queue addOperation:op1];
    [queue addOperation:op2];
    [queue addOperation:op3];
    [queue addOperation:op4];
}

#pragma mark ------- 3种子类配合队列queue使用 -----------------
- (void)invocationOperationWithQueue {
    //1.创建操作,封装任务
    NSInvocationOperation *op1 = [[NSInvocationOperation alloc]initWithTarget:self selector:@selector(operation1) object:nil];
    NSInvocationOperation *op2 = [[NSInvocationOperation alloc]initWithTarget:self selector:@selector(operation2) object:nil];
    NSInvocationOperation *op3 = [[NSInvocationOperation alloc]initWithTarget:self selector:@selector(operation3) object:nil];
    
    //2.创建队列
    /*
     GCD:
     串行类型:create & 主队列
     并发类型:create & 全局并发队列
     NSOperation:
     主队列:   [NSOperationQueue mainQueue] 和GCD中的主队列一样,串行队列
     非主队列: [[NSOperationQueue alloc]init]  非常特殊(同时具备并发和串行的功能)
     //默认情况下,非主队列是并发队列
     */
    NSOperationQueue *queue = [[NSOperationQueue alloc]init];
    
    //3.添加操作到队列中，addOperation方法内部已经调用了[op1 start]，不需要再手动启动
    [queue addOperation:op1];
    [queue addOperation:op2];
    [queue addOperation:op3];
}

- (void)blockOperationWithQueue {
    //1.创建操作
    NSBlockOperation *op1 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"1----%@",[NSThread currentThread]);
    }];
    NSBlockOperation *op2 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"2----%@",[NSThread currentThread]);
    }];
    NSBlockOperation *op3 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"3----%@",[NSThread currentThread]);
    }];
    //追加任务
    [op2 addExecutionBlock:^{
        NSLog(@"4----%@",[NSThread currentThread]);
    }];
    [op2 addExecutionBlock:^{
        NSLog(@"5----%@",[NSThread currentThread]);
    }];
    [op2 addExecutionBlock:^{
        NSLog(@"6----%@",[NSThread currentThread]);
    }];
    
    //2.创建队列
    NSOperationQueue *queue = [[NSOperationQueue alloc]init];
    
    //3.添加操作到队列
    [queue addOperation:op1];
    [queue addOperation:op2];
    [queue addOperation:op3];
    
    
    //提供一个简便方法，使用Block直接添加任务
    //1)创建操作,2)添加操作到队列中
    [queue addOperationWithBlock:^{
        NSLog(@"7----%@",[NSThread currentThread]);
    }];
}

- (void)customWithQueue{
    //1.封装操作
    RCOperation *op1 = [[RCOperation alloc]init];
    RCOperation *op2 = [[RCOperation alloc]init];
    
    //2.创建队列
    NSOperationQueue *queue = [[NSOperationQueue alloc]init];
    
    //3.添加操作到队列
    [queue addOperation:op1];
    [queue addOperation:op2];
}

#pragma mark ------- 3种子类使用 -----------------
-(void)invocationOpeation{
    
    //1.创建操作,封装任务
    /*
     第一个参数:目标对象 self
     第二个参数:调用方法的名称
     第三个参数:前面方法需要接受的参数 nil
     */
    NSInvocationOperation *op1 = [[NSInvocationOperation alloc]initWithTarget:self selector:@selector(operation1) object:nil];
    NSInvocationOperation *op2 = [[NSInvocationOperation alloc]initWithTarget:self selector:@selector(operation2) object:nil];
    NSInvocationOperation *op3 = [[NSInvocationOperation alloc]initWithTarget:self selector:@selector(operation3) object:nil];
    
    
    //2.启动|执行操作
    [op1 start];
    [op2 start];
    [op3 start];
}


- (void)blockOperation{
    //1.创建操作
    NSBlockOperation *op1 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"1----%@",[NSThread currentThread]);
    }];
    NSBlockOperation *op2 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"2----%@",[NSThread currentThread]);
    }];
    NSBlockOperation *op3 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"3----%@",[NSThread currentThread]);
    }];
    
    //追加任务
    //注意:如果一个操作中的任务数量大于1,那么会开子线程并发执行任务
    //注意:不一定是子线程,有可能是主线程
    [op3 addExecutionBlock:^{
        NSLog(@"4---%@",[NSThread currentThread]);
    }];
    
    [op3 addExecutionBlock:^{
        NSLog(@"5---%@",[NSThread currentThread]);
    }];
    
    [op3 addExecutionBlock:^{
        NSLog(@"6---%@",[NSThread currentThread]);
    }];
    
    //2.启动
    [op1 start];
    [op2 start];
    [op3 start];
}
- (void)customWithOpeation {
    //1.封装操作
    RCOperation *op1 = [[RCOperation alloc]init];
    RCOperation *op2 = [[RCOperation alloc]init];
    
    //2.启动
    [op1 start];
    [op2 start];
}

-(void)operation1{
    NSLog(@"1--%@",[NSThread currentThread]);
}

-(void)operation2{
    NSLog(@"2--%@",[NSThread currentThread]);
}

-(void)operation3{
    NSLog(@"3--%@",[NSThread currentThread]);
}


@end
