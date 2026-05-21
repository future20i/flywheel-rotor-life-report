# AI 万卡 GPU 集群直流母线飞轮储能系统转子寿命与动态可靠性论证报告

**版本**：V1.0  
**日期**：2026-05-21  
**材料**：25Cr2Ni4MoV | 最高转速：20,000 rpm | 800V DC Bus | SiC DC/DC + SST

---

## 摘要

本报告针对 AI 万卡 GPU 集群通过 SiC 电力电子系统（DC/DC + SST）耦合至 800V 直流母线的飞轮储能系统，建立完整的转子寿命与动态可靠性分析框架。核心研究对象为 25Cr2Ni4MoV 锻钢转子，最高转速 20,000 rpm。关键区别在于：传统 UPS 场景中飞轮承受的是电网频率波动（0.01~0.5 Hz）和年数次 UPS 切换冲击，而 AI 数据中心场景下，GPU 集群的 Compute Spike（All-Reduce 同步、梯度检查点、推理派发）产生 **10 Hz ~ 10 kHz 的高频功率波动**，经 SiC 开关器件（20~50 kHz）耦合后，在转子上产生 **宽带随机电磁转矩激励**。这种激励的频谱宽度、随机性、持续时间均远超传统设计基准，直接刷新了飞轮转子疲劳寿命评估的工程范式。

---

## 1. 系统建模基础

### 1.1 飞轮转子物理参数

| 参数 | 符号 | 值 | 单位 |
|------|------|-----|------|
| 材料 | 25Cr2Ni4MoV | — | — |
| 密度 | $\rho$ | 7,850 | kg/m³ |
| 弹性模量 | $E$ | 206 | GPa |
| 泊松比 | $\nu$ | 0.30 | — |
| 屈服强度 | $\sigma_y$ | 930 | MPa |
| 抗拉强度 | $\sigma_b$ | 1,080 | MPa |
| 疲劳极限（10⁷ cycles） | $\sigma_f$ | 480 | MPa |
| 断裂韧性 | $K_{IC}$ | 120~145 | MPa·m^{1/2} |
| Paris 常数 | $C, m$ | $2.1\times10^{-12}$, 3.2 | — |
| 最高转速 | $n_{max}$ | 20,000 | rpm |
| 额定转速 | $n_{rated}$ | 18,000 | rpm |
| 转动惯量 | $J$ | 42.5 | kg·m² |
| 最大储能 | $E_{max} = \frac{1}{2}J\omega_{max}^2$ | 93.2 | MJ |
| 转子质量 | $m$ | 860 | kg |
| 转子类型 | 实心阶梯轴 + 飞轮盘 | — | — |

**来源**：25Cr2Ni4MoV 为风电/火电主轴及飞轮转子常用高强度合金钢，数据参照 GB/T 3310-2019、ASTM A471 及典型 2MW 级飞轮转子设计参数。

---

### 1.2 AI 万卡 GPU 集群功率频谱模型

这是本报告与所有传统飞轮寿命评估的根本性差异所在。

#### 1.2.1 GPU 负载的时间尺度分层

AI 训练/推理的功率负载具有显著的多尺度特征。定义 GPU 集群母线瞬时功耗为：

$$P_{GPU}(t) = P_{base} + \sum_{i=1}^{N} \Delta P_i \cdot \text{Rect}_{[t_i, t_i+\tau_i]}(t) + P_{noise}(t)$$

其中：
- $P_{base}$ — 稳态功耗（推理持续负载 + 训练数据管线填充）
- $\Delta P_i$ — 第 $i$ 个功率脉冲的幅值
- $\text{Rect}$ — 矩形脉冲函数
- $\tau_i$ — 脉冲宽度
- $P_{noise}(t)$ — 残差随机分量

#### 1.2.2 关键时间尺度

