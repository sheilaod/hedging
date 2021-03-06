% clear memory before you start
clear;

% MARKC - change fork do 2 different things
% generate file (fork = 1) - can see large values of longrun variance
% draw graphs for S&P Index (fork = 2) - uses infer on the model generated by estimate
fork = 2;

% MARKC - change filename here
%filename='C:\Users\212340664\Documents\not_personal\Learning\Year 2\Dissertation\Data\USDEUR Spot Reverse.csv';
sandpfilename='C:\Users\212340664\Documents\not_personal\Learning\Year 2\Dissertation\Data\S&P Index.csv';
delimiter = ',';
headerLine = 1;
sanp=importdata(sandpfilename, delimiter, headerLine);

% all the return values
allprices=sanp.data(:,1);
allreturns=price2ret(allprices);
alldates=sanp.textdata(:,1);
max = length(allreturns);
    
figure; % figure window
y=transpose(allreturns);
plot(y);
xlim([0,max]);
title('S&P Index');

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

% 6 month forecast = 4 x 6mth = 4x130 day window
% max=T-window;
% max=2000;

% create the model
Mdl=garch(1,1);

% number of trading days (252) times 4 - Figleski 4 x the forward length
window = 1008;
volatilitymatrix{(max+1)-window,4} = [];
volatilitymatrix(1, 1) = cellstr('Date');
volatilitymatrix(1, 2) = cellstr('LR Vol');
volatilitymatrix(1, 3) = cellstr('Return');
volatilitymatrix(1, 4) = cellstr('Cond. Var.');
chk = length(volatilitymatrix);
disp(chk);

% fork from earlier
if fork == 2
    bottom = 1;
    top = window;
    windowreturns=allreturns(bottom:top);
    windowdates=alldates(bottom:top);
    % not sure below is necessary
    percentreturns = 100*allreturns;
    [EstMdl2,~,logL2, Par] = estimate(Mdl,allreturns);

    v = infer(EstMdl2,percentreturns);
    inn = percentreturns./sqrt(v);

    figure
    subplot(2,1,1)
    plot(v)
    xlim([0,length(percentreturns)])
    title('Conditional Variances');
    %subplot(3,1,2)
    %xlim([0,length(inn)])
    %plot(inn)
    %title('Innovations');
    y=transpose(allreturns);
    subplot(2,1,2);
    plot(allreturns);
    title('S&P Index');

else
 
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
            volatilitymatrix(i+1, 2) = num2cell(volL);
            volatilitymatrix(i+1, 1) = alldates(i+2, 1);
            volatilitymatrix(i+1, 3) = num2cell(allreturns(i+2, 1));
            volatilitymatrix(i+1, 4) = num2cell(v(length(v), 1));
        else
            disp(i);
            disp(max);
        end 
    end
    output='C:\Users\212340664\Documents\not_personal\Learning\Year 2\Dissertation\Data\vol.xlsx';
    xlswrite(output, volatilitymatrix);
end


