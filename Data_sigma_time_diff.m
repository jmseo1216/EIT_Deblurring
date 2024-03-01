%% initialization
clearvars
close all
clc
%% user definition
geom.radii = 1;
geom.size = 0.1 ; % 전극 크기 
geom.eledcnt = 8; % eled 개수  
geom.eledc = linspace(45,315, 7); % 전극 각도 설정 
mat.eled_array = 1:geom.eledcnt; 

mesh.size = 5;
stud.currfreq = 100;  % [kHz]

phy.eled_array = [13 19 24 18 11 5 1 7];
phy.eledcnt = length(phy.eled_array);

%load('eled_pos.mat', 'eled_index');
%phy.eled_index = eled_index;
%% main
% s_matrix 구하기 
% --create model
model = createModel();
% --geom
model = fnc_geom(model, geom); 
% --material
model = fnc_material(model);
% --mesh
model = fnc_mesh(model, mesh);
% --physics
model = fnc_physics(model, phy);

%  --study and solve 
model = fnc_stud(model, stud);
%  -- dot
[s_matrix, pd1] = fnc_smatrix(model, phy);

file_name1 = 'C:\Users\admin\OneDrive\문서\EIT_Unet\S_matrix_data.xlsx';
xlswrite(file_name1, s_matrix);
% 40by 457

% sigma
lamda = 0.000005;
I = eye(457);

fclose('all');
S_name = 'C:\Users\admin\OneDrive\문서\EIT_Unet\S_matrix_data.xlsx';
S_matrix = xlsread(S_name);

% V_absolute_ex_data, V_diff_data.xlsx
V_name = 'C:\Users\admin\OneDrive\문서\EIT_Unet\V_diff_data_py.xlsx';     
V_matrix = xlsread(V_name);


all_sigma = [];
for i = 1:size(V_matrix, 2) 
    V_matrix_col = V_matrix(:,i);
    sigma = (S_matrix' * S_matrix + lamda*I) \ eye(457) * (S_matrix' * V_matrix_col);
    all_sigma = [all_sigma, sigma];
end

Sigma_filename = 'C:\Users\admin\OneDrive\문서\EIT_Unet\sigma_data.xlsx';
if exist(Sigma_filename, 'file')
    delete(Sigma_filename);
end
writematrix(all_sigma, Sigma_filename); 

sigma = xlsread(Sigma_filename);

%figure_filename = 'C:\Users\admin\OneDrive\문서\EIT_Unet\figure_image';

pts = pd1.p;
ptx = pts(1,:);
pty = pts(2,:);
tri = delaunay(ptx,pty);  % 똑같은 삼각형 좌표 사용 
[Xq, Yq] = meshgrid(linspace(-1, 1, 64), linspace(-1, 1, 64));
input_sigma = [];
input_sigma_filename = 'C:\Users\admin\OneDrive\문서\EIT_Unet\input_sigma_data.xlsx';  
%figure
for ii = 1:size(sigma, 2)
    sigma_col = sigma(:,ii);
    % z-core
    %scaled_diff_matrix = [];
    %current_mean = mean(sigma);
    %current_std = std(sigma);
    %for j = 1: 457
    %    data = sigma_col(j);
    %    scaled_data = (data - current_mean) / current_std;
    %    scaled_diff_matrix = [scaled_diff_matrix; scaled_data] ;
    %end 

    % Min-Max Normalization
    current_max = max(sigma_col);
    current_min = min(sigma_col);
    scaled_diff_matrix = [];
    for j = 1: 457
        data = sigma_col(j);
        scaled_data = (data - current_min) / (current_max - current_min);
        scaled_diff_matrix = [scaled_diff_matrix; scaled_data] ;
    end 

    %V = sigma_col';
    V = scaled_diff_matrix;
    ptx = ptx(:); % 1x457를 457x1로 변경
    pty = pty(:);
    Vq = griddata(ptx, pty, V, Xq, Yq);  % Interpolation
    Vqq = reshape(Vq, 4096, 1);
    input_sigma = [input_sigma, Vqq];
    figure; 
    pcolor(Xq, Yq, Vq); axis equal; axis off; box off; shading flat;     
    figure_name = ['C:\Users\admin\OneDrive\문서\EIT_Unet\train_input_image\train_in_fig' num2str(ii) '.png'];
    saveas(gcf, figure_name, 'png');