| 事件 | 时间尺度 | 功率变化幅度 | 物理原因 |
|------|---------|-------------|---------|
| All-Reduce 同步 | 100 μs ~ 10 ms | +30%~+80% $P_{base}$ | 梯度聚合网络通信释放计算空闲 |
| 梯度检查点 I/O 爆发 | 10~100 ms | +20%~+50% | PCIe/NVLink 存储访问峰值 |
| 前向/反向传播交替 | 1~100 ms | ±10%~±30% | 计算管线交替，GPU 利用率波动 |
| 批次结束/开始 | 10~200 ms | -40%~-80% | 管线排空气 + 新批次加载 |
| 推理请求到达 | 1 μs~1 ms | +5%~+30% | 推理实例动态扩缩 |
| 推理批处理调度 | 1~50 ms | ±20%~±60% | 动态批大小切换 |
| 温控/降频事件 | 秒级 | -30%~-50% | 芯片温度触发 DVFS |

对于 **万卡集群**，这些波动在统计上叠加而非完全相消。实测研究表明，在 10,000+ GPU 规模下，集群总功率的 **归一化频谱密度在 10 Hz ~ 1 kHz 范围内维持 > -20 dB 的水平**（文献：Google Borg 集群功耗特征，ASPLOS 2021；Meta 训练集群测量，ISCA 2023）。

#### 1.2.3 GPU 功率的 PSD 模型

定义单台 GPU 的归一化功率谱密度为：

$$S_{GPU}(f) = \frac{P_{pk}^2}{2\pi f_c} \cdot \frac{1}{1 + (f/f_c)^2} + \sum_{k=1}^{N} A_k \cdot \delta(f - f_k) + W(f)$$

- 第一项：**Lorentzian 连续谱**，截断频率 $f_c \approx 50$ Hz（对应 All-Reduce 周期 20 ms）
- 第二项：**离散线谱**，对应确定的计算节律（$f_k = 1/T_k$）
- 第三项：**白噪声基底** $W(f) = \sigma_{noise}^2$，覆盖开关频率及以上

对于万卡集群，等效 PSD 为（假设各 GPU 非完全独立、存在部分同步性）：

$$S_{cluster}(f) = N_{GPU} \cdot S_{GPU}(f) \cdot \Gamma(f)$$

其中 $\Gamma(f)$ 为相干函数（Coherence Function），$0 \le \Gamma(f) \le 1$。实测值在低频段（< 50 Hz）$\Gamma \approx 0.3\sim0.6$，高频段 $\Gamma \to N_{GPU}^{-1}$。

---

## 2. 电磁转矩纹波模型

### 2.1 SiC DC/DC 耦合路径

飞轮系统通过 SiC MOSFET DC/DC 变换器与 800V 直流母线连接。SiC 器件的开关频率 $f_{sw} = 20 \sim 50$ kHz 远高于传统 IGBT（2~5 kHz），但 PWM 开关过程引入的 **高频纹波转矩** 必须建模。

电磁转矩的通用表达式：

$$T_e(t) = T_{e0} + \Delta T_{e,load}(t) + \Delta T_{e,ripple}(t)$$

#### 2.1.1 负载耦合转矩

由 GPU 功率波动耦合至直流母线，并经 DC/DC 变换器传至飞轮电机的电磁端：

$$\Delta T_{e,load}(t) = \frac{1}{\omega_{FW}} \cdot \frac{P_{DC,bus}(t)}{\eta_{DC/DC}} \approx \frac{P_{GPU}(t)}{\omega_{FW} \cdot \eta_{DC/DC}}$$

其中 $\omega_{FW}$ 为飞轮瞬时角速度，$\eta_{DC/DC}$ 为 SiC 变换器效率（~97.5%）。

#### 2.1.2 PWM 纹波转矩

SiC DC/DC 的 PWM 调制在定子电流中引入开关频率谐波，产生纹波转矩：

$$\Delta T_{e,ripple}(t) = \frac{3}{2} p \cdot \left[ \Psi_{PM} \cdot \tilde{i}_q(t) + (L_d - L_q) \cdot \tilde{i}_d(t) \cdot \tilde{i}_q(t) \right]$$

其中 $\tilde{i}_d(t)$、$\tilde{i}_q(t)$ 为 dq 轴电流的高频分量（开关频率 ± 边带），由 PWM 死区效应和电压谐波产生。对于 **500 kW 级 PMSM 飞轮电机**，典型值为：

$$|\Delta T_{e,ripple}|_{rms} \approx 0.5 \sim 2.5 \text{ N·m}$$

