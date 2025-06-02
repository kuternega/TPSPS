name = {'H', 'L', 'gamma', 'V0', 'C0', 'T0', 'iav'};
file_name = 'data output/data_output.csv';

% Настройки аппроксимации 
enableApproximation = true;
approxType = "poly";     % 'poly' или 'spline'
polyDegree = 3;          % степень полинома, если poly

% Загрузка данных
data = load_data(file_name);

% Визуализация + аппроксимация 
for i = 1:length(data)
    figure;
    plot(data(i).x, data(i).y, 'ko', 'DisplayName', 'Исходные данные');
    hold on;

    xlabel(name{i});
    ylabel('Изменение потока соли');
    grid on;

    if enableApproximation
        xq = linspace(min(data(i).x), max(data(i).x), 200);

        switch approxType
            case "poly"
                coeffs = polyfit(data(i).x, data(i).y, polyDegree);
                yq = polyval(coeffs, xq);
                plot(xq, yq, 'r-', 'LineWidth', 1.5, ...
                     'DisplayName', sprintf('Полиномиальная аппроксимация (степень %d)', polyDegree));

                % Печать формулы полинома в консоль
                polyStr = poly2str(coeffs, 'x');
                fprintf('Параметр %s: аппроксимирующий полином:\n%s\n\n', name{i}, polyStr);

            case "spline"
                [x_unique, idx_unique] = unique(data(i).x);
                y_unique = data(i).y(idx_unique);

                yq = spline(x_unique, y_unique, xq);
                plot(xq, yq, 'b--', 'LineWidth', 1.5, ...
                     'DisplayName', 'Сплайн аппроксимация');

                fprintf('Параметр %s: сплайн аппроксимация построена.\n\n', name{i});

            otherwise
                warning('Неизвестный тип аппроксимации.');
        end
    end

    legend;
end

% Функция загрузки данных
function [data] = load_data(file_name)
    data = [];
    try
        T = readtable(file_name);
        params = unique(T.param);

        for i = 1:length(params)
            idx = T.param == params(i);
            data(i).x = T.x(idx);
            data(i).y = T.y(idx);
        end

        disp('Файл успешно прочитан и обработан.');
    catch ME
        fprintf('Ошибка при чтении файла: %s\n', ME.message);        
    end
end
