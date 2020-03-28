% renamefile
clear
sequence{1} = 'rng14_15';
sequence{2} = 'rng17_20';
sequence{3} = 'rng18_03';
sequence{4} = 'rng22_08';
sequence{5} = 'person1';
sequence{6} = 'person2';

for i = 2:6
    cd(['E:\Project\tracking\∫ÏÕ‚\staple-master\sequences\' sequence{i} '\imgs2\'])
    f = fopen('cn.txt','w');

    dir_content = dir(['E:\Project\tracking\∫ÏÕ‚\staple-master\sequences\' sequence{i} '\imgs\']);
    % skip '.' and '..' from the count
    n_imgs = length(dir_content) - 2;
    img_files = cell(n_imgs, 1);
    for ii = 1:n_imgs
        img_files{ii} = dir_content(ii+2).name;
    end

    for j = 1:n_imgs
        str = img_files{j};
        fprintf(f,['ren ' str ' ' str(end-7:end) '\n'] ); 
    end
    fclose(f);
end
    