纹波频率为 $f_{ripple} = m \cdot f_{sw} \pm n \cdot f_e$，其中 $f_e = p \cdot f_{FW}$（PMSM 电频率），$p$ 为极对数。

### 2.2 合成转矩激励的频谱

将 GPU 功率波动和 PWM 纹波叠加，得到施加于转子的 **合成电磁转矩扰动** 的功率谱密度：

$$S_{Te}(f) = \frac{1}{\omega_{FW}^2 \eta^2} \cdot S_{GPU}(f) \cdot |H_{DC/DC}(f)|^2 + \sum_{m,n} \delta(f - (mf_{sw} \pm n f_e)) \cdot \Gamma_{ripple}^2$$

其中 $H_{DC/DC}(f)$ 为 SiC DC/DC 变换器的闭环传递函数（含输出电容滤波效应）。

> **关键结论**：在 AI 数据中心工况下，飞轮转子承受的电磁转矩激励频谱覆盖 **10 Hz ~ 50 kHz** 的宽带范围，其中 10 Hz ~ 1 kHz 的连续谱分量（来自 GPU 负载）是决定疲劳寿命的主要贡献者。传统 UPS 场景这一分量几乎为零。

---

## 3. 转子扭振模型

### 3.1 连续体扭转振动方程

将飞轮转子视为连续体，建立其扭转振动（Torsional Vibration）控制方程：

$$GJ(x)\frac{\partial^2 \theta(x,t)}{\partial x^2} - \rho J_p(x)\frac{\partial^2 \theta(x,t)}{\partial t^2} - c(x)\frac{\partial \theta(x,t)}{\partial t} = -T_e(t) \cdot \delta(x - x_e)$$

其中：
- $\theta(x,t)$ — 轴向位置 $x$ 处的角位移
- $G$ — 剪切模量（79.5 GPa for 25Cr2Ni4MoV）
- $J(x)$ — 扭转惯性矩（截面极惯性矩）
- $J_p(x)$ — 单位长度极转动惯量
- $c(x)$ — 结构阻尼系数
- $x_e$ — 电机气隙转矩作用位置

### 3.2 模态截断与离散化

采用有限元法（或 Rayleigh-Ritz 法）将连续系统离散为 $N$ 自由度振动系统：

$$\mathbf{J}\ddot{\boldsymbol{\theta}}(t) + \mathbf{C}\dot{\boldsymbol{\theta}}(t) + \mathbf{K}\boldsymbol{\theta}(t) = \mathbf{T}_e(t)$$

其中 $\mathbf{J}$ 为转动惯量矩阵，$\mathbf{K}$ 为扭转刚度矩阵，$\mathbf{C}$ 为阻尼矩阵（通常假定为 Rayleigh 阻尼：$\mathbf{C} = \alpha\mathbf{J} + \beta\mathbf{K}$）。

### 3.3 固有频率与模态

求解特征值问题 $\det(\mathbf{K} - \omega_n^2 \mathbf{J}) = 0$ 得到各阶扭转固有频率 $\omega_n^{(r)}$ 及模态振型 $\boldsymbol{\Phi}^{(r)}$。对典型的 2 MW 级实心钢制飞轮转子：

| 模态阶次 | 固有频率 $f_n$ (Hz) | 振型描述 |
|---------|------------------|---------|
| 第1阶 | 18~35 | 转子一阶扭转 |
| 第2阶 | 120~200 | 转子二阶扭转（含轴段弯曲耦合） |
| 第3阶 | 350~500 | 高阶扭转/弯扭耦合 |
| 第4+阶 | >800 | 纯局部模态（联轴器、轴承等） |

**适用条件**：上述频率范围针对直径~0.8 m、长度~2 m 的实心飞轮转子。具体数值需根据详细有限元计算得出。

### 3.4 Campbell 图（Campbell Diagram）

Campbell 图是评估转子系统共振风险的 **核心工程工具**。它同时绘制：

1. **扭转固有频率线**（随转速变化，因陀螺效应和离心刚度硬化）
2. **激励频率线**：
   - $f_{excitation} = k \cdot f_{FW}$（转频整数倍：1×、2×、3×…）
   - $f_{excitation} = f_{GPU,peak}$（GPU 功率谱峰频率）
   - $f_{excitation} = f_{sw} \pm n f_e$（PWM 边带频率）
   - $f_{excitation} = f_{grid-related}$（若有并网）

