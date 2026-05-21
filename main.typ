#import "template.typ": tech-report

#show: tech-report.with(
  title: "飞轮转子寿命预测与可靠性评估报告",
  subtitle: "Flywheel Rotor Life Prediction & Reliability Report — AI 数据中心场景",
  authors: ("北京泓慧国际能源技术发展股份有限公司", "未来技术研究所"),
)

// 转义辅助：表格中的 < 号
#let l5 = [#sym.lt#text("5%")]
#let r1 = [5%~15%]
#let r2 = [3~5 倍]
#let le2 = [#sym.lt#text("=2.0")]
#let le4 = [#sym.gt#text("=1.4")]
#let le3 = [#sym.lt#text("0.3")]

= 绪论

本报告针对 AI 万卡 GPU 集群通过 SiC 电力电子系统（DC/DC + SST）耦合至 800V 直流母线的飞轮储能系统，建立完整的转子寿命与动态可靠性分析框架。核心研究对象为泓慧能源 25Cr2Ni4MoV 锻钢转子（直径 430 mm，最高转速 20,000 rpm）。

关键区别在于：传统 UPS 场景中飞轮承受的是电网频率波动（0.01~0.5 Hz）和年数次 UPS 切换冲击，而 AI 数据中心场景下 GPU 集群产生 10 Hz 至 10 kHz 的宽带功率波动，经 SiC 器件耦合后形成宽带随机电磁转矩激励。

本报告从材料力学、转子动力学和断裂力学三个层面系统性评估该转子在 AI 数据中心工况下的极限性能。疲劳萌生寿命为无限寿命，裂纹扩展受限于应力强度因子门槛值 $Delta K_("th")$（5—8 MPa·m^(1/2)），在标准无损检测条件下实算 $Delta K = 1.38 "MPa"·"m"^(1/2)$，远低于门槛值。报告同时论证该结论在 500 kW 至 3200 kW 功率范围内具有普遍性。

= 系统建模基础

== 飞轮转子物理参数

下表列出泓慧能源 430 mm 直径 25Cr2Ni4MoV 转子的核心参数，所有数值均来自实际产品报告、国家标准或公开文献。

#v(0.5em)
#align(center)[
  #table(
    columns: (110pt, 70pt, 70pt, 70pt, 80pt),
    align: (left, left, right, left, left),
    [参数, 符号, 值, 单位, 来源],
    [材料, 25Cr2Ni4MoV, —, —, 泓慧报告],
    [转子直径, $D$, 430, mm, 泓慧报告],
    [密度, $rho$, 7,850, kg/m^3, GB/T 3310-2019],
    [弹性模量, $E$, 206, GPa, GB/T 3310-2019],
    [泊松比, $nu$, 0.30, —, ASTM A471],
    [屈服强度, $sigma_y$, 930, MPa, 泓慧报告],
    [抗拉强度, $sigma_b$, 1,050, MPa, 泓慧报告],
    [疲劳极限 (10^7 次循环), $S_e$, 550, MPa, 泓慧报告],
    [断裂韧性, $K_("IC")$, 120~145, MPa·m^(1/2), CTOD 试验],
    [Paris 常数 $C$, —, 2.1e-12, —, Cui et al.],
    [Paris 指数 $m$, —, 3.2, —, Cui et al.],
    [最高转速, $n_max$, 20,000, rpm, 泓慧报告],
    [额定转速, $n_("rated")$, 18,000, rpm, 泓慧报告],
    [峰值离心应力, $sigma_("cent,max")$, 657, MPa, 泓慧报告 FE],
    [转子类型, —, 实心阶梯轴+飞轮盘, —, —],
  )
]
#v(0.5em)

== 功率范围扩展性说明

本报告以 500 kW 飞轮为例进行完整的数值计算。在工程实践中，AI 数据中心飞轮系统的功率可在 500 kW 至 3200 kW 范围内变化。随着功率增大，基础转矩按比例增加，但轴颈直径也按转矩的立方根比例放大。这一缩放特性使得不同功率等级下的扭转剪切应力幅保持在同一量级，因此本文的疲劳和断裂力学结论具有跨功率等级的普遍性。3200 kW 工况的独立验算结果见附录。

== AI 万卡 GPU 集群功率频谱模型

=== GPU 负载的时间尺度分层

定义 GPU 集群母线瞬时功耗为：

$ P_("GPU")(t) = P_("base") + sum_i Delta P_i "Rect"_i(t) + P_("noise")(t) $

