name = {'H', 'L', 'gamma', 'V0', 'C0', 'T0', 'iav'};
file_name = 'data output/data_output.csv';
data = load_data(file_name);
for i = 1:length(data)
    figure;
    plot(data(i).x, data(i).y, 'o');
    xlabel(name{i});
    ylabel('Изменение потока соли');
    grid on;
end


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