end 

 %xlswrite(input_sigma, input_sigma_filename);



%% create model

function model = createModel()  
    import com.comsol.model.*
    import com.comsol.model.util.*
    % Create a new COMSOL model
    model = ModelUtil.create('Model');
    model.component.create('comp1', true); 
end
%% geometry
function model = fnc_geom(model, geom)
    geom.eledpos = [];
    model.component('comp1').geom.create('geom1', 2);
    model.component('comp1').geom('geom1').create('c1', 'Circle');
    model.component('comp1').geom('geom1').create('sq1', 'Square');
    model.component('comp1').geom('geom1').feature('sq1').set('pos', {'1*cos(0)' '1*sin(0)'});
    model.component('comp1').geom('geom1').feature('sq1').set('base', 'center');
    model.component('comp1').geom('geom1').feature('sq1').set('size', geom.size);
    geom.eledpos = [geom.eledpos, {'sq1'}]; % 전극 위치
    for i = 1: geom.eledcnt - 1
        temp.name1 = ['sq' num2str(i + 1)];
        temp.name2 = ['rot' num2str(i)];
        temp.angle = geom.eledc(i);
        model.component('comp1').geom('geom1').create(temp.name1, 'Square');
        model.component('comp1').geom('geom1').feature(temp.name1).set('pos', {'1*cos(0)' '1*sin(0)'});
        model.component('comp1').geom('geom1').feature(temp.name1).set('base', 'center');
        model.component('comp1').geom('geom1').feature(temp.name1).set('size', geom.size);
        
        model.component('comp1').geom('geom1').create(temp.name2, 'Rotate');
        model.component('comp1').geom('geom1').feature(temp.name2).set('rot', num2str(temp.angle));   
        model.component('comp1').geom('geom1').feature(temp.name2).selection('input').set({temp.name1});
        geom.eledpos = [geom.eledpos, {temp.name2}];
    end  % 전극 생성 
    model.component('comp1').geom('geom1').create('uni1', 'Union');
    model.component('comp1').geom('geom1').feature('uni1').label('union_1');
    model.component('comp1').geom('geom1').feature('uni1').selection('input').set(geom.eledpos); % 수정 
    model.component('comp1').geom('geom1').create('dif1', 'Difference');
    model.component('comp1').geom('geom1').feature('dif1').label('difference_1');
    model.component('comp1').geom('geom1').feature('dif1').selection('input').set({'uni1'}); % 더할 개체
    model.component('comp1').geom('geom1').feature('dif1').selection('input2').set({'c1'});  % 없앨
    
    
    model.component('comp1').geom('geom1').create('c2', 'Circle');

    model.component('comp1').geom('geom1').create('pt1', 'Point');
    model.component('comp1').geom('geom1').feature('pt1').label('ForGround');
    model.component('comp1').geom('geom1').run;
end

%% material
function model = fnc_material(model)
    model.component('comp1').material.create('eled', 'Common');
    model.component('comp1').material('eled').selection.set([1, 2, 3, 4, 5, 6, 7, 8]);
    model.component('comp1').material('eled').propertyGroup('def').set('electricconductivity', {'100' '0' '0' '0' '100' '0' '0' '0' '100'});
    model.component('comp1').material('eled').propertyGroup('def').set('relpermittivity', {'0' '0' '0' '0' '0' '0' '0' '0' '0'});

    model.component('comp1').material.create('domain', 'Common');
    model.component('comp1').material('domain').selection.set(9);
    model.component('comp1').material('domain').propertyGroup('def').set('electricconductivity', {'1' '0' '0' '0' '1' '0' '0' '0' '1'});
    model.component('comp1').material('domain').propertyGroup('def').set('relpermittivity', {'0' '0' '0' '0' '0' '0' '0' '0' '0'});
