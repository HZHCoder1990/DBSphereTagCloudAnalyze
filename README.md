[DBSphereTagCloud](https://github.com/dongxinb/DBSphereTagCloud)是一款3D标签组件，效果如下:

![效果图](./SCREENSHOT.gif)

#### 源码阅读笔记

读懂`DBSphereTagCloud`源码，其实只要解决以下三个问题即可:

 >1.如何把标签均匀的分布在"球体"的表面?
 
 >2."球体"怎么实现自动旋转?
 
 >3."球体"怎么实现拖拽旋转?

- 如何把标签均匀的分布在"球体"的表面?

  最开始看作者的关于计算标签坐标的源码时也是一头雾水，不知如何下手。还好我在我在`StackOverflow`上找到了答案，[Evenly distributing n points on a sphere](https://stackoverflow.com/questions/9600801/evenly-distributing-n-points-on-a-sphere/26127012#26127012)。其中有个答案给出了计算公式:
  
  ``` c
   function sphere ( N:float,k:int):Vector3 {
          var inc =  Mathf.PI  * (3 - Mathf.Sqrt(5));
          var off = 2 / N;
          var y = k * off - 1 + (off / 2);
          var r = Mathf.Sqrt(1 - y*y);
            var phi = k * inc;
            return Vector3((Mathf.Cos(phi)*r), y, Mathf.Sin(phi)*r); 
    };
  ```
 
 - "球体"怎么实现自动旋转?

   使用定时器和旋转矩阵即可。旋转矩阵的推导过程网上有很多资料，我主要参考的是[这篇文章](https://blog.csdn.net/csxiaoshui/article/details/65446125)。在测试工程中，为了简便，我让球体围绕Z轴做逆时针旋转。
  
   围绕Z轴逆时针旋转矩阵:
  
    $ \begin{bmatrix} x_1 \\ y_1  \\ z_1 \\ 1 \end{bmatrix} = \begin{bmatrix} cosθ & -sinθ & 0 & 0 \\ sinθ & cosθ & 0 & 0 \\ 0 & 0 & 1 & 0 \\ 0 & 0 & 0 & 1 \\ \end{bmatrix}  * \begin{bmatrix} x \\ y \\ z \\ 1 \\ \end{bmatrix}$
  
   围绕Z轴顺时针旋转矩阵: 
 
    $ \begin{bmatrix} x_1 \\ y_1  \\ z_1 \\ 1 \end{bmatrix} = \begin{bmatrix} cosθ & sinθ & 0 & 0 \\ -sinθ & cosθ & 0 & 0 \\ 0 & 0 & 1 & 0 \\ 0 & 0 & 0 & 1\\ \end{bmatrix}  * \begin{bmatrix} x \\ y \\ z \\ 1 \\ \end{bmatrix}$

    怎么判断围绕哪一个轴旋转的的标准方向呢? 我个人经验是:`围绕哪一个轴旋转，就从哪一个轴的正方向朝相反方向看过去，并且头顶要和其他轴的正方向一致，标准方向就是从右往左旋转`。
    
  - "球体"怎么实现拖拽旋转?

   给"球体"添加拖动手势即可。但是难点在于在添加了拖动手势后，围绕任意点旋转的旋转矩阵该怎么写？不过网上已经有相关的资料，并给出了具体的步骤:
   >  1.将旋转轴绕x轴旋转
   
   > 2.将旋转轴绕y轴旋转
   
   > 3.绕z轴旋转
   
   > 4.执行步骤2的逆过程
   
   > 5.执行步骤1的逆过程

   具体过程请看源码分析工程。