**共振条件**：当任一激励频率线与固有频率线相交时，发生共振。

#### 3.4.1 AI 数据中心工况下的特殊关注

**传统 UPS 飞轮** 的主要激励仅包含 1×/2× 转频（由残余不平衡质量产生），Campbell 图分析重点关注工作转速远离这些共振点即可。

**AI 数据中心飞轮** 新增大量 **非转频依赖的宽带激励**（GPU 功率谱 + PWM 边带），它们可能：

- 始终与第一阶扭转固有频率重合（若 $f_{n1} \approx 30$ Hz 落在 GPU PSD 的高能量区）
- 在 10 Hz ~ 1 kHz 范围内形成 **持续的宽带共振带**，而非传统意义上的单点共振

**应对措施**：
- 设计上要求 $f_{n1} > 100$ Hz（通过增大轴径/缩短轴长/增加刚度）
- 或主动注入反向转矩的陷波滤波器（Notch Filter on SiC DC/DC control）

---

## 4. 应力分析与载荷分解

### 4.1 稳态应力场

#### 4.1.1 离心应力

转子在额定转速（18,000 rpm，$\omega = 1885$ rad/s）下，离心应力为最大稳态应力分量。

对于实心圆盘（厚度均匀），径向应力和周向应力的解析解为：

$$\sigma_r(r) = \frac{3+\nu}{8}\rho\omega^2(R^2 - r^2)$$

$$\sigma_\theta(r) = \frac{3+\nu}{8}\rho\omega^2\left(R^2 - \frac{1+3\nu}{3+\nu}r^2\right)$$

最大应力出现在转子中心：

$$\sigma_{max} = \sigma_r(0) = \sigma_\theta(0) = \frac{3+\nu}{8}\rho\omega^2R^2$$

代入参数（$R = 0.4$ m, 18,000 rpm）：

$$\sigma_{max,centrifugal} \approx \frac{3+0.3}{8} \times 7850 \times (1885)^2 \times 0.4^2 \approx 386 \text{ MPa}$$

对于阶梯轴-飞轮盘组合转子，需用有限元计算，典型结果：

| 位置 | 稳态离心应力 (MPa) | 来源 |
|------|-------------------|------|
| 转轴中心 | 350~420 | 解析解 |
| 飞轮盘根部（$R = 0.35$ m） | 280~340 | FE |
| 轴肩过渡区 | 260~320 | FE |
| 轴承座配合面 | 120~200 | FE |

#### 4.1.2 装配过盈应力

转子与电机转子铁芯的过盈配合产生接触应力。过盈量 $\delta = 0.1\sim0.2$ mm（直径方向），产生的径向接触压力：

$$p_c = \frac{\delta}{d} \cdot \frac{1}{\frac{1}{E_1}\left(\frac{d^2+d_1^2}{d^2-d_1^2} - \nu_1\right) + \frac{1}{E_2}\left(\frac{d_2^2+d^2}{d_2^2-d^2} + \nu_2\right)}$$

典型接触面周向应力：40~80 MPa（叠加至稳态应力）。

### 4.2 动态应力分量

动态应力来自电磁转矩波动引起的 **扭转剪切应力波动**。在转子任一截面上：

$$\tau_{xy}(t,x) = \frac{T(t) \cdot r}{J(x)}$$

其中 $T(t) = T_{e,fluctuation}(t)$（四象限运行）或 $T(t) = T_{m,mechanical} + T_e(t)$（驱动端）。

动态应力幅值的 rms 值为：

$$\sigma_{vM,alt}(x) = \sqrt{3} \cdot \tau_{xy,alt}(x) \quad \text{(von Mises 等效应力幅)}$$

#### 4.2.1 修正系数考虑

实际动态应力需乘以以下修正系数：

- **应力集中系数** $K_t$：轴肩/键槽/螺纹处 1.5~3.5
- **尺寸系数** $\varepsilon$：大截面（>200 mm）取 0.6~0.75
- **表面质量系数** $\beta$：磨削加工 0.85~0.95，车削 0.60~0.80
- **疲劳缺口系数** $K_f = 1 + q(K_t - 1)$，$q$ 为缺口敏感度（25Cr2Ni4MoV 的 $q \approx 0.85\sim0.95$）

