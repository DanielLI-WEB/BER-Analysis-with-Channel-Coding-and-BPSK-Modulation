function [ber, numBits] = BER_BPSK_AWGN(EbNo, maxNumErrs, maxNumBits,varargin)

% Fixed parameter configuration
blockSize = 30;

% Initialize the BER vector
ber = zeros(size(EbNo));

% Create the necessary System objects
persistent modBPSK chan demodBPSK error
if isempty(modBPSK)
modBPSK = comm.BPSKModulator;
chan = comm.AWGNChannel('EbNo',EbNo);
demodBPSK = comm.BPSKDemodulator;
error = comm.ErrorRate;
end

% Calculation BER
for idx = 1:length(EbNo)
    chan.EbNo = EbNo(idx);
    reset(error)
    numErrs = 0;
    numBits = 0;
    while numErrs < maxNumErrs && numBits < maxNumBits
        % Check if the user clicked the stop button of BERTool
        if isBERToolSimulationStopped(varargin{:})
            break
        end
        % Generate random information bits
        data = randi([0 1], blockSize, 1);
        modSignal = modBPSK(data);
        receivedSignal = chan(modSignal);
        demodSignal = demodBPSK(receivedSignal);


        % Error Statistics
        stats = error(data, demodSignal);
        numErrs = stats(2);
        numBits = stats(3);
    end
    ber(idx) = stats(1);
end
% Release resources
release(modBPSK);
release(chan);
release(demodBPSK);
release(error);
end