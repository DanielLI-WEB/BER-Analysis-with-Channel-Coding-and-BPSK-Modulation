function [ber, numBits] = BER_BPSK_Conv_AWGN(EbNo, maxNumErrs, maxNumBits)

% Fixed parameter configuration
K = 7;                  % constraint length
genPoly = [171 133];    % Generating polynomial
trellis = poly2trellis(K, genPoly); % Generate grid structure
blockSize = 30;          %signal size

% Initialize the BER vector
ber = zeros(size(EbNo));

% Create the necessary System objects
conEnc = comm.ConvolutionalEncoder(...
    'TrellisStructure', trellis, ...
    'TerminationMethod', 'Terminated');
modDPSK = comm.BPSKModulator;
chan = comm.AWGNChannel('EbNo',EbNo);
demodDPSK = comm.BPSKDemodulator;
vDec = comm.ViterbiDecoder(...
    'TrellisStructure', trellis, ...
    'TerminationMethod', 'Terminated', ...
    'InputFormat','Hard');
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

        encodedData = conEnc(data);
        modSignal = modDPSK(encodedData);
        receivedSignal = chan(modSignal);
        demodSignal = demodDPSK(receivedSignal);
        receivedBits = vDec(demodSignal);

        % Extract valid bits
        receivedBits_valid = receivedBits(1:length(data));

        % Update error statistics
        stats = error(data, receivedBits_valid);
        numErrs = stats(2); 
        numBits = stats(3); 
    end
    ber(idx) = stats(1);
end
% Release
release(conEnc);
release(modDPSK);
release(chan);
release(demodDPSK);
release(vDec);
release(error);
end
