%% initialization
clearvars
close all
clc
%% user definition
geom.radii = 1;
geom.size = 0.1; % 전극 크기 
geom.eledcnt = 8; % eled 개수  
geom.eledc = linspace(45,315, 7); % 전극 각도 설정 
geom.domain = 10;
geom.domain_rad = linspace(0.50, 1.00, geom.domain+1); % 반지름 circnt

geom.xaxis1 = linspace(0.1, 0.6, 6); % x축
  
geom.rad1 = linspace(0.2, 0.4, 6); % 반지름 

geom.angle = linspace(0, 360, 17); % 각도 

%mat.con = linspace(0.027,0.033, 3);  % back ground
%mat.con1 = linspace(0.05, 0.11, 3);
%mat.con2 = linspace(0.07, 0.12, 3);


mat.eled_array = 1:geom.eledcnt; 

mesh.size = 5;
stud.currfreq = 100;  % [kHz]
all_matrix = [];

phy.eled_array = [13 19 24 18 11 5 1 7];
phy.eledcnt = length(phy.eled_array);
phy.comb = nchoosek(mat.eled_array, 2);
phy.comb_len = size(phy.comb, 1);

mat.type = {'mat2', 'mat1'};

file_name = 'C:\Users\admin\OneDrive\문서\EIT_Unet\V_diff_data_py.xlsx';  
startCol = 1;
append_diff_matrix = [];

output_sigma = [];
output_sigma_filename = 'C:\Users\admin\OneDrive\문서\EIT_Unet\output_sigma_data.xlsx';
%% main
for i = 1:6      % x축1  8
    disp(['i = ', num2str(i)]); geom.i = i;   
    for j = 1:6  % 반지름 
        disp(['j = ', num2str(j)]); geom.j = j;
        for a = 1:17  % 각도1  8 
            disp(['a = ', num2str(a)]); geom.a = a; 
            % --create model
            model = createModel();
            % --geo
            model = fnc_geom(model, geom);
            % --mesh
            model = fnc_mesh(model, mesh);
            % --material
            model = fnc_material(model, 'mat2');
            % --physics
            model = fnc_physics(model, phy);
            % -- study and solve
            model = fnc_stud(model, stud);
    
            V_matrix1 = fnc_intergral(model, phy); 
    

            % --create model
            model = createModel();
            % --geo
            model = fnc_geom(model, geom);
            % --mesh
            model = fnc_mesh(model, mesh);
            % --material
            model = fnc_material(model, 'mat1');
            % --physics
            model = fnc_physics(model, phy);
            % -- study and solve
            model = fnc_stud(model, stud);
    
            V_matrix2 = fnc_intergral(model, phy); 

            Diff_matrix = V_matrix1 - V_matrix2;
                    

            append_diff_matrix = [append_diff_matrix, Diff_matrix];
                    
            % plot
            model = fnc_test_plt(model);
            %figure %저장
            
            
            pd = mpheval(model,'ec.sigmaxx','selection',[9 10]);
            
            pts = pd.p;
            ptx = pts(1,:);
            pty = pts(2,:);

            tri = delaunay(ptx,pty); 
            % min max 


            V = pd.d1(:) ;
            [Xq, Yq] = meshgrid(linspace(-1, 1, 64), linspace(-1, 1, 64));
            
            ptx = ptx(:); % 1x457를 457x1로 변경
            pty = pty(:);
            Vq = griddata(ptx, pty, V, Xq, Yq);     % Interpolation
            Vqq = reshape(Vq, 4096, 1);     % 64*64
            output_sigma = [output_sigma, Vqq]; % 열추가 
            
            %
            figure; 
            pcolor(Xq, Yq, Vq); axis equal; axis off; box off; shading flat; clim([0 1]); colorbar;
             
            %figure_name = ['C:\Users\admin\OneDrive\문서\EIT_Unet\train_output_image2\train_ex_out_fig' num2str(startCol) '.png'];
            
            %saveas(gcf, figure_name, 'png');        
            startCol = startCol + 1;
            clear model

        end    
    end
end
%xlswrite(file_name, append_diff_matrix);
%xlswrite(output_sigma, output_sigma_filename);   



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
        temp.name1 = ['sq' num2str(i + 1)]; % 직사각형->정사각형
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


    model.component('comp1').geom('geom1').create('c3', 'Circle');
    model.component('comp1').geom('geom1').feature('c3').set('pos', [geom.xaxis1(geom.i) 0]);
    model.component('comp1').geom('geom1').feature('c3').set('r', geom.rad1(geom.j));
    model.component('comp1').geom('geom1').create('rot10', 'Rotate');
    model.component('comp1').geom('geom1').feature('rot10').setIndex('rot', num2str(geom.angle(geom.a)), 0);
    model.component('comp1').geom('geom1').feature('rot10').selection('input').set({'c3'});

    model.component('comp1').geom('geom1').create('dif2', 'Difference');
    model.component('comp1').geom('geom1').feature('dif2').selection('input').set({'c2'});
    model.component('comp1').geom('geom1').feature('dif2').selection('input2').set({'rot10'});
    model.component('comp1').geom('geom1').create('c4', 'Circle');
    model.component('comp1').geom('geom1').feature('c4').set('pos', [geom.xaxis1(geom.i) 0]);
    model.component('comp1').geom('geom1').feature('c4').set('r', geom.rad1(geom.j));
    model.component('comp1').geom('geom1').create('rot11', 'Rotate');
    model.component('comp1').geom('geom1').feature('rot11').setIndex('rot', num2str(geom.angle(geom.a)), 0);
    model.component('comp1').geom('geom1').feature('rot11').selection('input').set({'c4'});


    

    model.component('comp1').geom('geom1').create('pt1', 'Point');
    model.component('comp1').geom('geom1').feature('pt1').label('ForGround');
    model.component('comp1').geom('geom1').run;
