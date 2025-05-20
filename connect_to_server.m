
f = parfeval(@() connect(), 0);
while strcmp(f.State, 'running') || strcmp(f.State, 'queued')
    pause(0.01);  % даём MATLAB немного времени
end
connect()

function connect()
   addpath('Z:\COMSOL56\Multiphysics\mli');
   mphstart('localhost', 2036);
end

