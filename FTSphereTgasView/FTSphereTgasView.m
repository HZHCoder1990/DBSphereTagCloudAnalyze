
#import "FTSphereTgasView.h"
#import "YYWeakProxy.h"

/**
 备注:
 
 源码读到这里基本结束了，不过还有2个问题待解决
   
   > 1.UIKit坐标系转换到笛卡尔坐标系？
   > 2.在绕任意点旋转的时候，为什么绕Y轴需要加上direction.y这个分量？
 */

// 定义"点"的结构体
struct FTPoint{
    CGFloat x;
    CGFloat y;
    CGFloat z;
};

typedef struct FTPoint FTPoint;

// 构造方法
static FTPoint FTPointMake(CGFloat x,CGFloat y,CGFloat z){
     
     FTPoint point;
     point.x = x;
     point.y = y;
     point.z = z;
     return point;
}
typedef NSUInteger FTU_Int;

//定义一个 4x4 的矩阵
struct FTMatrix{
    FTU_Int row; //矩阵的行数
    FTU_Int column; //矩阵的列数
    CGFloat matrix[4][4]; //数据
};

typedef struct FTMatrix FTMatrix;

// 构造方法
__unused static FTMatrix FTMatrixMake(FTU_Int row,FTU_Int column){
    
    FTMatrix matrix;
    matrix.row = row;
    matrix.column = column;
    for (FTU_Int i = 0; i < row; i ++) {
        for (FTU_Int j = 0; j < column; j ++) {
            matrix.matrix[i][j] = 0;
        }
    }
    return matrix;
}
// 通过传入数组来构建矩阵
__unused static FTMatrix FTMatrixMakeFromArray(FTU_Int row,FTU_Int column,CGFloat *data){
    
    FTMatrix matrix;
    matrix.row = row;
    matrix.column = column;
    
    // !!!!! 特别注意 下面两种赋值方式的区别  !!!!
    /*  这个是有问题的   满足不了 4 * 4的矩阵
    for (FTU_Int i = 0; i < row; i ++) { // 3
        for (FTU_Int j = 0; j < column; j ++) { // 2
            matrix.matrix[i][j] = *(data + j + i * row);
        }
    }*/
    
    for (FTU_Int i = 0; i < row; i ++) { // 3
        CGFloat *t = data + (i * column);
        for (FTU_Int j = 0; j < column; j ++) { // 2
            matrix.matrix[i][j] = *(t + j);
        }
    }
    return matrix;
}

/**
  矩阵相乘
  两个矩阵必须满足条件:
  1.第一个矩阵的列数必须是等于第二个矩阵的行数。
  2.相乘的结果具有第一个矩阵的行数和第二个矩阵的列数。
 
   1,2,        3,6,               11,24,
   4,5,    *   4,9         =      32,69,
   6,8                            50,108
 
 */
__unused static FTMatrix FTMatrixMutiply(FTMatrix a,FTMatrix b){
    
    FTMatrix resultMatrix = FTMatrixMake(a.row, b.column);
    for (FTU_Int i = 0; i < a.row; i ++) {
        //遍历b的列数
        for (FTU_Int j = 0; j < b.column; j ++) {
            //取出a的列
            for (FTU_Int k = 0; k < a.column; k ++) {
                //"横" * "竖"
                resultMatrix.matrix[i][j] += a.matrix[i][k] * b.matrix[k][j];
            }
        }
    }
    return resultMatrix;
}
/**
 旋转矩阵  为了简便，这里考虑围绕Z轴旋转的情况 其他情况类似
 */