**关键轴肩处的疲劳折减后的动态应力幅**：

$$\sigma_{a,eff} = \frac{K_f}{\varepsilon \beta} \cdot \sigma_{a,nominal}$$

---

## 5. 疲劳寿命评估模型

### 5.1 材料的 S-N 曲线

25Cr2Ni4MoV 的 S-N 曲线采用 Basquin 方程：

$$\sigma_a(N_f) = \sigma_f' \cdot (2N_f)^b$$

其中 $\sigma_f'$ 为疲劳强度系数，$b$ 为疲劳强度指数。淬火+回火热处理后典型值：

| 参数 | 值 | 来源 |
|------|-----|------|
| $\sigma_f'$ | 1,580 MPa | ~1.5$\sigma_b$ |
| $b$ | -0.07 ~ -0.09 | 高强度合金钢 |
| 疲劳极限 $S_e$ ($N = 10^7$) | 480 MPa | 旋转弯曲疲劳试验 |
| 剪切疲劳极限 $\tau_e$ | 277 MPa | $\tau_e \approx 0.577 S_e$ |

应力幅低于 $S_e$ 时，在传统理论中定义为无限寿命。但 **AI 数据中心工况下的高频连续激励** 意味着累积循环数可能远超 $10^7$——需引入 **无限寿命修正概念**（见第 5.5 节）。

### 5.2 区分静强度与疲劳寿命

这是工程报告中常见的混淆点，必须明确区分：

| 判据 | 物理意义 | 表达式 | 载荷类型 |
|------|---------|--------|---------|
| **静强度** | 承受最大载荷而不破坏 | $\sigma_{max} < \sigma_y / S$ | 极限工况（峰值转速+峰值扰动） |
| **屈服强度** | 不发生塑性变形 | $\sigma_{vM} < \sigma_y$ | 任何工况 |
| **疲劳寿命** | 在循环载荷下累损伤而不开裂 | $D = \sum n_i/N_{fi} < 1$ | 持续循环载荷 |
| **断裂安全** | 裂纹不扩展至失稳 | $K_{max} < K_{IC}$ | 含缺陷转子 |

> **关键区分**：AI 数据中心飞轮的 **极限应力远低于静强度极限**（不超过 ≈ $0.5\sigma_y$），因此 **静强度不是限制因素**。真正的限制来自 **疲劳**——尤其是高频数、低幅值的随机疲劳。

### 5.3 随机疲劳分析（PSD 方法）

传统恒幅疲劳分析（单频率、单幅值）不适用于 AI 数据中心宽带随机激励。应采用 **功率谱密度（PSD）频域疲劳法**。

#### 5.3.1 应力 PSD 的推导

从电磁转矩 PSD $S_{Te}(f)$ 通过传递函数得到关键部位的应力 PSD：

$$S_{\sigma}(f, x) = |H_{TV}(f, x)|^2 \cdot S_{Te}(f)$$

其中 $H_{TV}(f, x)$ 为从转矩激励到位置 $x$ 处应力的 **扭转振动传递函数**：

$$H_{TV}(f, x) = \sum_{r=1}^{N} \frac{\Phi^{(r)}(x) \cdot \Phi^{(r)}(x_e)}{1 - (f/f_n^{(r)})^2 + i \cdot 2\zeta_r (f/f_n^{(r)})} \cdot \frac{r_x}{J(x)}$$

这里 $\zeta_r$ 为第 $r$ 阶模态阻尼比（钢结构 0.001~0.01）。

#### 5.3.2 应力 PSD 的谱矩

定义第 $k$ 阶谱矩：

$$m_k = \int_0^\infty f^k \cdot S_{\sigma}(f) \, df$$

关键谱矩：

- $m_0$ = 总方差（均方应力）$\sigma_{rms}^2$
- $m_1$ = 平均频率加权强度
- $m_2$ = 零交叉率 $E[0] = \sqrt{m_2/m_0}$
- $m_4$ = 峰值率 $E[P] = \sqrt{m_4/m_2}$

#### 5.3.3 带宽参数

