function [ PolarGrid ] = VectorizedCompute2DPolarDFT( inputImage,  noOfAngles )
%COMPUTE2DRADONTRANSFORM Summary of this function goes here
%   Detailed explanation goes here
I = inputImage;

[sizeX,sizeY] =  size(I);
N = sizeX -1;      % N is always even
M = noOfAngles;    % M is also even


% Three structures
% F_x_alpha_l = zeros(sizeX,sizeY, 'like',I);   % X- scaled square grid
% F_y_alpha_l = zeros(sizeX,sizeY, 'like',I);   % Y- scaled square grid


PolarGrid = zeros(M, N+1, 'like',I);     %  Polar grid: No of angles vs. Radial data
lineData = zeros(1,N+1,'like',I );
SymmlineData = zeros(1,N+1,'like',I);


dcValue = 0;

lineSpacing = -N/2:N/2;

L = (M-2)/4;       % Number of levels
hasFortyFiveDegrees = 0;

if(rem(M-2,4) ~= 0)
    hasFortyFiveDegrees = 1;
    L = ceil (L);                   % use + 1
end


for l=1:1:L  % For each level
    
    angle = l*180/M;
    alpha_l = cosd(angle);
    beta_l  = sind(angle);
   
    
    % X axis Scaling
    F_x_alpha_l = VectorizedFrFT_Centered(inputImage.', alpha_l);
    F_x_alpha_l = F_x_alpha_l.';
    
    if (l == 1) % For first pass gather lines at 0 and 90
        NintyLine = F_x_alpha_l(:, N/2+1);          % Getting the column
        J = (0:1:N)';
        K = (0:1:N)';
        J = J - N/2;
        PremultiplicationFactor=exp(1i*pi*J *N/(N+1));
        PostmultiplicationFactor = exp(1i*pi*N*K/(N+1));
        col = bsxfun(@times,PostmultiplicationFactor,fft(bsxfun(@times,NintyLine,PremultiplicationFactor)));
        PolarGrid (M/2+1,:)   = col; fliplr ( conj(col'));
        line = PolarGrid(M/2+1,:);
        dcValue = line(N/2+1);  
    end
    
    
    desiredIndexes = [-ones(1,N/2)*l 0 ones(1,N/2)*l];
    for y =1 :N+1
        if (y ~= N/2+1) % Skip at zero computed seperately
            col = F_x_alpha_l(:,y);
            beta_factor = abs(lineSpacing(y))*beta_l /l;
            lineData (y) = VectorizedFrFTCenteredSingle( (col), beta_factor , desiredIndexes(y) );
            SymmlineData(y) = VectorizedFrFTCenteredSingle( (col), beta_factor , -desiredIndexes(y) );
        end
    end
    lineData (N/2+1) = dcValue;
    SymmlineData(N/2+1) = dcValue;
    PolarGrid (1+l, :)= lineData;
    PolarGrid (M+1-l, :)= fliplr( SymmlineData);
    
    if (hasFortyFiveDegrees && angle == 45)   % If angle is 45 we have already computed it
        continue;
    end
    
     % Y axis Scaling
     F_y_alpha_l = VectorizedFrFT_Centered(( inputImage), alpha_l);
   
    if (l == 1)
        ZeroLine = F_y_alpha_l( N/2+1,:);
        J = (0:1:N);
        K = (0:1:N);
        J = J - N/2;
        PremultiplicationFactor=exp(1i*pi*J *N/(N+1));
        PostmultiplicationFactor = exp(1i*pi*N*K/(N+1));
        PolarGrid (1,:) =  PostmultiplicationFactor .* fft(ZeroLine.*PremultiplicationFactor);       % At 0 degrees
    end
    
    for x = 1:N+1
        if (x ~= N/2+1) % Skip at zero computed seperately
            row = F_y_alpha_l(x,:);
            beta_factor = abs(lineSpacing(x))*beta_l /l;
            lineData (x) = VectorizedFrFTCenteredSingle( row, beta_factor , -desiredIndexes(x) );
            SymmlineData(x) = VectorizedFrFTCenteredSingle(row, beta_factor , desiredIndexes(x) );
        end
    end
    lineData (N/2+1) = dcValue;
    SymmlineData(N/2+1) = dcValue;
    PolarGrid (M/2+1+l, :)=  lineData ;
    PolarGrid (M/2+1-l, :)=  SymmlineData;
end
end