/// 围绕Z轴旋转点
/// @param point 需要旋转的点
/// @param angle 旋转的角度
__unused static FTPoint FTRotationMatrixForZ_Axis(FTPoint point,CGFloat angle){
    
    if (angle == 0.0) return point;
    
    // 矩阵 * 点
    CGFloat originalPointData[1][4] = {
        point.x,
        point.y,
        point.z,
        1.0};
    
    // 构造成矩阵 这里可以传一维数组的 originalPointData[4] 本质是一样的
    FTMatrix result = FTMatrixMakeFromArray(1, 4, *originalPointData);
    

    CGFloat cosθ = cos(angle);
    CGFloat sinθ = sin(angle);
    // 逆时针旋转
//    CGFloat m[4][4] = {
//        {cosθ,-sinθ,0,0},
//        {sinθ,cosθ,0,0},
//        {0,  0,  1,  0},
//        {0,  0,  0,  1},
//    };
    
    // 顺时针旋转
    CGFloat m[4][4] = {
        {cosθ,sinθ,0,0},
        {-sinθ,cosθ,0,0},
        {0,  0,  1,  0},
        {0,  0,  0,  1},
    };
    
    FTMatrix matrix = FTMatrixMakeFromArray(4, 4, *m);
    result = FTMatrixMutiply(result, matrix);
    FTPoint resultPoint = FTPointMake(result.matrix[0][0], result.matrix[0][1], result.matrix[0][2]);
    return resultPoint;
    
    /**
     result =
     {
       x,y,z,1,                 xcosθ + ysinθ,  -xsinθ + ycosθ,z,1
       0,0,0,0,    * matix =
       0,0,0,0,
       0,0,0,0
     }
     */
}


/// 绕任意轴旋转
/// @param point 需要旋转的点
/// @param direction 点移动的很小的一段位移，需要组从UIKit坐标系映射到笛卡尔坐标系
/// @param angle 旋转角度
/**
 绕任意轴旋转步骤:
 1.将旋转轴绕x轴旋转
 2.将旋转轴绕y轴旋转
 3.绕z轴旋转
 4.执行步骤2的逆过程
 5.执行步骤1的逆过程
 
 */
__unused static FTPoint FTRotationMatrixForRandom_Axis(FTPoint point,
                                                       FTPoint direction,
                                                       CGFloat angle){
    
    if (angle == 0.0) return point;
    CGFloat originalPointData[1][4] = {
        point.x,
        point.y,
        point.z,
        1.0};
    FTMatrix result = FTMatrixMakeFromArray(1, 4, *originalPointData);
    
    // 这里的旋转矩阵统一采用顺时针旋转矩阵
    // 1.绕X轴旋转
    if (direction.z * direction.z + direction.y * direction.y != 0) {
        CGFloat distance_zy = sqrt(direction.z * direction.z + direction.y * direction.y);
        CGFloat cos1 = direction.z / distance_zy;
        CGFloat sin1 = direction.y / distance_zy;
        CGFloat t1[4][4] = {
            {1, 0, 0, 0},
            {0, cos1, sin1, 0},
            {0, -sin1, cos1, 0},
            {0, 0, 0, 1}};
        FTMatrix m1 = FTMatrixMakeFromArray(4, 4, *t1);
        result = FTMatrixMutiply(result, m1);
    }
    
    //2.绕Y轴旋转  这里还有疑问: 按道理来讲 绕Y轴旋转 是不需要加上.y的值的!!!
    if (direction.x * direction.x + direction.y * direction.y + direction.z * direction.z != 0) {
        CGFloat distance_xyz = sqrt(direction.x * direction.x + direction.y * direction.y + direction.z * direction.z);
        CGFloat cos2 = sqrt(direction.y * direction.y + direction.z * direction.z) / distance_xyz;
        CGFloat sin2 = -direction.x /distance_xyz;
        CGFloat t2[4][4] = {
            {cos2, 0, -sin2, 0},
            {0, 1, 0, 0},
            {sin2, 0, cos2, 0},
            {0, 0, 0, 1}};
        FTMatrix m2 = FTMatrixMakeFromArray(4, 4, *t2);
        result = FTMatrixMutiply(result, m2);
    }
    
    // 3.绕Z轴旋转
    CGFloat cosθ = cos(angle);
    CGFloat sinθ = sin(angle);
    CGFloat m[4][4] = {
        {cosθ,sinθ,0,0},
        {-sinθ,cosθ,0,0},
        {0,  0,  1,  0},
        {0,  0,  0,  1},
    };
    
    FTMatrix matrix = FTMatrixMakeFromArray(4, 4, *m);
    result = FTMatrixMutiply(result, matrix);
    
    //4.绕Y轴反方向旋转
    if (direction.x * direction.x + direction.y * direction.y + direction.z * direction.z != 0) {
        CGFloat distance_xyz = sqrt(direction.x * direction.x + direction.y * direction.y + direction.z * direction.z);
        CGFloat cos2 = sqrt(direction.y * direction.y + direction.z * direction.z) / distance_xyz;
        CGFloat sin2 = -direction.x / distance_xyz;
        CGFloat t2_[4][4] = {{cos2, 0, sin2, 0}, {0, 1, 0, 0}, {-sin2, 0, cos2, 0}, {0, 0, 0, 1}};
        FTMatrix m2_ = FTMatrixMakeFromArray(4, 4, *t2_);
        result = FTMatrixMutiply(result, m2_);
    }
    
    //5.绕X轴反方向旋转
    if (direction.z * direction.z + direction.y * direction.y != 0) {
        CGFloat distance_zy = sqrt(direction.z * direction.z + direction.y * direction.y);
        CGFloat cos1 = direction.z / distance_zy;
        CGFloat sin1 = direction.y / distance_zy;
        CGFloat t1_[4][4] = {{1, 0, 0, 0}, {0, cos1, -sin1, 0}, {0, sin1, cos1, 0}, {0, 0, 0, 1}};
        FTMatrix m1_ = FTMatrixMakeFromArray(4, 4, *t1_);
        result = FTMatrixMutiply(result, m1_);
    }
    
    FTPoint resultPoint = FTPointMake(result.matrix[0][0], result.matrix[0][1], result.matrix[0][2]);
    return resultPoint;
    
}