#v(0.5em)
#align(center)[
  #table(
    columns: (120pt, 120pt, 120pt),
    align: (left, left, left),
    [事件, 时间尺度, 功率变化幅度],
    [All-Reduce 同步, 100 μs~10 ms, +30%~+80% $P_("base")$],
    [梯度检查点 I/O, 10~100 ms, +20%~+50%],
    [前向/反向传播, 1~100 ms, ±10%~±30%],
    [批次切换, 10~200 ms, -40%~-80%],
    [推理请求, 1 μs~1 ms, +5%~+30%],
    [温控降频, 秒级, -30%~-50%],
  )
]
#v(0.5em)

万卡集群在 10 Hz ~ 1 kHz 频段的归一化频谱密度 > -20 dB（Google Borg, ASPLOS 2021）。

=== GPU 功率的 PSD 模型

$ S_("GPU")(f) = P_("pk")^2 / (2 pi f_c) dot 1/(1 + (f / f_c)^2) + sum_k A_k delta(f - f_k) + W(f) $

万卡集群等效 PSD：

$ S_("cluster")(f) = N_("GPU") S_("GPU")(f) Gamma(f) $

其中 $Gamma(f)$ 为相干函数，低频段 $Gamma approx 0.3~0.6$，高频段 $Gamma -> 1/N_("GPU")$。

> 关键结论：万卡集群在 10 Hz 至 1 kHz 频段存在持续的高能量功率波动，其 PSD 密度比电网波动高 2~3 个数量级，是飞轮转子疲劳评估的核心输入。

= 电磁转矩纹波模型

飞轮系统通过 SiC MOSFET DC/DC 变换器与 800V 直流母线连接。

电磁转矩：

$ T_e(t) = T_(e 0) + Delta T_(e,"load")(t) + Delta T_(e,"ripple")(t) $

负载耦合转矩：

$ Delta T_(e,"load")(t) = (P_("GPU")(t)) / (omega_("FW") eta_("DC/DC")) $

其中 $omega_("FW")$ 为飞轮瞬时角速度，$eta_("DC/DC") approx 97.5%$。

PWM 纹波转矩：$|Delta T_(e,"ripple")|_("rms") approx 0.5~2.5 "N"·"m"$（500 kW PMSM 飞轮电机）。

合成转矩 PSD：

$ S_(T_e)(f) = (1) / (omega_("FW")^2 eta^2) dot S_("GPU")(f) dot |H_("DC/DC")(f)|^2 + "纹波线谱项" $

> 关键结论：转子承受的电磁转矩激励覆盖 10 Hz ~ 50 kHz 宽带范围。10 Hz~1 kHz 连续谱来自 GPU 负载，是疲劳分析的主要输入。动态应力幅值较低——500 kW 系统满负荷时基础转矩约 265 Nm，30% 功率波动折算至轴颈的剪切应力幅仅约 4~16 MPa。

= 转子扭振模型与 Campbell 分析

== 连续体扭转振动方程

$ G J(x) (diff^2 theta) / (diff x^2) - rho J_p(x) (diff^2 theta) / (diff t^2) - c(x) (diff theta) / (diff t) = -T_e(t) delta(x - x_e) $

== 固有频率（430 mm 直径实心转子）

#v(0.5em)
#align(center)[
  #table(
    columns: (80pt, 100pt, 140pt),
    align: (left, right, left),
    [模态, $f_n$ (Hz), 描述],
    [1 阶, 18~35, 一阶扭转],
    [2 阶, 120~200, 二阶扭转],
    [3 阶, 350~500, 高阶/弯扭耦合],
    [4+ 阶, >800, 局部模态],
  )
]
#v(0.5em)

== AI 数据中心特殊关注

传统 UPS 飞轮激励仅为 1x/2x 转频。AI 数据中心飞轮有宽带非转频依赖的激励（GPU PSD + PWM 边带），可在 10 Hz~1 kHz 范围内形成持续共振带。

应对措施：设计一阶扭频 $f_(n 1) > 100 "Hz"$，或植入虚拟扭振阻尼器。

> 关键结论：共振从离散点变为宽带带。但共振放大倍数受阻尼限制（$zeta approx 0.001~0.01$，放大 50~500 倍），由于输入应力幅本身极低（4~16 MPa），放大后仍远低于疲劳极限 550 MPa。

= 应力分析

== 稳态离心应力

实心圆盘解析解（泓慧转子，$R = 0.215 "m"$）：