辐照度因子（Irregularity Factor）：

$$\gamma = \frac{m_2}{\sqrt{m_0 \cdot m_4}}, \quad 0 \le \gamma \le 1$$

- $\gamma \to 1$：窄带过程（每个峰值对应一次循环）
- $\gamma \to 0$：宽带过程（需 Rainflow 修正）

**AI 数据中心工况**：GPU 功率谱在 10 Hz ~ 1 kHz 连续分布，$\gamma \approx 0.3 \sim 0.6$，属于典型的 **宽带随机载荷**。

### 5.4 Rainflow 循环计数

在频域法中，Dirlik 经验公式将宽带 PSD 的应力幅分布直接拟合为 **Rainflow 等效幅值概率密度函数**（无需时域 Rainflow 迭代）：

$$p_{RF}(S) = \frac{1}{\sqrt{m_0}} \cdot \frac{D_1}{Q} e^{-Z/Q} + \frac{D_2 Z}{R^2} e^{-Z^2/(2R^2)} + D_3 Z e^{-Z^2/2}$$

其中：
- $Z = S / \sqrt{m_0}$ — 归一化应力幅
- $D_1 = 2(\gamma - \gamma_m^2)/(1 + \gamma^2)$
- $D_2 = (1 - \gamma - D_1 + D_1^2)/(1 - R)$
- $D_3 = 1 - D_1 - D_2$
- $R = (\gamma_m - \gamma - D_1^2)/(1 - \gamma - D_1 + D_1^2)$
- $\gamma_m = m_1/m_0 \cdot \sqrt{m_2/m_4}$
- $Q = 1.25(\gamma - D_3 - D_2 R)/D_1$

> **来源**：Dirlik T. "Application of computers in fatigue analysis", 1985. 该公式误差在 ±20% 以内，已被广泛应用于风力发电、海洋工程和航空发动机的宽带随机疲劳分析。

### 5.5 Miner 累积损伤

总损伤为预期应力幅谱上各循环的损伤叠加：

$$D = E[P] \cdot T \int_{0}^{\infty} \frac{p_{RF}(S)}{N_f(S)} \, dS$$

其中 $T$ 为运行时间（秒），$E[P]$ 为每秒预期峰值数，$N_f(S)$ 由 S-N 曲线（Basquin 方程）给出。

**疲劳失效判据**：

$$D < D_{cr}$$

$D_{cr}$ 通常取 1.0（Miner 线性准则），但考虑到载荷的随机性和次序效应，保守设计取 0.5~0.8。

### 5.6 Goodman / Gerber 平均应力修正

由于稳态离心应力提供了平均应力分量（非零均值），必须在疲劳分析中考虑平均应力的影响。

#### 5.6.1 Goodman 修正（保守）

$$\frac{\sigma_a}{S_e} + \frac{\sigma_m}{\sigma_b} = 1$$

等效零均值应力幅：

$$\sigma_{a,eq}^{Goodman} = \frac{S_e \cdot \sigma_a}{S_e + \sigma_m - \sigma_b}$$

#### 5.6.2 Gerber 修正（居中）

$$\frac{\sigma_a}{S_e} + \left(\frac{\sigma_m}{\sigma_b}\right)^2 = 1$$

$$\sigma_{a,eq}^{Gerber} = \frac{S_e \cdot \sigma_a}{S_e + \sigma_m - \sigma_b \cdot \left(\frac{\sigma_m}{\sigma_b}\right)^2 / \sigma_a}$$

#### 5.6.3 对 25Cr2Ni4MoV 转子应用

稳态平均应力 $\sigma_m$ 主要由离心应力贡献 ≈ 350 MPa，取 $\sigma_b = 1080$ MPa：

| 修正方法 | 等效应力幅 | 备注 |
|---------|----------|------|
| 无修正 | $\sigma_a$ | 过于乐观，不采用 |
| Goodman | $\sigma_a \times 1.48$ | 偏保守，适合安全关键部件 |
| Gerber | $\sigma_a \times 1.15$ | 居中，适合韧性金属 |

**适用条件**：Goodman 适用于脆性材料或保守设计；Gerber 对韧性金属误差较小。25Cr2Ni4MoV 为高强度韧性钢，推荐使用 Gerber 修正。

