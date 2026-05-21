// 模板测试 — 现代极简工业风
#import "industrial-whitepaper-template.typ": industrial-whitepaper, tbl-bottom

#show: industrial-whitepaper.with(
  cover-title: "飞轮转子结构完整性论证报告",
  cover-subtitle: "AI 万卡 GPU 集群直流母线应用场景 · V1.1",
  cover-meta: (
    "编制单位": "北京泓慧国际能源技术发展股份有限公司",
    "日期": "2026-05-21",
    "版本": "V1.1",
    "密级": "内部资料",
  ),
)

= 绪论

本报告针对 AI 万卡 GPU 集群直流母线场景下的飞轮储能系统转子结构完整性进行评估。基准转子直径 430 mm，材料 25Cr2Ni4MoV，最高转速 20,000 rpm。

飞轮储能系统在 AI 数据中心场景下，面临与传统 UPS 完全不同的负载特征。GPU 计算尖峰引起的大幅值随机电磁转矩激励（10 Hz—10 kHz），对转子疲劳寿命和结构完整性提出了新的挑战。

传统飞轮储能系统的工况以短时大功率放电（UPS模式：15—30 s）或慢速功率调节（电网调频：分钟级）为主。AI 数据中心场景中，GPU Compute Spikes 的功率波动幅度可达额定值的 60%，波动频带覆盖机械共振区。

= 转子结构与材料

采用 25Cr2Ni4MoV 高强度合金钢整体锻造转子。材料参数如下：

=== 材料化学成分

#table(
  columns: (auto, auto, auto, auto, auto),
  table.header(
    [元素], [C], [Si], [Mn], [Cr],
  ),
  [含量 (%)], [0.22], [0.25], [0.35], [1.85],
)

#tbl-bottom(5)

=== 力学性能

屈服强度 $sigma_s >= 800 "MPa"$，抗拉强度 $sigma_b >= 950 "MPa"$，断裂韧性 $K_("IC") >= 100 "MPa"·m^(1/2)$。

= 有限元分析

转子在 20,000 rpm 下的最大等效应力为：

$ sigma_max = 657 "MPa" $

安全系数：

$ n = frac(sigma_s, sigma_max) = frac(800, 657) = 1.24 $

== 疲劳寿命分析

使用 Paris 公式计算裂纹扩展：

$ frac(d a, d N) = C (Delta K)^m $

其中 Delta K 应力强度因子幅：

$ Delta K = 1.38 "MPa"·m^(1/2) $

对比门槛值 5—8 MPa·m^(1/2)，$Delta K << Delta K_("th")$，裂纹不扩展。
