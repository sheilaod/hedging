% clear memory before you start
clear;

% MARKC - change fork do 2 different things
% generate file (fork = 1) - can see large values of longrun variance
% draw graphs for S&P Index (fork = 2) - uses infer on the model generated by estimate
fork = 1;

% MARKC - change filename here
usdeurfilename='C:\Users\212340664\Documents\not_personal\Learning\Year 2\Dissertation\Data\USDEUR Spot Reverse.csv';
usdeur1Mforwardfilename='C:\Users\212340664\Documents\not_personal\Learning\Year 2\Dissertation\Data\USDEUR 1M Forwards.csv';
usdeur3Mforwardfilename='C:\Users\212340664\Documents\not_personal\Learning\Year 2\Dissertation\Data\USDEUR 3M Forwards.csv';
usdeur6Mforwardfilename='C:\Users\212340664\Documents\not_personal\Learning\Year 2\Dissertation\Data\USDEUR 6M Forwards.csv';
usdeur12Mforwardfilename='C:\Users\212340664\Documents\not_personal\Learning\Year 2\Dissertation\Data\USDEUR 12M Forwards.csv';
% sandpfilename='C:\Users\212340664\Documents\not_personal\Learning\Year 2\Dissertation\Data\S&P Index.csv';
delimiter = ',';
headerLine = 0; % there is no header in the file

% fork from earlier
if fork == 2    % S&P
    %sandp=importdata(sandpfilename, delimiter, headerLine);
    sandp=importdata(usdeurfilename, delimiter, headerLine);
    % all the return values
    allprices=sandp.data(:,1);
    allreturns=price2ret(allprices);
    alldates=sandp.textdata(:,1);
    max = length(allreturns);

    e = allreturns - mean(allreturns);

    figure;
    subplot(2,1,1);
    autocorr(e.^2);
    title('Autocorrelation');
    subplot(2,1,2);
    parcorr(e.^2);
    title('Partial Autocorrelation');

    % Jarque Bera test, H0: Data is not serially correlated (i.e. that it is i.i.d.)
    [h,p,jbstat,critval] = jbtest(allreturns, 0.05);
    disp([h p]);

    % Ljung-Box test
    [h,p,stat] = lbqtest(e.^2,'Lags',[5,15]);
    disp([h p stat]);

    % Engle's ARCH test
    [h,p,fStat,crit] = archtest(e,'Lags',1);

    % create the model
    Mdl=garch(1,1);

    bottom = 1;
    % not sure below is necessary
    % percentreturns = 100*allreturns;
    [EstMdl2,~,logL2, Par] = estimate(Mdl,allreturns);

    v = infer(EstMdl2,allreturns);
    inn = allreturns./sqrt(v);

    figure
    subplot(2,1,1)
    plot(v)
    %xlim([0,length(allreturns)])
    xlim([0,length(v)]);
    title('Conditional Variances');
    y=transpose(allreturns);
    subplot(2,1,2);
    plot(allreturns);
    xlim([0,length(allreturns)]);
    title('S&P Index');