end
%% mesh
function model = fnc_mesh(model, mesh)
    model.component('comp1').mesh.create('mesh1');
    model.component('comp1').mesh('mesh1').create('ftri1', 'FreeTri');
    model.component('comp1').mesh('mesh1').feature('size').set('hauto', mesh.size);
    model.component('comp1').mesh('mesh1').run;
end

%% physics   
%function model = fnc_physics(model, phy)
% %총 ec.40까지 나오면 % 12 34
% %8개만 반복문돌리고 필요한거 가져오자 한쌍씩  12 23 34 ... 81
%    for i = 0: 7
%        idx1 = mod(i+1, phy.eledcnt) + 1;
%        idx2 = mod(i, phy.eledcnt) + 1 ;
%        
%        phys.idxinncurreled = phy.eled_array(idx1);
%        phys.idxoutcurreled = phy.eled_array(idx2);
%        temp.name = ['ec' num2str(i+1)];
%   
%        model.component('comp1').physics.create(temp.name, 'ConductiveMedia', 'geom1');
%        model.component('comp1').physics(temp.name).create('ncd1', 'NormalCurrentDensity', 1);
%        model.component('comp1').physics(temp.name).feature('ncd1').selection.set([phys.idxinncurreled]);
%        model.component('comp1').physics(temp.name).feature('ncd1').set('nJ', 1);
%        model.component('comp1').physics(temp.name).create('ncd2', 'NormalCurrentDensity', 1);
%        model.component('comp1').physics(temp.name).feature('ncd2').selection.set([phys.idxoutcurreled]);
%        model.component('comp1').physics(temp.name).feature('ncd2').set('nJ', -1);
%        model.component('comp1').physics(temp.name).create('gnd1', 'Ground', 0);
%        model.component('comp1').physics(temp.name).feature('gnd1').selection.set([19]);
%    end
%end

%% physics   
function model = fnc_physics(model, phy)
    for i = 1:phy.eledcnt
        idx1 = mod(i, phy.eledcnt) + 1;
        idx2 = mod(i-1, phy.eledcnt) + 1;
        phys.idxinncurreled = phy.eled_array(idx1);   %  +   
        phys.idxoutcurreled = phy.eled_array(idx2);   %  -
        temp.name = ['ec' num2str(i)];
        model.component('comp1').physics.create(temp.name, 'ConductiveMedia', 'geom1');
        model.component('comp1').physics(temp.name).create('ncd1', 'NormalCurrentDensity', 1);
        model.component('comp1').physics(temp.name).feature('ncd1').selection.set([phys.idxinncurreled]);
        model.component('comp1').physics(temp.name).feature('ncd1').set('nJ', 1);
        model.component('comp1').physics(temp.name).create('gnd2', 'Ground', 1);
        model.component('comp1').physics(temp.name).feature('gnd2').selection.set([phys.idxoutcurreled]);


    end

end


%% mpheval
function [s_matrix, pd1] = fnc_smatrix(model, phy)
    s_matrix = [];
    for i = 1: 8
        disp(['i = ' num2str(i)]);
        if i == 1
            temp_name1 = 'ec.Ex'; 
            temp_name2 = 'ec.Ey'; 
        else 
            temp_name1 = ['ec' num2str(i) '.Ex'];
            temp_name2 = ['ec' num2str(i) '.Ey'];
        end 

        pd1 = mpheval(model, temp_name1, 'selection', 9); % temp_name
        pd2 = mpheval(model, temp_name2, 'selection', 9);
        for ii = i+1 : i+5
            idx = mod(ii, phy.eledcnt) +1;
            disp(['ii = ' num2str(ii)]);
            disp(idx)
            if idx == 1
                temp_name3 = 'ec.Ex';
                temp_name4 = 'ec.Ey';
            else 
                temp_name3 = ['ec' num2str(idx) '.Ex'];
                temp_name4 = ['ec' num2str(idx) '.Ey'];
            end
            pd3 = mpheval(model, temp_name3, 'selection', 9);  % temp_name
            pd4 = mpheval(model, temp_name4, 'selection', 9);
            
            arr1 =[];
            for k = 1: 457
                a = [pd1.d1(k), pd2.d1(k)];
                b = [pd3.d1(k), pd4.d1(k)];
                dot_product = dot(a,b);
                arr1 = [arr1, dot_product];
            end
            s_matrix = [s_matrix; arr1];

        end
    end

