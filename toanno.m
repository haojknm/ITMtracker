clear

out = xml2struct('Thermal_05.xml');
% anno_Thermal_01 = 1;

anno = out.children(1:2:end);

k=0;
for i=1:length(anno)
    
    if length(anno(i).children(1).children) == 1
        k=k+1;
        % frame number
        anno_Thermal_05(k,1) = str2num(anno(i).attributes.value);
        % object id
        anno_Thermal_05(k,2) = str2num(anno(i).children(1).children.attributes.value);
        % orientation
        % x,y,w,h
        anno_Thermal_05(k,4) = str2num(anno(i).children(1).children.children(3).attributes(3).value);
        anno_Thermal_05(k,5) = str2num(anno(i).children(1).children.children(3).attributes(4).value);
        anno_Thermal_05(k,6) = str2num(anno(i).children(1).children.children(3).attributes(2).value);
        anno_Thermal_05(k,7) = str2num(anno(i).children(1).children.children(3).attributes(1).value);
    else
        for j = 1:2:length(anno(i).children(1).children)
            k = k + 1;
            % frame number
            anno_Thermal_05(k,1) = str2num(anno(i).attributes.value);
            % object id
            anno_Thermal_05(k,2) = str2num(anno(i).children(1).children(j).attributes.value);
            % orientation
            % x,y,w,h
            anno_Thermal_05(k,4) = str2num(anno(i).children(1).children(j).children(3).attributes(3).value);
            anno_Thermal_05(k,5) = str2num(anno(i).children(1).children(j).children(3).attributes(4).value);
            anno_Thermal_05(k,6) = str2num(anno(i).children(1).children(j).children(3).attributes(2).value);
            anno_Thermal_05(k,7) = str2num(anno(i).children(1).children(j).children(3).attributes(1).value);
        end
    end
end
save anno_Thermal_05 anno_Thermal_05

obj1 = find(anno_Thermal_01(:,2)==1)
anno_obj1 = (anno_Thermal_01(obj1,:));
