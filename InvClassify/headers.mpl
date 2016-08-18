(*
    所有文件的变量和函数声明
*)

# InvClassify.mpl
local
        ModuleLoad;                     # 加载包时改变微分显示形式
export
        doClassify,                     # 进行分类
        InvSol,                         # 解对象
        RepSol;                         # 代表元对象

# Basic.mpl
export    
        d,                              # 导出微分算子，用于生成输入表达式
        setSymbols,                     # 设置输入表达式所含变量
        getSymbols;                     # 获取输入表达式所含变量
local
        getTransMatAndPDE,              # 获取伴随变换矩阵和偏微分方程
        getInvariants,                  # 根据偏微分方程获取不变量

        default_syms:={x,y,z,t,u,v,w},      # 默认符号集
        syms:=default_syms,                 # 当前符号集
        pnames:={a,c,d,epsilon,Delta,phi},  # 受保护的名字

        `&*`,                           # 交换子运算符
        getKd,                          # 将表达式分解为非线性项并提取系数
        getPmVec,                       # 获取表达式关于给定非线性项集的系数向量
        ans2v,                          # 求解表达式关于基的线性表出

        getPDE;                         # 获取生成不变量的偏微分方程

uses    
        Pa=`\x26\x50\x61\x72\x74\x69\x61\x6C\x44\x3B`;# 微分算子所作用的函数

# Classifyer.mpl
local    
        cid:=0,                     # 当前不变量方程中的常数项下标
        getCname,                   # 获取不变量方程中常数项c[k]的名字

        ieqCode:=0,                 # 不变量方程编号
        getIeqCode,                 # 获取不变量方程的编号
        
        buildInvEqs,                # 构造不变量方程
        genInvariants,              # 产生新的不变量
        subsOeq,                    # 产生新的偏微分方程
        solveInvEqs,                # 求解不变量方程
        solveAllZero,               # 求解全零不变量方程
        fetchRep,                   # 取特解定代表元
        solveTransEq,               # 求解伴随变换方程

        clearConditions,            # 删去与a无关的约束
        eqOfEpsilon,                # 检查是否和epsilon有关

        sols,                       # 当前所有解
        usols,                      # 上一个全零不变量方程的解
        getUsolsKey,                # 获取全零方程在usols中的key
        solveRestAllZeroIeqs,       # 求解剩余全零不变量方程
        oldSols,                    # 上一次getSols的解

        getNewSols,                 # 获取新解
        solveTeq,                   # 指定求解伴随变换方程

        ieqsolve,                   # 自定义求解不变量方程
        teqsolve,                   # 自定义求解变换方程

        resolve,                    # 重新分类
        classify;                   # 自动分类
export    
        getSols;                    # 获取所有解
      


# Combine.mpl
export  
        rmRep,                      # 删除代表元
        updateRep,                  # 修改代表元
        getReps;                    # 获取排序后的代表元
local   
        reps:={},                   # 当前代表元映射表
        buildReps,                  # 重新计算代表元
        addReps,                    # 新增代表元
        formReps;                   # 建立代表元

# Condition.mpl
local   
        findSolutionDomain,         # 求解解的定义域
        classifySolve,              # 分类求解约束
        findDomain,                 # 求解表达式定义域
        findDomainCondtions;        # 求解表达式约束条件

# Fetch.mpl
export  fetchSolRep;                # 取特解
local    
        fetchSpecSol,               # 根据方程和约束取特解
        rebuildAndFetch,            # 转化关于c的不等式约束之后，再对约束进行分类
        fetchByCons,                # 求解关于a的约束之后，转化为单边约束，再逐解取特解
        fetchBySingleCons,          # 对于和a有关的约束，采用逐步替换的方法取特解
        isSingleCon,                # 是否是单变量约束
        filtCon,                    # 筛选：自由变量，确定性约束，和c无关的不等式约束，和c有关的不等式约束
        transIeq,                   # 将不等式约束转化为等式约束
        fetchIeq;                   # 最邻近整数方法取特解


# InvSimplify.mpl
local
        simplifyInvariants,             # 化简不变量
        simplifyInvs,                   # 单次化简
        simpleSimplify,                 # 消除不变量的倍数
        myAlgsubs,                      # 解决algsubs对分式进行替换的问题
        dealsubs,                       # 预处理替换表达式
        rmOrd,                          # 简化不变量次数
        getOrd,                         # 获取连乘项的各项幂次
        setOrd,                         # 设置连乘项的各项幂次
        isInv,                          # 检查是否为不变量
        rmK,                            # 删除多项式的倍数
        myGcd,                          # 多个数的gcd
        spAdd,                          # 简化不变量之和
        spMul,                          # 简化不变量之积
        invOrd;                         # 化简分数次数的不变量

# InvOrder.mpl
local   findInvariantsOrder,        # 计算不变量阶数
        findOrder,                  # 计算表达式阶数（不含分母）
        findItemOrder;              # 计算某一项的阶数

# Utils.mpl
local   
        sortByComplexity,           # 表达式按照复杂度进行排序
        tappend,                    # 按照集合拓展table键值
        tpop,                       # 提取并删除值
        collectObj,                 # 对象按键值分类
        printDeltas,                # 输出Delta
        uniqueObj;                  # 对象按键值唯一化
export
        summaryReps,                # 简要输出代表元及其成立条件以及不变量方程和变换方程的解
        printRepCon,                # 简要输出代表元及其成立条件
        printSols,                  # 输出所有InvSol
        printReps;                  # 输出所有RepSol

# Interaction.mpl
export  
        canTransform,               # 检查两个代表元之间能否相互转化
        resolveRep,                 # 添加新的RepSol进行求解
        resolveSol,                 # 添加新的InvSol进行求解
        fetchNewRep;                # 获取新的代表元   
local   
        testTransform;              # 检查两个解之间能否相互转化

# Logout.mpl
(*
    输出级别：
        1   输出所有过程
        2   输出关键结果
        3   不输出
*)
export  setLogLevel;                # 设置输出级别
local   
        logLevel:=1,                # 日志输出级别
        flog,                       # 对应 print
        flogf;                      # 对应 printf