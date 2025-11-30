function [ber, numBits] = BER_BPSK_AWGN(EbNo, maxNumErrs, maxNumBits, varargin)
% 核心功能：依赖BERTool调用的BPSK-AWGN误码率仿真函数
% 适配BERTool要求：参数格式、停止检测完全兼容
rng(10, "twister");

% 持久化信道和误码统计对象（提升仿真效率）
persistent AWGNChannel BitErrCalc
if isempty(AWGNChannel)
    AWGNChannel = comm.AWGNChannel;  % AWGN信道对象（题目要求的系统对象）
    BitErrCalc = comm.ErrorRate;     % 误码率统计对象（题目要求的系统对象）
end

% 初始化误码统计变量
berVec = zeros(3, 1);
FRM = 10000;  % 每帧比特数（兼顾速度与统计精度）

% 关键：释放信道对象，修改不可调属性（EbNo），避免报错
release(AWGNChannel);
AWGNChannel.EbNo = EbNo;                % BERTool传入的当前信噪比
AWGNChannel.NoiseMethod = 'Signal to noise ratio (Eb/No)';  % 有效属性

% 核心仿真循环（响应BERTool的停止按钮）
while ((berVec(2) < maxNumErrs) && (berVec(3) < maxNumBits))
    % 检测BERTool的"手动停止"按钮，点击后中断仿真（BERTool依赖关键）
    if nargin >= 4 && isBERToolSimulationStopped(varargin{:})
        break;
    end
    
    txBits = randi([0, 1], FRM, 1);      % 生成随机二进制比特
    txSig = pskmod(txBits, 2);           % BPSK调制（替代旧系统对象，无警告）
    rxSig = AWGNChannel(txSig);          % 信号通过AWGN信道（加噪声）
    rxBits = pskdemod(rxSig, 2);         % BPSK解调（与调制匹配）
    berVec = BitErrCalc(txBits, rxBits); % 累计误码统计
end

% 向BERTool返回结果（BERTool会自动收集所有Eb/No的BER）
ber = berVec(1);         % 当前Eb/No对应的误码率
numBits = berVec(3);     % 当前Eb/No处理的总比特数
reset(BitErrCalc);       % 重置统计对象，避免缓存影响下次调用（BERTool循环时关键）
end