end

%% study and solve
function model = fnc_stud(model, stud)
    temp.name1 = 'std';  
    temp.nmae2 = 'sol';
    model.study.create(temp.name1);
    model.study(temp.name1).create('freq', 'Frequency');
    model.study(temp.name1).feature('freq').set('punit', 'kHz');
    model.study(temp.name1).feature('freq').setIndex('plist', num2str(stud.currfreq), 0);
    
    model.sol.create(temp.nmae2);
    model.sol(temp.nmae2).study(temp.name1);
    model.sol(temp.nmae2).attach(temp.name1);
    model.sol(temp.nmae2).create('st1', 'StudyStep');
    model.sol(temp.nmae2).create('v1', 'Variables');
    model.sol(temp.nmae2).create('s1', 'Stationary');
    model.sol(temp.nmae2).feature('s1').create('p1', 'Parametric');
    model.sol(temp.nmae2).feature('s1').create('fc1', 'FullyCoupled');
    model.sol(temp.nmae2).feature('s1').feature.remove('fcDef');
    model.sol(temp.nmae2).attach(temp.name1);
    model.sol(temp.nmae2).feature('st1').label('Compile Equations: Frequency Domain');
    model.sol(temp.nmae2).feature('v1').label('Dependent Variables 1.1');
    model.sol(temp.nmae2).feature('v1').set('clistctrl', {'p1'});
    model.sol(temp.nmae2).feature('v1').set('cname', {'freq'});
    model.sol(temp.nmae2).feature('v1').set('clist', {[num2str(stud.currfreq) '[kHz]']});
    model.sol(temp.nmae2).feature('s1').label('Stationary Solver 1.1');
    model.sol(temp.nmae2).feature('s1').feature('dDef').label('Direct 1');
    model.sol(temp.nmae2).feature('s1').feature('aDef').label('Advanced 1');
    model.sol(temp.nmae2).feature('s1').feature('p1').label('Parametric 1.1');
    model.sol(temp.nmae2).feature('s1').feature('p1').set('pname', {'freq'});
    model.sol(temp.nmae2).feature('s1').feature('p1').set('plistarr', stud.currfreq);
    model.sol(temp.nmae2).feature('s1').feature('p1').set('punit', {'kHz'});
    model.sol(temp.nmae2).feature('s1').feature('p1').set('pcontinuationmode', 'no');
    model.sol(temp.nmae2).feature('s1').feature('p1').set('preusesol', 'auto');
    model.sol(temp.nmae2).feature('s1').feature('fc1').label('Fully coupled 1.1');
    model.sol(temp.nmae2).runAll;
end

%% plot test_data
function model = fnc_test_plt(model)
    model.result.create('pg1', 'PlotGroup2D');
    model.result('pg1').create('surf1', 'Surface');
    model.result('pg1').feature('surf1').set('expr', 'ec.sigmaxx');
    model.result('pg1').feature('surf1').create('sel1', 'Selection');
    model.result('pg1').feature('surf1').feature('sel1').selection.set([9]);
    
    model.result('pg1').feature('surf1').set('rangecoloractive', true);
    model.result('pg1').feature('surf1').set('rangecolormin', '0.0');
    model.result('pg1').feature('surf1').set('rangecolormax', 0.12);
    model.result('pg1').feature('surf1').set('rangedataactive', true);
    model.result('pg1').feature('surf1').set('rangedatamin', '0.0');
    model.result('pg1').feature('surf1').set('rangedatamax', 0.12);
    model.result('pg1').feature('surf1').set('coloring', 'gradient');
    model.result('pg1').feature('surf1').set('topcolor', 'yellow');
    model.result('pg1').feature('surf1').set('bottomcolor', 'blue');

    model.result('pg1').feature('surf1').set('resolution', 'normal');
    model.result('pg1').set('titletype', 'none');
    model.result('pg1').set('edges', false);
    figure; mphplot(model,'pg1'); axis off; box off;
    
end