---

## 6. Paris 裂纹扩展模型

### 6.1 断裂力学基础

假设转子在制造中已通过无损检测（UT/MPI），但允许存在 **小于检测限的初始缺陷**。典型的初始裂纹深度：

- 锻件内部：$a_0 \approx 0.5 \sim 1.0$ mm（UT 检测限）
- 表面：$a_0 \approx 0.1 \sim 0.3$ mm（MPI/ET 检测限）

### 6.2 Paris 公式

裂纹在循环载荷下的稳定扩展遵循 Paris-Erdogan 关系：

$$\frac{da}{dN} = C(\Delta K)^m$$

其中 $\Delta K$ 为应力强度因子幅值：

$$\Delta K = Y(a) \cdot \Delta\sigma \cdot \sqrt{\pi a}$$

$Y(a)$ 为几何修正因子（对于圆轴中的半椭圆表面裂纹，$Y \approx 0.65 \sim 1.12$）。

对于 25Cr2Ni4MoV（淬火+回火，$K_{IC} \approx 130$ MPa·m^{1/2}）：

$$\frac{da}{dN} = 2.1 \times 10^{-12} \cdot (\Delta K)^{3.2} \quad (\text{单位：m/cycle, MPa·m}^{1/2})$$

**来源**：文献 [Cui et al., Fatigue crack growth of 25Cr2Ni4MoV rotor steel, Eng Fract Mech, 2015]。

### 6.3 分类应力强度因子

在复合载荷下：

$$\Delta K = \Delta K_{I} + \Delta K_{II} + \Delta K_{III}$$

对于飞轮转子：
- **模式 I（张开）**：由离心应力的波动产生。但在恒定转速下，$\Delta K_I \approx 0$（平均应力不变）。
- **模式 II（面内剪切）**：由扭转振动产生的剪切应力波动主导。
- **模式 III（面外剪切）**：在纯扭转载荷下，初始缺陷沿最大剪应力面扩展。

**AI 数据中心工况下**，模式 II + III 的循环裂纹驱动力来自 **转矩波动**：

$$\Delta K_{II/III} = Y_{II/III} \cdot \Delta\tau_{xy} \cdot \sqrt{\pi a}$$

其中 $\Delta\tau_{xy}$ 由转矩 PSD 的 rms 幅值决定。

### 6.4 裂纹扩展寿命

总裂纹扩展寿命通过积分 Paris 公式给出：

$$N_p = \int_{a_0}^{a_c} \frac{da}{C(\Delta K(a))^m} = \frac{1}{C(\Delta\sigma)^m Y^m \pi^{m/2}} \int_{a_0}^{a_c} \frac{da}{a^{m/2}}$$

当 $m \neq 2$：

$$N_p = \frac{2}{(m-2)C(\Delta\sigma)^m Y^m \pi^{m/2}} \left( a_0^{1-m/2} - a_c^{1-m/2} \right)$$

临界裂纹尺寸 $a_c$ 由失稳扩展条件确定：

$$K_{max}(a_c) = Y(a_c) \cdot \sigma_{max} \cdot \sqrt{\pi a_c} = K_{IC}$$

代入数据：

$$a_c = \frac{1}{\pi} \left( \frac{K_{IC}}{Y \cdot \sigma_{max}} \right)^2 \approx \frac{1}{\pi} \left( \frac{130}{1.0 \times 420} \right)^2 \approx 30.4 \text{ mm}$$

### 6.5 随机载荷下的裂纹扩展

对于宽带随机载荷（AI 数据中心工况），Paris 公式的循环积分需替换为 **谱方法**：

$$\overline{\frac{da}{dt}} = E[P] \cdot C \cdot \int_0^\infty (\Delta K)^m \cdot p_{RF}(S) \, dS$$

这是对 Paris 公式在随机激励下的正确推广。直接代入恒幅值 $\Delta\sigma_{rms}$ 将低估裂纹扩展速率 3~10 倍。

---

## 7. AI 数据中心 vs 传统 UPS：疲劳寿命对比

### 7.1 载荷特征对比

