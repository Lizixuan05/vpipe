# VPipe 学习路线图

## 📊 概念关系图

```
                                    VPipe系统
                                        |
                 _______________________ ______________________
                |                       |                      |
         流水线并行                  异步调度              权重存储
      (Pipeline Parallel)          (ASP Mode)         (Weight Stashing)
                |                       |                      |
         Stage切分                   1F1B调度              Version Queue
         Partition                 不等待同步             保存多版本权重
                |                       |                      |
         ________|________        _______|_______         _____|_____
        |                |       |               |       |           |
     模型层            激活值   Forward       Backward   旧版本    新版本
     分配方案          通信     Minibatch    Minibatch   应用梯度  前向推理
```

## 🎯 学习路径总览

```
第一阶段 (Day 1-2)          第二阶段 (Day 3-4)         第三阶段 (Day 5-6)        第四阶段 (Day 7)
  宏观理解                    代码执行流程               深入核心机制             实验调优
     |                            |                          |                      |
     v                            v                          v                      v
┌─────────────┐           ┌──────────────┐          ┌──────────────┐        ┌─────────────┐
│ 理解架构    │           │ driver.py    │          │ 通信机制     │        │ 运行实验    │
│ Stage/Rank  │  -------> │ main_with... │  ------> │ Weight       │  ----> │ 性能对比    │
│ Pipeline    │           │ runtime.py   │          │ Stashing     │        │ 参数调优    │
└─────────────┘           └──────────────┘          └──────────────┘        └─────────────┘
     |                            |                          |                      |
读学习指南               添加打印语句                 查变量速查表          修改配置文件
画流程图                 单步追踪                     理解队列机制          分析日志
```


## 🗺️ 核心知识地图

### 1. 架构层

```
VPipe系统架构
│
├── 启动层 (driver.py)
│   ├── 解析YAML配置
│   ├── 构建机器列表
│   ├── 启动Singularity容器
│   └── 分发运行命令
│
├── 训练层 (main_with_runtime.py)
│   ├── 初始化分布式环境
│   ├── 加载数据集
│   ├── 构建模型和partition
│   ├── 创建optimizer
│   └── 执行训练循环
│
├── 运行时层 (runtime.py)
│   ├── StageRuntime初始化
│   ├── 前向传播管理
│   ├── 反向传播管理
│   └── 流水线调度
│
└── 通信层 (communication.py)
    ├── 进程组管理
    ├── 点对点通信
    ├── 广播通信
    └── 异步线程池
```

### 2. 概念层

```
核心概念体系
│
├── 并行维度
│   ├── 流水线并行 (Pipeline): 模型切分到多个GPU
│   ├── 数据并行 (Data): 同一stage内多GPU
│   └── 张量并行 (Tensor): (未实现，在cpm目录开发中)
│
├── 流水线概念
│   ├── Stage: 连续的若干层
│   ├── Minibatch: Batch的子集
│   ├── Warmup: 填充流水线
│   ├── 1F1B: One Forward One Backward
│   └── Cooldown: 排空流水线
│
├── 通信概念
│   ├── Rank: 进程标识
│   ├── Tensor Tag: 通信标识
│   ├── Send/Recv: 点对点通信
│   └── Broadcast: 广播通信
│
└── 优化技术
    ├── Weight Stashing: 多版本权重
    ├── Recomputation: 激活值重计算
    ├── ASP: 异步陈旧参数
    └── Gradient Clipping: 梯度裁剪
```

### 3. 数据流层

```
数据流动路径
│
Dataset
  │
  v
DataLoader (仅Stage 0)
  │
  v
┌─────────┐
│ Stage 0 │ input_ids, attention_mask, labels
│         │ ↓ Forward
│         │ out12 (激活值)
└─────────┘
     │ send
     v
┌─────────┐
│ Stage 1 │ ← recv out12
│         │ ↓ Forward
│         │ out25 (激活值)
└─────────┘
     │ send
     v
┌─────────┐
│ Stage 2 │ ← recv out25
│         │ ↓ Forward
│         │ out38 (激活值)
└─────────┘
     │ send
     v
┌─────────┐
│ Stage 3 │ ← recv out38
│         │ ↓ Forward + Loss
│ (Loss)  │ ↓ Backward
│         │ grad_out38 (梯度)
└─────────┘
     │ send
     v
┌─────────┐
│ Stage 2 │ ← recv grad_out38
│         │ ↓ Backward
│         │ grad_out25 (梯度)
└─────────┘
     │ send
     v
┌─────────┐
│ Stage 1 │ ← recv grad_out25
│         │ ↓ Backward
│         │ grad_out12 (梯度)
└─────────┘
     │ send
     v
┌─────────┐
│ Stage 0 │ ← recv grad_out12
│         │ ↓ Backward
│         │ 更新权重
└─────────┘
```

## 📋 知识点清单

### 必须掌握 ✅

- [ ] Stage vs Rank vs GPU 的区别
- [ ] Pipeline并行的基本原理
- [ ] 1F1B调度策略
- [ ] Warmup/Cooldown阶段
- [ ] send_ranks 和 receive_ranks 的构建
- [ ] tensor_tags 的作用
- [ ] Weight Stashing 的必要性
- [ ] 如何运行基础实验

### 应该理解 🔶