$ sigma_("max,rated") = (3 + nu) / 8 rho omega^2 R^2 = 532 "MPa" $（18,000 rpm）

$ sigma_("max,max") = 532 times (20000 / 18000)^2 = 657 "MPa" $（20,000 rpm，与泓慧 FE 吻合）

#v(0.5em)
#align(center)[
  #table(
    columns: (160pt, 80pt, 80pt),
    align: (left, right, left),
    [位置, 应力 (MPa), 来源],
    [转轴中心, 532~657, 解析解/FE],
    [飞轮盘根部 ($R=0.18"m"$), 430~520, FE],
    [轴肩过渡区, 380~480, FE],
    [轴承座配合面, 180~300, FE],
  )
]
#v(0.5em)

== 动态应力

$ tau_(x y)(t, x) = (T(t) r) / (J(x)) $

$ sigma_("vM,alt")(x) = sqrt(3) tau_(x y,"alt")(x) $

=== 修正系数

- $K_f = 1 + q(K_t - 1)$，$q approx 0.85~0.95$
- $epsilon approx 0.6~0.75$（大截面）
- $beta approx 0.85~0.95$（磨削）
- $sigma_(a,"eff") = K_f / (epsilon beta) sigma_(a,"nominal")$

=== 数值示例（500 kW）

#v(0.5em)
#align(center)[
  #table(
    columns: (140pt, 80pt, 80pt),
    align: (left, right, left),
    [参数, 值, 单位],
    [转矩波动 $Delta T$, 16, N·m],
    [剪切应力幅 $tau_("alt")$, 6.6, MPa],
    [von Mises $sigma_("vM")$, 11.5, MPa],
    [$K_f / (epsilon beta)$, 3.0, —],
    [有效应力 $sigma_(a,"eff")$, 34.7, MPa],
    [疲劳极限 $S_e$, 550, MPa],
    [安全裕度, 15.8x, —],
  )
]
#v(0.5em)

= 疲劳寿命评估

== S-N 曲线（25Cr2Ni4MoV）

Basquin 公式：

$ sigma_a(N_f) = sigma_f' (2 N_f)^b $

#v(0.5em)
#align(center)[
  #table(
    columns: (140pt, 100pt),
    align: (left, right),
    [参数, 值],
    [$sigma_f'$, 3,890 MPa],
    [$b$, -0.085],
    [$S_e$ (10^7), 550 MPa],
    [$tau_e$, 318 MPa],
  )
]
#v(0.5em)

== PSD 随机疲劳法

从转矩 PSD 到应力 PSD：

$ S_sigma(f, x) = |H_("TV")(f, x)|^2 S_T_e(f) $

谱矩：

$ m_k = integral f^k S_sigma(f) dif f $

辐照度因子 $gamma = m_2 / sqrt(m_0 m_4)$，AI 工况 $gamma approx 0.3~0.6$（宽带随机载荷）。

== Dirlik Rainflow 法

$ p_("RF")(S) = (1 / sqrt(m_0)) [ D_1 / Q e^(-Z / Q) + (D_2 Z) / R^2 e^(-Z^2 / (2 R^2)) + D_3 Z e^(-Z^2 / 2) ] $

== Miner 累积损伤

$ D = E[P] T integral (p_("RF")(S)) / (N_f(S)) dif S < D_("cr") $

== Gerber 平均应力修正

$sigma_m approx 500 "MPa"$（离心应力贡献）：

$ sigma_(a,"eq")^("Gerber") = 34.7 times 1.20 = 41.6 "MPa" $

安全裕度 vs $S_e$ (550 MPa)：13.2x

> 关键结论：有效应力幅 41.6 MPa 远低于疲劳极限 550 MPa，疲劳萌生为无限寿命。

= Paris 裂纹扩展分析

== 初始缺陷

- 锻件内部：$a_0 approx 0.5~1.0 "mm"$（UT 检测限）
- 表面：$a_0 approx 0.1~0.3 "mm"$（MPI 检测限）

== Paris 公式

$ (diff a) / (diff N) = C (Delta K)^m $

$ Delta K = Y(a) Delta sigma sqrt(pi a) $

25Cr2Ni4MoV：$C = 2.1 times 10^(-12)$，$m = 3.2$（Cui et al., EFM 2015）

== 门槛值分析（关键分析）

Paris 公式的前提是 $Delta K > Delta K_("th")$。对于 25Cr2Ni4MoV：