// 遍历矩阵
__unused static void TraverseForFTMatrix(FTMatrix matrix){
    
    printf("{\n");
    for (FTU_Int i = 0; i < matrix.row; i ++) {
        if (i != 0) printf("\n");
       
        for (FTU_Int j = 0; j < matrix.column; j ++) {
            printf("   %f,",matrix.matrix[i][j]);
        }
    }
    printf("\n}");
}

// 打印矩阵信息
//#define __PRINTF_MATRIX
void _test(){
    
    CGFloat a_data[] = {1,2,4,5,6,8};
    CGFloat b_data[] = {3,6,4,9};
    
    FTMatrix a = FTMatrixMakeFromArray(3, 2, a_data);
    FTMatrix b = FTMatrixMakeFromArray(2, 2, b_data);
    FTMatrix res = FTMatrixMutiply(a, b);
    TraverseForFTMatrix(res);
}

#define ROTATION_ANGLE  0.002

@interface FTSphereTgasView ()
{
    //保存所有的标签
    NSMutableArray<UIView *> *_allTags;
    //保存所有的坐标
    NSMutableArray<NSValue *> *_allCoordinates;
    
    //定时器
    // 自动旋转时
    CADisplayLink *_timer;
    // 松开手减速时
    CADisplayLink *_inertia;
    
    //上一次碰触的点
    CGPoint _lastPoint;
    //滚动速度
    CGFloat _velocity;
    
    //每次移动后的坐标
    FTPoint _moveDirection;
}
@property (assign,nonatomic) CGFloat halfWidth;
@property (assign,nonatomic) CGFloat halfHeight;
@property (assign,nonatomic) FTU_Int allTagsCnt;
@end

