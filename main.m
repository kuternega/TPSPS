params.value = [0.007, 0.02, 0, 0.0001, 100, 293.15, 70];
params.measurement = {'[m]', '[m]', '', '[m/s]', '[mol/m^3]', '[K]', '[A/m^2]'};
params.name = {'H', 'L', 'gamma', 'V0', 'C0', 'T0', 'iav'};
params.step = [0.003, 0.01, pi/12, 0.00005, 50, 15, 10];
params.tol = [0.0005, 0.001, pi/32, 0.00001, 1, 1, 1];

file_name = 'data output.csv';
maxIter = 5;
timeout = 10*60;
func = @(param) f(param);
data = load_data(file_name);
[x_min, f_min, data] = coordDescentGoldenAuto(func, params, maxIter, timeout, data, file_name);  
fprintf('\n\n\nОптимальное значение параметров:\n');
for i = 1:length(x_min.value)
    fprintf('%s = %f\n', x_min.name{i}, x_min.value(i));
end
fprintf('Оптимальное значение функции: %f\n',f_min);


function [data] = load_data(file_name)
    data = [];
    try
        % Попытка считать таблицу
        T = readtable(file_name);

        % Обработка данных
        params = unique(T.param);

        for i = 1:length(params)
            idx = T.param == params(i);
            data(i).x = T.x(idx);
            data(i).y = T.y(idx);
        end
        disp('Файл успешно прочитан и обработан.');

    catch ME
        % Обработка ошибки
        fprintf('Ошибка при чтении файла: %s\n', ME.message);        
    end
end


function [x_best, f_best, data] = coordDescentGoldenAuto(f, x, maxIter, timeout, data, file_name)
    n = numel(x.value);
    ok = true;
    for i = 1:n
        fprintf('\n\n\nОптимизация параметра: %s\n', x.name{i});
        % Определение границ        
        try
            if i > length(data)
                data(i).x = [];
                data(i).y = [];
            end
            [a, b, tmp] = findBracket(@(val) f(setCoord(x, i, val)), x.value(i), x.step(i), maxIter, timeout, data(i));
        catch ME
            error = ME;
            ok = false;            
        end
        data(i).x = tmp.x;
        data(i).y = tmp.y;
        fprintf('\nИнтервал поиска:\t\t[%f; %f]\n', a, b);
        fprintf('Длина интервала:\t\t%f\n', b - a);
        fprintf('Минимальная длина интервала:\t\t%f\n', x.tol(i));
        % Оптимизация по i-й координате
        fi = @(xi) f(setCoord(x, i, xi));
        if ok
            try
                [x.value(i), tmp] = goldenSection(fi, a, b, x.tol(i), data(i));
            catch ME
                error = ME;
                ok = false;                 
            end        
            data(i).x = tmp.x;
            data(i).y = -tmp.y;
        end
        figure;
        plot(data(i).x, data(i).y, 'o');
        xlabel(x.name(i));
        ylabel('Изменение потока соли');
        grid on;
        if ~ok
            break;
        end
    end

    % сохранение данных в csv файл
    allData = [];        
    for j = 1:length(data)
        lenX = length(data(j).x);  % длина векторов
        temp = table(...
            repmat(j, lenX, 1), ...
            data(j).x(:), ...
            data(j).y(:), ...
            'VariableNames', {'param', 'x', 'y'});
        allData = [allData; temp];
    end
    if ~ok
        rethrow(error);
    end
    writetable(allData, file_name);
        
    x_best = x;
    [f_best, ~] = evalWithTimeout(@() f(x_best), -1);
    f_best = -f_best;
end

function x_new = setCoord(x, i, val)
    x_new = x;
    x_new.value(i) = val;
end

function [xmin, data] = goldenSection(f, a, b, tol, data)
    try
        gr = (sqrt(5) + 1) / 2;
        c = b - (b - a) / gr;
        d = a + (b - a) / gr;
        while abs(b - a) > tol        
            [fc, ~] = evalWithTimeout(@() f(c), -1);
            [fd, ~] = evalWithTimeout(@() f(d), -1);
            data.x(end + 1) = c;
            data.y(end + 1) = fc;
            data.x(end + 1) = d;
            data.y(end + 1) = fd;
            if fc < fd
                b = d;
            else
                a = c;
            end
            fprintf('\nИнтервал поиска:\t\t[%f; %f]\n', a, b);
            fprintf('Длина интервала:\t\t%f\n', b - a);
            fprintf('Минимальная длина интервала:\t\t%f\n', tol);
            c = b - (b - a) / gr;
            d = a + (b - a) / gr;
        end

        xmin = (a + b) / 2;
    catch ME
        xmin = a;
        data = data;
        rethrow(ME);
    end
