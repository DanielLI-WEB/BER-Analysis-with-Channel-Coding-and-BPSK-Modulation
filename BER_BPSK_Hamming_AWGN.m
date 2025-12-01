function [ber, numBits] = BER_BPSK_Hamming_AWGN(EbNo, maxNumErrs, maxNumBits)

% Fixed parameter configuration
M = 2;                  % DPSK modulation order
blockSize = 30;

% Initialize the BER vector
ber = zeros(size(EbNo));

% Create the necessary System objects
modBPSK = comm.BPSKModulator;
chan = comm.AWGNChannel('EbNo',EbNo);
demodBPSK = comm.BPSKDemodulator;
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

        encodedData = hammingEncoder(data);
        modSignal = modBPSK(encodedData');
        receivedSignal = chan(modSignal);
        demodSignal = demodBPSK(receivedSignal);
        receivedBits = hammingDecoder(demodSignal,blockSize);


        % Update error statistics
        stats = error(data, receivedBits');
        numErrs = stats(2);  % Current cumulative number of errors
        numBits = stats(3);  % Current cumulative number of bits
    end
    ber(idx) = stats(1);
end
% Release resources
release(modBPSK);
release(chan);
release(demodBPSK);
release(error);
end

%% Hamming code encoding function
function hammingCode_long = hammingEncoder(original_data)
    if iscolumn(original_data)
        original_data = original_data';
    end
    % Group processing
    len = length(original_data);
    group_num = ceil(len / 4);
    % Add zeros at the end
    padded_bits = zeros(1, group_num*4);
    padded_bits(1:len) = original_data;   
    
    % Each group is encoded and concatenated
    hammingCode_long = [];
    for i = 1:group_num
        % Extract the 4-bit information bits of the current group
        start_idx = (i-1)*4 + 1;
        end_idx = i*4;
        infoBits_group = padded_bits(start_idx:end_idx);
        
        % Call the (7,4) Hamming code encoding function
        hammingCode_group = hammingEncoder_short(infoBits_group);
        
        % Concatenate the encoding results
        hammingCode_long = [hammingCode_long, hammingCode_group];
    end

end

function hammingCode = hammingEncoder_short(infoBits)
    hammingCode = zeros(1, 7);
    hammingCode(3) = infoBits(1); 
    hammingCode(5) = infoBits(2); 
    hammingCode(6) = infoBits(3); 
    hammingCode(7) = infoBits(4); 
    
    hammingCode(1) = mod(sum(hammingCode([3 5 7])), 2);
    hammingCode(2) = mod(sum(hammingCode([3 6 7])), 2);
    hammingCode(4) = mod(sum(hammingCode([5 6 7])), 2);
end

%% Hamming decoder function
function original_data = hammingDecoder(hammingCode_long, original_len)
    if iscolumn(hammingCode_long)
        hammingCode_long = hammingCode_long';
    end
    %Input validity check
    if ~isvector(hammingCode_long) || ~all(hammingCode_long == 0 | hammingCode_long == 1)
        error('The input to Hamming code must be a vector containing only 0 and 1.');
    end
    len_hamming = length(hammingCode_long);
    if mod(len_hamming, 7) ~= 0
        error('The length of a Hamming code must be an integer multiple of 7.');
    end
    
    %Group processing
    group_num = len_hamming / 7;
    infoBits_all = [];
    
    for i = 1:group_num
        start_idx = (i-1)*7 + 1;
        end_idx = i*7;
        hammingCode_group = hammingCode_long(start_idx:end_idx);
        infoBits_group = hammingDecoder_short(hammingCode_group);
        infoBits_all = [infoBits_all, infoBits_group];
    end
    original_data = infoBits_all(1:original_len);

end

function infoBits = hammingDecoder_short(hammingCode)
    S1 = mod(hammingCode(1) + hammingCode(3) + hammingCode(5) + hammingCode(7), 2);
    S2 = mod(hammingCode(2) + hammingCode(3) + hammingCode(6) + hammingCode(7), 2);
    S3 = mod(hammingCode(4) + hammingCode(5) + hammingCode(6) + hammingCode(7), 2);
    
    error_pos = S3*4 + S2*2 + S1*1;
    
    if error_pos ~= 0
        hammingCode(error_pos) = 1 - hammingCode(error_pos);
    end
   
    infoBits = [hammingCode(3), hammingCode(5), hammingCode(6), hammingCode(7)];
end