@implementation FTSphereTgasView
- (CGFloat)halfWidth{
    return self.frame.size.width * 0.5;
}
- (CGFloat)halfHeight{
    return self.frame.size.height * 0.5;
}
- (FTU_Int)allTagsCnt{
    if (!_allTags) {
        return 0;
    }
    return _allTags.count;
}
- (instancetype)initWithFrame:(CGRect)frame
                         tags:(NSArray *)tags{
    if (self = [super initWithFrame:frame]) {
        
        _allTags = [NSMutableArray arrayWithArray:tags];
        _allCoordinates = [NSMutableArray arrayWithCapacity:0];
        
        [self prepareTagsLayout];
        [self preparePanGestureAndTimer];
        
        //默认值
        _moveDirection = FTPointMake(0.5, 0.5, 0.0);
        
#ifdef __PRINTF_MATRIX
        _test();
#endif
        
    }
    return self;
}
/**
  最开始的标签布局
 */
- (void)prepareTagsLayout{
    
    if (!_allTags.count) return;
    
    FTU_Int N = _allTags.count;
    NSInteger i = 0,j = 0;
    //最开始所有的标签都居中显示
    for (; i < N; i ++) {
        UIView *view = [_allTags objectAtIndex:i];
        if (!view) { return; }
        view.center = CGPointMake(self.halfWidth, self.halfHeight);
        [self addSubview:view];
    }
    
    //计算球体表面标签的坐标
    CGFloat inc = M_PI * (3.0 - sqrt(5.0));
    CGFloat off = 2.0 / N;
    for (; j < N; j ++) {
        CGFloat y = j * off - 1.0 + (off / 2.0);
        CGFloat r = sqrt(1.0 - y * y);
        CGFloat phi = j * inc;
        CGFloat x = cos(phi) * r;
        CGFloat z = sin(phi) * r;
        
        //转成对象 放入数组中保存
        FTPoint point = FTPointMake(x, y, z);
        NSValue *value = [NSValue value:&point withObjCType:@encode(FTPoint)];
        [_allCoordinates addObject:value];
        
        CGFloat animationTime = 1.0;
        [UIView animateWithDuration:animationTime animations:^{
            [self layoutTagWithPoint:point forIndex:j];
        }];
    }
}

/// 开始布局每一个标签
/// @param point 点的坐标属性
/// @param index 位置
- (void)layoutTagWithPoint:(FTPoint)point
                  forIndex:(NSUInteger)index{
    
    UIView *view = [_allTags objectAtIndex:index];
    if (!view) return;
    
    //这里为什么要 +1呢？ 因为这样球体的圆心才会在屏幕中心
    view.center = (CGPoint){(point.x + 1.0) * self.halfWidth,(point.y + 1.0) * self.halfHeight};
    
    //这个可更改 选择合适的即可
    CGFloat transform = (point.z + 2.0) / 3.0;
    view.transform = CGAffineTransformScale(CGAffineTransformIdentity, transform, transform);
    // 调整view的层级 数值越大 越在前面
    view.layer.zPosition = transform;
    view.alpha = transform;
}