end

%% material
function model = fnc_material(model, type)
    model.component('comp1').material.create('eled', 'Common');
    model.component('comp1').material('eled').selection.set([1, 2, 3, 4, 5, 6, 7, 8]);
    model.component('comp1').material('eled').propertyGroup('def').set('electricconductivity', {'100' '0' '0' '0' '100' '0' '0' '0' '100'});
    model.component('comp1').material('eled').propertyGroup('def').set('relpermittivity', {'0' '0' '0' '0' '0' '0' '0' '0' '0'});
    
    model.component('comp1').material.create('domain', 'Common');
    model.component('comp1').material('domain').selection.set(9);
    model.component('comp1').material('domain').propertyGroup('def').set('electricconductivity', {'0.09' '0' '0' '0' '0.09' '0' '0' '0' '0.09'});
    model.component('comp1').material('domain').propertyGroup('def').set('relpermittivity', {'0' '0' '0' '0' '0' '0' '0' '0' '0'});
    
    if strcmp(type, 'mat2')
        model.component('comp1').material.create('domain1', 'Common');  % c3
        model.component('comp1').material('domain1').selection.set(10);
        model.component('comp1').material('domain1').propertyGroup('def').set('electricconductivity', {'1' '0' '0' '0' '1' '0' '0' '0' '1'});
        model.component('comp1').material('domain1').propertyGroup('def').set('relpermittivity', {'0' '0' '0' '0' '0' '0' '0' '0' '0'});
    elseif strcmp(type, 'mat1')
        model.component('comp1').material.create('domain1', 'Common');  % c3
        model.component('comp1').material('domain1').selection.set(10);
        model.component('comp1').material('domain1').propertyGroup('def').set('electricconductivity', {'2' '0' '0' '0' '2' '0' '0' '0' '2'});
        model.component('comp1').material('domain1').propertyGroup('def').set('relpermittivity', {'0' '0' '0' '0' '0' '0' '0' '0' '0'});
    end
end
%% mesh
function model = fnc_mesh(model, mesh)
    model.component('comp1').mesh.create('mesh1');
    model.component('comp1').mesh('mesh1').create('ftri1', 'FreeTri');
    model.component('comp1').mesh('mesh1').feature('size').set('hauto', mesh.size);
    model.component('comp1').mesh('mesh1').run;
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

%% line intergral 
function Diff_matrix = fnc_intergral(model, phy)
    Vint_diff = []; 
    Diff_matrix = [];
    k = 2; % 선적분 인덱스 시작위치  [1 2 3 4 5 6 7 8] % phy.eled_array = [2 5 8 11 14 17 20 23];
    for i = 1:phy.eledcnt % 1:8
        
        for ii = k : k+4 % 2:6, 3:7, 4:8, 5:9
            if i == 1 
                temp.name = 'V';
            else 
                temp.name = ['V' num2str(i)];
            end
            
            idx1 = mod(ii+1, phy.eledcnt) +1;  
            idx2 = mod(ii, phy.eledcnt) +1;   %  idx1 - idx2  
            % 4-3, 5-4, 6-5, 7-6, 8-7, 

            selection1 = phy.eled_array(idx1);
            selection2 = phy.eled_array(idx2);
            
            [Vint1, ~] = mphint2(model, temp.name, 'line', 'selection', selection1);
            [Vint2, ~] = mphint2(model, temp.name, 'line', 'selection', selection2);
            Vdiff = Vint1 - Vint2;
            Vint_diff = [Vint_diff; Vdiff];   
        end
        k = k+1;
        
    end
    Diff_matrix = [Diff_matrix; Vint_diff];
end


%% plot test_data
function model = fnc_test_plt(model)
    model.result.create('pg1', 'PlotGroup2D');
    model.result('pg1').create('surf1', 'Surface');
    model.result('pg1').feature('surf1').set('expr', 'ec.sigmaxx');
    model.result('pg1').feature('surf1').create('sel1', 'Selection');
    model.result('pg1').feature('surf1').feature('sel1').selection.set([9 10]);
    
    model.result('pg1').feature('surf1').set('rangecoloractive', true);
    model.result('pg1').feature('surf1').set('rangecolormin', '1.0');
    model.result('pg1').feature('surf1').set('rangecolormax', 2);
    model.result('pg1').feature('surf1').set('rangedataactive', true);
    model.result('pg1').feature('surf1').set('rangedatamin', '1.0');
    model.result('pg1').feature('surf1').set('rangedatamax', 2);
    model.result('pg1').feature('surf1').set('coloring', 'gradient');
    model.result('pg1').feature('surf1').set('topcolor', 'yellow');
    model.result('pg1').feature('surf1').set('bottomcolor', 'blue');

    model.result('pg1').feature('surf1').set('resolution', 'normal');
    model.result('pg1').set('titletype', 'none');
    model.result('pg1').set('edges', false);
    figure; mphplot(model,'pg1'); axis off; box off; colorbar;
    %clim([0 1]);
    %colorbar;
    
end