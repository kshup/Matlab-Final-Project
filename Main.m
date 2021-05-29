% This code belongs to: 
% Furkan Kaya - 191216002,
% Ali Murat Tava - 191216008,
% Kaan İnce - 191216022,
% Tolgahan Şişman - 191216018.

function Main()
    p1 = [1,0,0,1,1,0,1,0,1,1,1];
    p2 = [1,1,0,1,0,1,1,1,1,0,0];
    p3 = [0,1,1,0,1,0,1,1,1,1,0];
    p4 = [0,0,1,1,0,1,0,1,1,1,1];
    
    A = [p1;p2;p3;p4];
    AT = transpose(A);
    G = [eye(11),AT];
    H = [A, eye(4)];
    frame = [0,1,1,1,1,1,1,1,1,0];
    sendrom = H * transpose(eye(15));
    addedZeroLen = 0;

    function itemP = ReturnItemProbMap(M, len)
        % This function return probability dict based on symbol count.
        itemP = containers.Map('KeyType','char','ValueType','double');
        for m = keys(M)
            thekey = m{1};
            count = double(M(thekey));
            itemP(thekey) = double(count/len);
        end
    end

    function itemCount = ReturnItemCountMap(l)
        % This function count every symbol in given list.
        itemCount = containers.Map('KeyType','char','ValueType','double');
        for m = l
            if (isKey(itemCount, m))
                itemCount(m) = itemCount(m) + 1;
                continue;
            end
            itemCount(m) = 1;
        end
    end

    function flattenArr = ReturnArrFlat(arr)
        flattenArr = [];
        for k = arr
            flattenArr = [flattenArr, transpose(k(1:end))];
        end
    end

    function withBurstError = ReturnBrokenArray(arr)
        for i=235:249
            arr(i) = mod(arr(i)+1, 2);
        end
        withBurstError = arr;
    end

    function indexNumber = GetIndexNumber(arr, item)
        indexNumber = 0;
        for a=arr
            indexNumber=indexNumber+1;
            if(a==item)
                break;
            end
        end
    end

    function frameDeleted = DeleteBeforeFrame(arr, frame)
        index = 1;
        frameLen = length(frame);
        while(1)
            if(index>=length(arr)) 
                break;
            end
            if(arr(index:index+frameLen-1)==frame)
                index = index+frameLen;
                break;
            end
            index=index+1;
        end
        frameDeleted = arr(index:end);
    end

    function fixedArr = FixErrorInArr(arr, errors)
        counter = 1;
        for k=errors
            if(ismember(1,k))
                erroredBit = GetIndexNumber(sendrom, k);
                erroredRow = counter;
                arr(erroredRow, erroredBit) = mod(arr(erroredRow, erroredBit)+1,2);
            end
            counter=counter+1;
        end
        fixedArr=arr;
    end

    
    function [finalMessage, dict] = Transmitter(message)
        itemCounts = ReturnItemCountMap(message);
        itemPs = ReturnItemProbMap(itemCounts, length(message));

        [dict, avglen] = huffmandict(keys(itemPs), cell2mat(values(itemPs)));

        huffEncoded = huffmanenco(message, dict);
        if (mod(length(huffEncoded),11) ~= 0)
            remain = 11 - mod(length(huffEncoded), 11);
            addedZeroLen = remain;
            huffEncoded = [huffEncoded, zeros(1, remain)];
        end
        reshapedArr = reshape(huffEncoded, length(huffEncoded)/11, 11);
        encodedMessage = mod(reshapedArr*G, 2);
        interLeavedMessage = ReturnArrFlat(encodedMessage);
        finalMessage = [frame, interLeavedMessage];
    end

    function recived = Receiver(message, dict)
        frameDeleted = DeleteBeforeFrame(message, frame);
        reshaped2 = reshape(frameDeleted, length(frameDeleted)/15, 15);
        errors = mod(H*transpose(reshaped2),2);
        fixed = FixErrorInArr(reshaped2, errors);

        %delete paradi columns
        fixed(:,[12, 13, 14, 15]) = [];
        fixed = ReturnArrFlat(fixed);
        fixed = fixed(1:end-addedZeroLen);

        recived = huffmandeco(fixed, dict);
    end
    
    function addedParasite = AddParasite(message)
        randomInt = randi([1 100]);
        randomBinary = de2bi(randomInt);
        finalWrandom = [randomBinary, message];
        addedParasite = ReturnBrokenArray(finalWrandom);
    end

    msg = importdata("Mesaj.txt");
    msg = cell2mat(msg);    
    
    msg
    
    [final, dict] = Transmitter(msg);
    finalWparasite = AddParasite(final);
    recivedMessage = Receiver(finalWparasite, dict);
    
    cell2mat(recivedMessage)
end