% Otherwise GENERATE the necessary data
else
    eurusd=importdata(usdeurfilename, delimiter, headerLine);
    forward1M=importdata(usdeur1Mforwardfilename, delimiter, 1);
    forward3M=importdata(usdeur3Mforwardfilename, delimiter, 1);
    forward6M=importdata(usdeur6Mforwardfilename, delimiter, 1);
    forward12M=importdata(usdeur12Mforwardfilename, delimiter, 1);

    % all the return values
    allprices=eurusd.data(:,1);
    allreturns=price2ret(allprices);
    alldates=eurusd.textdata(:,1);
    max = length(allreturns);

    % number of trading days (252) times 4 - Figleski 4 x the forward length
    window = 1008;
    volatilitymatrix{(max+1)-window,9} = [];
    volatilitymatrix(1, 1) = cellstr('Date');
    volatilitymatrix(1, 2) = cellstr('LR Vol');
    volatilitymatrix(1, 3) = cellstr('USDEUR Return');
    volatilitymatrix(1, 4) = cellstr('Vol');
    volatilitymatrix(1, 5) = cellstr('Spot');
    volatilitymatrix(1, 6) = cellstr('1M Forward');
    volatilitymatrix(1, 7) = cellstr('3M Forward');
    volatilitymatrix(1, 8) = cellstr('6M Forward');
    volatilitymatrix(1, 9) = cellstr('12M Forward');
    chk = length(volatilitymatrix);
    disp(chk);

    
    % create the model
    Mdl=garch(1,1);

    % store conditional variance for entire period
    cv = zeros(length(allreturns)- window, 1);
    re = zeros(length(allreturns)- window, 1);
    
    for i=1:max-window
        % top = max-i;    
        bottom = i;
        top = i+window;
        windowreturns=allreturns(bottom:top);
        windowdates=alldates(bottom:top);
        % not sure below is necessary
        percentreturns = 100*windowreturns;

        %display('iteration= ' + num2str(i));

        [EstMdl2,~,LogL,Par]= estimate(Mdl, 100*windowreturns);
        v = infer(EstMdl2,percentreturns);
        
        % extract model parameters
        parC=Par.X(1); % omega
        parG=Par.X(2); % beta (GARCH)
        parA=Par.X(3); % alpha (ARCH)

        % vector of initial parameter estimates (Par.X is vector of final
        % estimates) - not really useful...?
        %p = Par.X0;

        %disp([alldates(i, 1) parC parG parA]);

        % Carol Alexander? set the starting values for estimates on day t
        % to be the optimized values on day t-1? Doesn't really help
        % Mdl=garch('Constant',parC,'GARCH',parG,'ARCH',parA);

        % estimate unconditional volatility
        gamma=1-parA-parG;
        % longrun variance CA, vol II, pg. 136
        VL=parC/gamma;
        % longrun volatility
        volL=sqrt(VL);

        % 04/09/2014 - 69.3681
        if volL > 10
            disp(volL);
        end


        if i<max
            %indices = sub2ind(size(volatilitymatrix), i, 2);
            ret = allreturns(i, 1);
            vol = sqrt(v(length(v), 1))*sqrt(252);  % the last value
            % expected spot return (average)
            % expected forward return (average)
            % st. dev. spot return
            % st. dev. forward return
            % correlation ???
            
            % hedge ratio b*
            % hedge effectiveness HE(HKL)
            
            cv(i, 1) = vol;
            re(i, 1) = ret;
            % y = calculateOption();
            
            date = alldates(i+1, 1); % need to offset as we don't have return for the 1st date
            volatilitymatrix(i+1, 2) = num2cell(volL);
            volatilitymatrix(i+1, 1) = date;
            volatilitymatrix(i+1, 3) = num2cell(ret);
            volatilitymatrix(i+1, 4) = num2cell(vol);

            % date to string
            strDate=date{1};
            % spot
            k = strcmp(alldates, strDate);
            j = find(k==1);
            spot=allprices(j,1);
            
            if(i==621)
                disp(i);
            end
            
            % forwards
            % 1M
            fwdate=forward1M.textdata(:,1);
            k = strcmp(fwdate, strDate);
            j = find(k==1);
            forwards=forward1M.data(:,1);
            fw=forwards(j, 1);
            fw1Mprice=spot+fw/100;

            % 3M
            fwdate=forward3M.textdata(:,1);
            k = strcmp(fwdate, strDate);
            j = find(k==1);
            forwards=forward3M.data(:,1);
            fw=forwards(j, 1);
            if (fw~=0) 
                fw3Mprice=spot+fw/100;
            else
                fw3Mprice=0;
            end
            

            % 6M
            fwdate=forward6M.textdata(:,1);
            k = strcmp(fwdate, strDate);
            j = find(k==1);
            forwards=forward6M.data(:,1);
            fw=forwards(j, 1);
            fw6Mprice=spot+fw/100;
            
            % 12M
            fwdate=forward12M.textdata(:,1);
            k = strcmp(fwdate, strDate);
            j = find(k==1);
            forwards=forward12M.data(:,1);
            fw=forwards(j, 1);
            fw12Mprice=spot+fw/100;
            
            disp([i spot fw1Mprice fw3Mprice fw6Mprice fw12Mprice]);
            
            volatilitymatrix(i+1, 5) = num2cell(spot);
            volatilitymatrix(i+1, 6) = num2cell(fw1Mprice);
            volatilitymatrix(i+1, 7) = num2cell(fw3Mprice);
            volatilitymatrix(i+1, 8) = num2cell(fw6Mprice);
            volatilitymatrix(i+1, 9) = num2cell(fw12Mprice);
        else
            disp(i);
            disp(max);
        end 
    end
    
    % Plot the last window
    figure
    subplot(2,1,1)
    
    plot(cv)
    %xlim([0,1008]);
    title('Conditional Variances');
    % y=transpose(allreturns);
    subplot(2,1,2);
    % match values
    %subreturns = eurusd(length(cv):2);
    plot(re);
    %xlim([0,1008]);
    title('USDEUR');
    
    output='C:\Users\212340664\Documents\not_personal\Learning\Year 2\Dissertation\Data\vol.xlsx';
    xlswrite(output, volatilitymatrix);
end