- [ ] driver.py 的启动流程
- [ ] StageRuntime 的初始化过程
- [ ] CommunicationHandler 的工作机制
- [ ] OptimizerWithWeightStashing 的实现
- [ ] partition配置如何影响性能
- [ ] recompute_ratio 的内存-时间权衡
- [ ] ASP vs BSP 的区别
- [ ] 如何调试和定位问题

### 可以扩展 🌟

- [ ] BERT模型的切分实现 (vpipe.py)
- [ ] 激活重计算的详细机制
- [ ] 多节点通信的优化
- [ ] 3D并行 (Pipeline + Data + Tensor)
- [ ] 动态调度策略
- [ ] 为新模型编写切分代码
- [ ] 通信压缩技术
- [ ] 性能profiling和优化


## 🔍 快速查找索引

### 按概念查找

| 概念 | 定义位置 | 实现位置 | 示例位置 |
|------|----------|----------|----------|
| Stage | 学习指南 §核心概念1 | runtime.py:147 | 代码走查 实战2 |
| Rank | 学习指南 §核心概念2 | runtime.py:86 | 代码走查 实战2 |
| Minibatch | 学习指南 §核心概念3 | runtime.py:90-91 | 代码走查 实战3 |
| Weight Stashing | 学习指南 §核心概念5 | optimizer.py:21 | 代码走查 实战5 |
| Recomputation | 学习指南 §核心概念6 | bert/vpipe.py:49 | 代码走查 实战6 |
| send_ranks | 变量速查表 §通信 | runtime.py:84 | 代码走查 实战4 |
| tensor_tags | 变量速查表 §通信 | runtime.py:89 | 代码走查 实战4 |
| partition | 学习指南 §配置文件 | configs/*.json | 代码走查 实战2 |

### 按文件查找

| 文件 | 主要功能 | 关键类/函数 | 详解位置 |
|------|----------|-------------|----------|
| driver.py | 启动分布式训练 | main | 代码走查 实战1 |
| runtime.py | 流水线运行时 | StageRuntime | 代码走查 实战2-3 |
| communication.py | 通信管理 | CommunicationHandler | 代码走查 实战4 |
| optimizer.py | 权重存储 | OptimizerWithWeightStashing | 代码走查 实战5 |
| bert/vpipe.py | BERT切分 | Bert, Stage | 代码走查 实战6 |
| bert/main_with_runtime.py | 训练主程序 | train, stage | 代码走查 实战2 |

### 按功能查找

| 功能 | 相关文件 | 关键代码 | 学习资料 |
|------|----------|----------|----------|
| 模型切分 | bert/vpipe.py | generate_stage | 学习指南 §阶段三5 |
| 启动训练 | driver.py | Line 267-313 | 代码走查 实战1 |
| 前向传播 | runtime.py | run_forward | 代码走查 实战3 |
| 后向传播 | runtime.py | run_backward | 代码走查 实战3 |
| 发送张量 | runtime.py, communication.py | send_tensors_forward, send | 代码走查 实战4 |
| 接收张量 | runtime.py, communication.py | receive_tensors_forward, recv | 代码走查 实战4 |
| 权重更新 | optimizer.py | step | 代码走查 实战5 |
| 重计算 | bert/vpipe.py | cp_forward | 代码走查 实战6 |

## 💎 核心代码片段索引

### 1. Pipeline调度核心循环

**位置**: runtime.py, run_training_iteration()
```python
# Warmup
for i in range(num_warmup_minibatches):
    receive_tensors_forward()
    run_forward()
    send_tensors_forward()

# Steady (1F1B)
for i in range(num_iterations - num_warmup_minibatches):
    receive_tensors_forward()
    run_forward()
    send_tensors_forward()
    receive_tensors_backward()
    run_backward()
    send_tensors_backward()

# Cooldown
for i in range(num_warmup_minibatches):
    receive_tensors_backward()
    run_backward()
    send_tensors_backward()
```
**学习**: 代码走查实战.md §实战3

### 2. 通信核心逻辑

**位置**: communication.py, send()/recv()
```python
# 发送
tag = tensor_tags[tensor_name] * 100000 + minibatch_id
dist.send(tensor, dst=dst_rank, tag=tag)

# 接收
tag = tensor_tags[tensor_name] * 100000 + minibatch_id
dist.recv(buffer, src=src_rank, tag=tag)
```
**学习**: 代码走查实战.md §实战4

### 3. Weight Stashing核心逻辑

**位置**: optimizer.py, step()
```python
# 1. 加载旧版本权重
load_old_params()  # 从队列头部

# 2. 应用梯度
base_optimizer.step()

# 3. 保存新版本
queue.append(get_params(clone=True))

# 4. 更新版本号
latest_version = latest_version.incr()
current_version = current_version.incr()

# 5. 加载新版本
load_new_params()  # 使用队列尾部
```
**学习**: 代码走查实战.md §实战5

### 4. 模型切分核心逻辑

**位置**: bert/vpipe.py, Stage.__init__()
```python
# 根据recompute_ratio切分
back = int(fraction * len(calcus))

if back > 0:
    # 前面的layers正常执行
    no_cp_ = calcus[:-back]
    
    # 后面的layers使用checkpoint
    cp_ = calcus[-back:]
    cp_out = cp.checkpoint(self.cp_forward, ...)
```
**学习**: 代码走查实战.md §实战6