end

function [a_out, b_out, data] = findBracket(f1d, x0, step, maxIter, timeout, data)
    try
        % f1d — функция от 1 переменной
        % timeout — максимальное время для вызова функции
        % min_step — минимально допустимый шаг
        [fx0, ok] = evalWithTimeout(@() f1d(x0), timeout);
        if ~ok
            error('Не удалось вычислить начальное значение функции');
        end
        data.x(end + 1) = x0;
        data.y(end + 1) = fx0;
        % поиск правой границы
        [b_out, data] = findBracketR(f1d, x0, step, maxIter, timeout, data, fx0);
        fprintf('\nНайдена правая граница:\t\t%f\n', b_out);
        % поиск левой границы
        [a_out, data] = findBracketR(f1d, x0, -step, maxIter, timeout, data, fx0);
        fprintf('\nНайдена левая граница:\t\t%f\n', a_out);
    catch ME
        data = data;
        a_out = x0;
        b_out = x0;
        rethrow(ME);
    end 
end

function [b_out, data] = findBracketR(f1d, x0, step, maxIter, timeout, data, fa)
    try
        min_step = step/2;
        stepR = step;
        b = x0 + stepR;
        [fb, ok] = evalWithTimeout(@() f1d(b), timeout);
        if ok
            data.x(end + 1) = b;
            data.y(end + 1) = fb;
        end
        if ~ok
            stepR = step;
            while ~ok && stepR > min_step
                stepR = max(abs(stepR * 0.5), abs(min_step));  % Шаг не может быть меньше min_step
                b = x0 + stepR;
                [fb, ok] = evalWithTimeout(@() f1d(b), timeout);
                if ok
                    data.x(end + 1) = b;
                    data.y(end + 1) = fb;
                end
            end
            if ~ok
                b_out = x0;
                return
            end
        end
        if fb >= fa
            b_out = b;
            return
        end
        iter = 0;
        while ok && fa >= fb
            stepR = stepR * 2;  
            b = x0 - stepR;
            [fb, ok] = evalWithTimeout(@() f1d(b), timeout);
            if ok
                data.x(end + 1) = b;
                data.y(end + 1) = fb;
            end
            iter = iter + 1;
            if iter > maxIter
                if ok
                    b_out = x0 + stepR;
                    return
                end
                b_out = x0 + stepR/2;
                return
            end
        end
        if ~ok
            stepR2 = step;
            while ~ok && stepR > min_step
                stepR2 = max(abs(stepR * 0.5), abs(min_step));  % Шаг не может быть меньше min_step
                b = x0 + stepR + stepR2;
                [fb, ok] = evalWithTimeout(@() f1d(b), timeout);
                if ok
                    data.x(end + 1) = b;
                    data.y(end + 1) = fb;
                end
            end
            if ~ok
                b_out = x0 + stepR;
                return
            end
            b_out = x0 + stepR + stepR2;
            return
        end
        b_out = x0 + stepR;    
    catch ME
        b_out = x0;
        data = data;
        rethrow(ME);
    end
end



function [result, ok] = evalWithTimeout(func, timeout)
    result = [];
    ok = false;

    f = parfeval(@() func(), 1);  % Асинхронный запуск
    tStart = tic;

    while strcmp(f.State, 'running') || strcmp(f.State, 'queued')
        pause(0.01);
        if toc(tStart) > timeout && timeout ~= -1
            cancel(f);
            return;
        end
    end

    if strcmp(f.State, 'finished')
        try
            result = fetchOutputs(f);
            ok = true;
        catch
            ok = false;
        end
    end
end



function resault = f(params)
    model = mphload('models\GraviCon_GS.mph');
    for i = 1:length(params.value)
        name = params.name{i};
        value = params.value(i);
        measurement = params.measurement{i};    
        if isempty(measurement)
            model.param.set(name, num2str(value));
        else
            model.param.set(name, [num2str(value) measurement]);
        end
    end
    model.study('std1').run;
    int_val = mphint2(model, '(V0*C0 - v*C)*1[m]', 'line', 'selection', 3);
    n = numel(int_val);
    resault = -int_val(n);
end