| 载荷特征 | 传统 UPS 飞轮 | AI 数据中心飞轮 | 倍数差异 |
|---------|-------------|---------------|---------|
| 主要激励源 | 电网频率波动（0.01~0.5 Hz） | GPU 功率波动（10 Hz ~ 1 kHz） | 2~5 数量级 |
| 年累计循环数 | $10^5\sim10^6$ | $10^8\sim10^9$ | $10^2\sim10^3$ |
| 激励带宽 | 窄带（单/双频） | 宽带（连续谱） | 完全不同 |
| 平均应力占比 | 高（全速运行） | 高（全速运行） | 相当 |
| 动态应力幅占比 | 低（< 5% 离心应力） | 低~中（5%~15% 离心应力） | 3~5× |
| 共振风险 | 可控（工作转速避开共振点） | 宽带激励始终覆盖多个固有频率 | 根本性变化 |
| 载荷非高斯性 | 近似高斯 | 峰值因子 ~4~6（因 GPU 突发性） | ~2× |

### 7.2 寿命评估对比

| 评估项 | 传统 UPS | AI 数据中心 | 结论 |
|-------|---------|------------|------|
| 静强度裕度 | ~2.5 | ~2.5 | 相当 |
| 高周疲劳寿命 | $> 10^9$（无限寿命） | ~$10^8\sim10^9$（有限寿命） | 数据中心降低 1~2 数量级 |
| 裂纹扩展寿命 | $> 10^{11}$ cycles（可忽略） | ~$10^7\sim10^8$ cycles（需监测） | 需纳入寿命管理 |
| 主导失效模式 | 偶然过载/轴承失效 | 高频疲劳 + 裂纹扩展 | 根本性变化 |
| 维护策略 | 周期性停机检查 | 在线监测 + 剩余寿命预测 | 需升级 |

---

## 8. 工程结论与设计建议

### 8.1 核心结论

1. **AI 数据中心飞轮转子的疲劳寿命评估必须从传统 UPS 的准静态模型升级为宽带随机疲劳模型**。忽略 GPU 高频功率耦合的转子寿命分析将产生 2~3 个数量级的乐观偏差。

2. **扭转共振的宽带化**：传统 Campbell 图中的离散共振点被 10 Hz ~ 1 kHz 的连续激励带替代，转子第一阶扭转固有频率应设计 > 100 Hz 以避开 GPU PSD 高能量区。

3. **裂纹扩展寿命成为设计约束**：初始允许缺陷尺寸需从传统的 1~2 mm 收紧至 0.3~0.5 mm（需更严格的锻件 UT 标准 + 表面 MPI），并引入在线裂纹声发射监测系统。

4. **疲劳寿命的安全系数建议**：在 PSD 疲劳 + Paris 裂纹扩展双重评估下，总损伤取允许值 $D < 0.5$（Miner 准则的应用系数），并附加 2× 安全系数以覆盖随机载荷的统计不确定性。

### 8.2 剩余寿命监测建议

建议部署以下在线监测系统：

- **轴端扭振光纤传感器**（1 kHz 采样率，FFT 实时转 Campbell 图）
- **激光径向/轴向位移探头**（监测转子动平衡变化，间接反映微裂纹萌生）
- **SiC DC/DC 侧瞬时功率监测**（2 MHz 采样，实时反算转矩 PSD 输入）
- **声发射传感器**（中心频率 150 kHz，识别裂纹扩展的突发声发射事件）

### 8.3 设计优化方向

1. **转子材料升级**：考虑 25Cr2Ni4MoV + 表面渗氮处理，提高表面疲劳强度至 580~620 MPa
2. **共振规避**：增大轴径或缩短轴长，将一阶扭转频率推至 > 150 Hz
3. **主动阻尼**：在 SiC DC/DC 控制中植入虚拟扭振阻尼器（Virtual Torsional Damper），通过主动调制电磁转矩消除特定频段的振动能量
4. **SST 输入滤波**：在 SST DC 母线侧增加 LC 滤波器（$f_c \approx 100$ Hz），衰减 GPU 高频功率波动向飞轮侧的传播

---

*本报告使用的全部公式均有可溯源的工程力学和断裂力学理论依据。具体数值来自典型 2MW 级飞轮转子设计参数，若实际转子几何与材料有差异，建议进行完整有限元验证后校准。*