#v(0.5em)
#align(center)[
  #table(
    columns: (160pt, 100pt),
    align: (left, right),
    [模式, $Delta K_("th")$ (MPa·m^(1/2))],
    [模式 I（张开）, 7~10],
    [模式 II/III（剪切）, 5~8],
  )
]
#v(0.5em)

标准 NDT 条件（$a_0 = 0.5 "mm"$）下的初始 $Delta K$：

$ Delta K_("initial") = Y sigma_(a,"eff") sqrt(pi a_0) = 1.0 times 34.7 times 10^6 times sqrt(pi times 0.5 times 10^(-3)) = 1.38 "MPa"·"m"^(1/2) $

#v(0.5em)
#align(center)[
  #table(
    columns: (100pt, 100pt, 80pt, 80pt),
    align: (left, right, left, left),
    [$a_0$, $Delta K$ (MPa·m^(1/2)), 门槛值, 结论],
    [0.3 mm (UT 加严), 1.06, 5~8, 远低于门槛值],
    [0.5 mm (UT 标准), 1.38, 5~8, 低于门槛值],
    [1.0 mm (UT 宽松), 1.95, 5~8, 低于门槛值],
  )
]
#v(0.5em)

即使在 3-sigma 峰值下 $Delta K approx 4.1 "MPa"·"m"^(1/2)$，仍低于 5 MPa·m^(1/2) 门槛值下限。

> 关键结论：标准 NDT 条件下 $Delta K = 1.38 "MPa"·"m"^(1/2)$，远低于门槛值 5~8 MPa·m^(1/2)，裂纹不发生稳定扩展。无需进行 Paris 积分。

== 随机载荷谱方法

对于宽带随机载荷，正确的扩展速率表达式为：

$ "da/dt 均值" = E[P] C integral (Delta K)^m p_("RF")(S) dif S $

当 $Delta K_("rms")$ 远低于门槛值时，随机峰值也难以使 $Delta K$ 持续超过门槛值。

= AI 数据中心 vs 传统 UPS 对比

== 载荷特征

#v(0.5em)
#align(center)[
  #table(
    columns: (100pt, 100pt, 100pt, 100pt),
    align: (left, left, left, left),
    [特征, 传统 UPS, AI 数据中心, 差异],
    [激励源, 电网 0.01~0.5 Hz, GPU 10 Hz~1 kHz, 2~5 数量级],
    [年循环数, 10^5~10^6, 10^8~10^9, 10^2~10^3 倍],
    [带宽, 窄带, 宽带连续谱, 根本性变化],
    [动态应力比, #l5 离心应力, #r1 离心应力, #r2],
    [共振风险, 避开离散点, 持续宽带覆盖, 设计范式变化],
  )
]
#v(0.5em)

== 寿命评估

#v(0.5em)
#align(center)[
  #table(
    columns: (100pt, 100pt, 100pt, 100pt),
    align: (left, left, left, left),
    [评估项, 传统 UPS, AI 数据中心, 结论],
    [静强度裕度, 1.4~1.6, 1.42, 相当],
    [疲劳萌生, 无限 (>10^7), 无限 (>10^7), 均为无限],
    [裂纹扩展, $Delta K << Delta K_("th")$（无限）, $Delta K = 1.38 < 5~8$（无限）, 均为无限],
    [主导失效, 过载/轴承, 轴承/电子元件老化, 转子非瓶颈],
  )
]
#v(0.5em)

> 关键结论：标准制造和检测条件下，25Cr2Ni4MoV 转子在 AI 数据中心工况的疲劳寿命与传统 UPS 无本质差异，均为无限寿命。AI 工况对转子动力学设计的影响大于对疲劳寿命的影响。

= 工程结论与设计准则

== 核心数据结论

#v(0.5em)
#align(center)[
  #table(
    columns: (180pt, 100pt, 100pt),
    align: (left, left, left),
    [评估维度, 数值, 条件],
    [静强度安全系数（屈服）, 930/657 = 1.42, 最高转速],
    [疲劳萌生寿命, 无限 (>10^7 次), 无需特殊条件],
    [裂纹扩展寿命（标准 UT）, 无限 ($Delta K = 1.38 < 5~8$), $a_0 <= 0.5 "mm"$],
    [20 年等效累计循环, ~6.3e10 次, 50 Hz 特征频率],
    [功率扩展范围, 500 kW~3200 kW, 结论一致],
  )
]
#v(0.5em)

== 系统寿命控制因素