/// 定时器
- (void)preparePanGestureAndTimer{
    
    UIPanGestureRecognizer *gesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    [self addGestureRecognizer:gesture];
    
    _timer = [CADisplayLink displayLinkWithTarget:[YYWeakProxy proxyWithTarget:self] selector:@selector(autoRotation)];
    [_timer addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    
    _inertia = [CADisplayLink displayLinkWithTarget:[YYWeakProxy proxyWithTarget:self] selector:@selector(inertiaStep)];
    [_inertia addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
}
- (void)autoRotation{
    
    for (FTU_Int i = 0; i < self.allTagsCnt; i ++) {
        //[self updatePointFrame:i angle:ROTATION_ANGLE];
        [self updatePointFrame:i direction:_moveDirection angle:ROTATION_ANGLE];
    }
}
// 减速的回调
- (void)inertiaStep{
    
    // 速度 <= 0.0了  暂停定时器
    if (_velocity <= 0.0) {
        [self inertiaStop];
    }else{
        //速度 每次衰减70
        _velocity -= 70.0;
        // 旋转角度
        CGFloat angle = _velocity / self.halfWidth * 2.0 * _inertia.duration;
        //更新坐标
        for (FTU_Int i = 0; i < self.allTagsCnt; i ++) {
            [self updatePointFrame:i direction:_moveDirection angle:angle];
        }
    }
}
- (void)handlePanGesture:(UIPanGestureRecognizer *)gesture{
    
    if (gesture.state == UIGestureRecognizerStateBegan) {
        //获得触碰点的坐标
        _lastPoint = [gesture locationInView:self];
        //暂停定时器
        [self stopAutoRotationTimer];
        [self inertiaStop];
    }else if (gesture.state == UIGestureRecognizerStateChanged) {
        //时时获取点的坐标
        CGPoint current = [gesture locationInView:self];
        // UIKit坐标系转换到笛卡尔坐标系
        FTPoint direction = FTPointMake(_lastPoint.y - current.y, current.x - _lastPoint.x, 0.0);
        CGFloat distance = sqrt(direction.x * direction.x + direction.y * direction.y);
        CGFloat angle = distance / (self.halfWidth * 0.5);
        
        for (NSInteger i = 0; i < self.allTagsCnt; i ++) {
            [self updatePointFrame:i direction:_moveDirection angle:angle];
        }
        _moveDirection = direction;
        _lastPoint = current;
    }else if (gesture.state == UIGestureRecognizerStateEnded) { //松手
        CGPoint velocityP = [gesture velocityInView:self];
        _velocity = sqrt(velocityP.x * velocityP.x + velocityP.y * velocityP.y);
        //减速定时器开始启动
        [self inertiaStart];
    }
}

#pragma mark 定时器相关的操作
// 启动减速定时器
- (void)inertiaStart{
    //暂停自动旋转的定时器
    [self stopAutoRotationTimer];
    _inertia.paused = NO;
}
// 暂停减速定时器
- (void)inertiaStop{
    
    [self startAutoRotationTimer];
    _inertia.paused = YES;
}
// 暂停自动旋转定时器
- (void)stopAutoRotationTimer{
    _timer.paused = YES;
}
- (void)startAutoRotationTimer{
    _timer.paused = NO;
}


/*
/// 更新点的位置
/// @param index 索引
/// @param angle 角度
- (void)updatePointFrame:(NSUInteger)index
                   angle:(CGFloat)angle{
    
    //取出对应位置的point
    NSValue *value = [_allCoordinates objectAtIndex:index];
    FTPoint point;
    [value getValue:&point];
    
    //获得旋转过后的坐标
    FTPoint rPoint = FTRotationMatrixForZ_Axis(point, angle);
    //更新数组中的数据
    value = [NSValue value:&rPoint withObjCType:@encode(FTPoint)];
    _allCoordinates[index] = value;
    
    //更改point的位置
    [self layoutTagWithPoint:rPoint forIndex:index];
}*/


///  更新点的位置
/// @param index index
/// @param direction 移动后的点
/// @param angle 旋转角度
- (void)updatePointFrame:(NSUInteger)index
               direction:(FTPoint)direction
                   angle:(CGFloat)angle{
    
    //取出对应位置的point
    NSValue *value = [_allCoordinates objectAtIndex:index];
    FTPoint point;
    [value getValue:&point];
    
    //获得旋转过后的坐标
    FTPoint rPoint = FTRotationMatrixForRandom_Axis(point, direction, angle);
    //更新数组中的数据
    value = [NSValue value:&rPoint withObjCType:@encode(FTPoint)];
    _allCoordinates[index] = value;
    
    //更改point的位置
    [self layoutTagWithPoint:rPoint forIndex:index];
}

- (void)dealloc{
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
    if (_inertia) {
        [_inertia invalidate];
        _inertia = nil;
    }
}
@end
