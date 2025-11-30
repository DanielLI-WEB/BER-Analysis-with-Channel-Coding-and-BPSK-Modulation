function [ber, numBits] = BER_BPSK_AWGN(EbNo, maxNumErrs, maxNumBits)

% Fixed parameter configuration
blockSize = 30;

% Initialize the BER vector
ber = zeros(size(EbNo));

% Create the necessary System objects
modDPSK = comm.BPSKModulator;
chan = comm.AWGNChannel('EbNo',EbNo);
demodDPSK = comm.BPSKDemodulator;
error = comm.ErrorRate;

% Calculation BER
for idx = 1:length(EbNo)
    chan.EbNo = EbNo(idx);
    reset(error)
    numErrs = 0;
    numBits = 0;
    while numErrs < maxNumErrs && numBits < maxNumBits
        % Generate random information bits
        data = randi([0 1], blockSize, 1);
        modSignal = modDPSK(data);
        receivedSignal = chan(modSignal);
        demodSignal = demodDPSK(receivedSignal);


        % Error Statistics
        stats = error(data, demodSignal);
        numErrs = stats(2);
        numBits = stats(3);
    end
    ber(idx) = stats(1);
end
% Release resources
release(modDPSK);
release(chan);
release(demodDPSK);
release(error);
end