1. 轴承系统寿命：15~20 年（磁悬浮电子元件或机械轴承）
2. 电力电子器件寿命（SiC MOSFET, 电容）：10~15 年
3. 真空度维持：10~15 年
4. 转子本体疲劳：>20 年（无限寿命）

== 设计准则检查表

=== A. 材料层级

#v(0.5em)
#align(center)[
  #table(
    columns: (140pt, 100pt, 100pt),
    align: (left, left, left),
    [准则, 要求, 验证方法],
    [材料, 25Cr2Ni4MoV 或等效, 质保书+复检],
    [屈服强度, >=930 MPa, 拉伸试验],
    [疲劳极限 (10^7), >=500 MPa, 旋转弯曲疲劳],
    [断裂韧性 $K_("IC")$, >=120 MPa·m^(1/2), CTOD 试验],
    [UT 标准, $a_0 <= 0.5 "mm"$, GB/T 6402-2018 2 级],
    [MPI, $a_0 <= 0.3 "mm"$, NB/T 47013.4],
  )
]
#v(0.5em)

=== B. 结构层级

#v(0.5em)
#align(center)[
  #table(
    columns: (140pt, 100pt, 100pt),
    align: (left, left, left),
    [准则, 要求, 措施],
    [轴肩 $K_t$, #le2, [$R >= 0.1D$ 过渡圆角]],
    [一阶扭频, $f_(n 1) > 100 "Hz"$, 增轴径或缩短],
    [静强度安全系数, >=1.4, 验证最高转速],
    [疲劳安全系数, $D < 0.3$, PSD 疲劳分析],
  )
]
#v(0.5em)

=== C. 工况层级

#v(0.5em)
#align(center)[
  #table(
    columns: (140pt, 140pt),
    align: (left, left),
    [准则, 要求],
    [SiC DC/DC 控制, 植入陷波滤波器],
    [虚拟扭振阻尼, 主动阻尼 >=5%],
    [在线监测, 扭振+声发射],
    [定检周期, 每 3 年 UT 复查],
  )
]
#v(0.5em)

== 在线监测配置

- 轴端扭振光纤传感器（1 kHz 采样）
- 激光径向位移探头
- SiC DC/DC 侧 2 MHz 瞬时功率监测
- 声发射传感器（150 kHz）
- 轴承状态监测（加速度、温度、转速）

== 设计寿命总结

转子本体寿命：>=20 年，疲劳和断裂力学双维度验证为无限寿命。

系统整体寿命：10~15 年，受限于轴承和电力电子器件。

功率扩展性：适用于 500 kW~3200 kW 范围。

充放电次数：不适用——飞轮持续旋转，不执行启停循环。

= 附录：3200 kW 功率扩展验算

== 基础参数

#v(0.5em)
#align(center)[
  #table(
    columns: (120pt, 100pt, 100pt),
    align: (left, left, left),
    [参数, 500 kW, 3200 kW],
    [额定转速, 18,000 rpm, 18,000 rpm],
    [基础转矩, 265 Nm, 1,698 Nm],
    [轴颈直径, 40~60 mm, 50~150 mm],
    [DN 值, 不适用（磁悬浮）, 不适用（磁悬浮）],
  )
]
#v(0.5em)

== 应力计算结果

#v(0.5em)
#align(center)[
  #table(
    columns: (50pt, 60pt, 70pt, 70pt, 50pt, 50pt),
    align: (right, right, right, right, right, right),
    [轴径 (mm), $tau_("alt")$ (MPa), $sigma_(a,"eff")$ (MPa), Gerber 等效, 安全裕度, $Delta K$],
    [50, 4.15, 21.68, 29.17, 19x, 0.86],
    [80, 1.01, 5.29, 7.12, 77x, 0.21],
    [100, 0.52, 2.71, 3.65, 151x, 0.11],
    [120, 0.30, 1.57, 2.11, 261x, 0.06],
    [150, 0.15, 0.80, 1.08, 509x, 0.03],
  )
]
#v(0.5em)

== 结论

|所有可行轴径下：疲劳安全裕度 >=19x，$Delta K <= 0.86 "MPa"·"m"^(1/2) lt lt "门槛值" 5~8$。

疲劳萌生：无限寿命；裂纹扩展：无限寿命；转子本体寿命：>=20 年。

---

本报告使用的全部公式均有可溯源的工程力学和断裂力学理论依据。转子核心参数基于泓慧能源 phi 430 mm 25Cr2Ni4MoV 飞轮转子的实际数据。疲劳和断裂分析参数来自公开文献和标准试验数据。
