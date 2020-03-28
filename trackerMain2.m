function [results] = trackerMain2(p, im, bg_area, fg_area, area_resize_factor, opticFlow)
%TRACKERMAIN contains the main loop of the tracker, P contains all the parameters set in runTracker
    %% INITIALIZATION
    num_frames = numel(p.img_files);
    % used for OTB-13 benchmark
    OTB_rect_positions = zeros(num_frames, 4);
	pos = p.init_pos;
    target_sz = p.target_sz;
	num_frames = numel(p.img_files);
    % patch of the target + padding
    patch_padded = getSubwindow(im, pos, p.norm_bg_area, bg_area);
    % initialize hist model
    new_pwp_model = true;
    for k = 1:size(patch_padded,3)
        [bg_hist{k}, fg_hist{k}] = updateHistModel(new_pwp_model, patch_padded(:,:,k), bg_area, fg_area, target_sz, p.norm_bg_area, p.n_bins, 1);
        para(k) = 1.0/size(patch_padded,3);
    end
%     para = [0 1 0];
    Allpara = para;
   
    
    new_pwp_model = false;
    % Hann (cosine) window
    if isToolboxAvailable('Signal Processing Toolbox')
        hann_window = single(hann(p.cf_response_size(1)) * hann(p.cf_response_size(2))');
    else
        hann_window = single(myHann(p.cf_response_size(1)) * myHann(p.cf_response_size(2))');
    end
    % gaussian-shaped desired response, centred in (1,1)
    % bandwidth proportional to target size
    output_sigma = sqrt(prod(p.norm_target_sz)) * p.output_sigma_factor / p.hog_cell_size;
    y = gaussianResponse(p.cf_response_size, output_sigma);
    yf = fft2(y);
    %% SCALE ADAPTATION INITIALIZATION
    if p.scale_adaptation
        % Code from DSST
        scale_factor = 1;
        base_target_sz = target_sz;
        scale_sigma = sqrt(p.num_scales) * p.scale_sigma_factor;
        ss = (1:p.num_scales) - ceil(p.num_scales/2);
        ys = exp(-0.5 * (ss.^2) / scale_sigma^2);
        ysf = single(fft(ys));
        if mod(p.num_scales,2) == 0
            scale_window = single(hann(p.num_scales+1));
            scale_window = scale_window(2:end);
        else
            scale_window = single(hann(p.num_scales));
        end;

        ss = 1:p.num_scales;
        scale_factors = p.scale_step.^(ceil(p.num_scales/2) - ss);

        if p.scale_model_factor^2 * prod(p.norm_target_sz) > p.scale_model_max_area
            p.scale_model_factor = sqrt(p.scale_model_max_area/prod(p.norm_target_sz));
        end

        scale_model_sz = floor(p.norm_target_sz * p.scale_model_factor);
        % find maximum and minimum scales
        min_scale_factor = p.scale_step ^ ceil(log(max(5 ./ bg_area)) / log(p.scale_step));
        max_scale_factor = p.scale_step ^ floor(log(min([size(im,1) size(im,2)] ./ target_sz)) / log(p.scale_step));
    end

    %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %%
    t_imread = 0;
    %% MAIN LOOP
    tic;
    for frame = 1:num_frames
        if frame>1
            tic_imread = tic;
            im = imread([p.img_path p.img_files{frame}]);
            im = combfeat(im, opticFlow);
            t_imread = t_imread + toc(tic_imread);
	    %% TESTING step
            response_comb = 0;
            for k = 1:size(im,3)
                im_temp = im(:,:,k);
                % extract patch of size bg_area and resize to norm_bg_area
                im_patch_cf = getSubwindow(im_temp, pos, p.norm_bg_area, bg_area);
                pwp_search_area = round(p.norm_pwp_search_area / area_resize_factor);
                % extract patch of size pwp_search_area and resize to norm_pwp_search_area
                im_patch_pwp = getSubwindow(im_temp, pos, p.norm_pwp_search_area, pwp_search_area);
                % compute feature map
                xt = getFeatureMap(im_patch_cf, p.feature_type, p.cf_response_size, p.hog_cell_size);
                % apply Hann window
                xt_windowed = bsxfun(@times, hann_window, xt);
                % compute FFT
                xtf = fft2(xt_windowed);
                % Correlation between filter and test patch gives the response
                % Solve diagonal system per pixel.
                if p.den_per_channel
                    hf = hf_num{k} ./ (hf_den{k} + p.lambda);
                else
                    hf = bsxfun(@rdivide, hf_num{k}, sum(hf_den{k}, 3)+p.lambda);
                end
                response_cf{k} = ensure_real(ifft2(sum(conj(hf) .* xtf, 3)));
                
                % Crop square search region (in feature pixels).
                response_cf{k} = cropFilterResponse(response_cf{k}, ...
                    floor_odd(p.norm_delta_area / p.hog_cell_size));
                if p.hog_cell_size > 1
                    % Scale up to match center likelihood resolution.
                    response_cf{k} = mexResize(response_cf{k}, p.norm_delta_area,'auto');
                end
                
                
                likelihood_map{k} = getColourMap(im_patch_pwp, bg_hist{k}, fg_hist{k}, p.n_bins, 1);
                % (TODO) in theory it should be at 0.5 (unseen colors shoud have max entropy)
                likelihood_map{k}(isnan(likelihood_map{k})) = 0;
                
                % each pixel of response_pwp loosely represents the likelihood that
                % the target (of size norm_target_sz) is centred on it
                response_pwp{k} = getCenterLikelihood(likelihood_map{k}, p.norm_target_sz);
                
                %% ESTIMATION
                response{k} = mergeResponses(response_cf{k}, response_pwp{k}, p.merge_factor, p.merge_method);
                
                %% combine different channels
                response_comb = response_comb + para(k)*response{k};
            end
                
            [row, col] = find(response_comb == max(response_comb(:)), 1);
            center = (1+p.norm_delta_area) / 2;
            pos = pos + ([row, col] - center) / area_resize_factor;
            rect_position = [pos([2,1]) - target_sz([2,1])/2, target_sz([2,1])];
            
%             for k = 1:size(im,3)
%                 para(k) = response{k}(row,col) / mean(mean(response{k}));
%             end
%             para = para/(sum(para))
            
            for k = 1:size(im,3)
                [row_tmp, col_tmp] = find(response{k} == max(response{k}(:)), 1);
                dis_tmp(k) = ( (row-row_tmp)*(row-row_tmp) + (col-col_tmp)*(col-col_tmp) );
                para_new(k) = exp(-dis_tmp(k)/2/4)/2/pi/4;
            end            
            para_new = para_new/(sum(para_new));
            para = (1-p.learning_rate_para)*para + p.learning_rate_para*para_new;
            para = para.* (dis_tmp<10);
            para = para/(sum(para));
            Allpara = [Allpara ; para];
%             para = [0 1 0];
            

            %% SCALE SPACE SEARCH
            if p.scale_adaptation
                im_patch_scale = getScaleSubwindow(im, pos, base_target_sz, scale_factor * scale_factors, scale_window, scale_model_sz, p.hog_scale_cell_size);
                xsf = fft(im_patch_scale,[],2);
                scale_response = real(ifft(sum(sf_num .* xsf, 1) ./ (sf_den + p.lambda) ));
                recovered_scale = ind2sub(size(scale_response),find(scale_response == max(scale_response(:)), 1));
                %set the scale
                scale_factor = scale_factor * scale_factors(recovered_scale);

                if scale_factor < min_scale_factor
                    scale_factor = min_scale_factor;
                elseif scale_factor > max_scale_factor
                    scale_factor = max_scale_factor;
                end
                % use new scale to update bboxes for target, filter, bg and fg models
                target_sz = round(base_target_sz * scale_factor);
                avg_dim = sum(target_sz)/2;
                bg_area = round(target_sz + avg_dim);
                if(bg_area(2)>size(im,2)),  bg_area(2)=size(im,2)-1;    end
                if(bg_area(1)>size(im,1)),  bg_area(1)=size(im,1)-1;    end

                bg_area = bg_area - mod(bg_area - target_sz, 2);
                fg_area = round(target_sz - avg_dim * p.inner_padding);
                fg_area = fg_area + mod(bg_area - fg_area, 2);
                % Compute the rectangle with (or close to) params.fixed_area and
                % same aspect ratio as the target bboxgetScaleSubwindow
                area_resize_factor = sqrt(p.fixed_area/prod(bg_area));
            end

            if p.visualization_dbg==1
                mySubplot(2,1,5,1,im_patch_cf,'FG+BG','gray');
                mySubplot(2,1,5,2,likelihood_map{1},'obj.likelihood','parula');
                mySubplot(2,1,5,3,response_cf{1},'CF response','parula');
                mySubplot(2,1,5,4,response_pwp{1},'center likelihood','parula');
                mySubplot(2,1,5,5,response_comb,'merged response','parula');
                drawnow
            end
        end

        %% TRAINING
        for k=1:size(im,3)
            im_temp = im(:,:,k);
            % extract patch of size bg_area and resize to norm_bg_area
            im_patch_bg = getSubwindow(im_temp, pos, p.norm_bg_area, bg_area);
            % compute feature map, of cf_response_size
            xt = getFeatureMap(im_patch_bg, p.feature_type, p.cf_response_size, p.hog_cell_size);
            % apply Hann window
            xt = bsxfun(@times, hann_window, xt);
            % compute FFT
            xtf = fft2(xt);
            %% FILTER UPDATE
            % Compute expectations over circular shifts,
            % therefore divide by number of pixels.
            new_hf_num = bsxfun(@times, conj(yf), xtf) / prod(p.cf_response_size);
            new_hf_den = (conj(xtf) .* xtf) / prod(p.cf_response_size);

            if frame == 1
                % first frame, train with a single image
                hf_den{k} = new_hf_den;
                hf_num{k} = new_hf_num;
                
                
                
            else
                % subsequent frames, update the model by linear interpolation
                hf_den{k} = (1 - p.learning_rate_cf) * hf_den{k} + p.learning_rate_cf * new_hf_den;
                hf_num{k} = (1 - p.learning_rate_cf) * hf_num{k} + p.learning_rate_cf * new_hf_num;

                %% BG/FG MODEL UPDATE
                % patch of the target + padding
                [bg_hist{k}, fg_hist{k}] = updateHistModel(new_pwp_model, im_patch_bg, bg_area, fg_area, target_sz, p.norm_bg_area, p.n_bins, 1, bg_hist{k}, fg_hist{k}, p.learning_rate_pwp);
            end
            
        end

        %% SCALE UPDATE
        if p.scale_adaptation
            im_patch_scale = getScaleSubwindow(im, pos, base_target_sz, scale_factor*scale_factors, scale_window, scale_model_sz, p.hog_scale_cell_size);
            xsf = fft(im_patch_scale,[],2);
            new_sf_num = bsxfun(@times, ysf, conj(xsf));
            new_sf_den = sum(xsf .* conj(xsf), 1);
            if frame == 1,
                sf_den = new_sf_den;
                sf_num = new_sf_num;
            else
                sf_den = (1 - p.learning_rate_scale) * sf_den + p.learning_rate_scale * new_sf_den;
                sf_num = (1 - p.learning_rate_scale) * sf_num + p.learning_rate_scale * new_sf_num;
            end
        end

        % update bbox position
        if frame==1, rect_position = [pos([2,1]) - target_sz([2,1])/2, target_sz([2,1])]; end

        rect_position_padded = [pos([2,1]) - bg_area([2,1])/2, bg_area([2,1])];

        OTB_rect_positions(frame,:) = rect_position;

        if p.fout > 0,  fprintf(p.fout,'%.2f,%.2f,%.2f,%.2f\n', rect_position(1),rect_position(2),rect_position(3),rect_position(4));   end

        %% VISUALIZATION
        if p.visualization == 1
            if isToolboxAvailable('Computer Vision System Toolbox')
                im = insertShape(im, 'Rectangle', rect_position, 'LineWidth', 4, 'Color', 'black');
                im = insertShape(im, 'Rectangle', rect_position_padded, 'LineWidth', 4, 'Color', 'yellow');
                % Display the annotated video frame using the video player object.
                step(p.videoPlayer, im);
            else
                figure(1)
                imshow(im)
                rectangle('Position',rect_position, 'LineWidth',2, 'EdgeColor','g');
                rectangle('Position',rect_position_padded, 'LineWidth',2, 'LineStyle','--', 'EdgeColor','b');
                drawnow
            end
        end
    end
    elapsed_time = toc;
%     plot(Allpara,'DisplayName','Allpara','LineWidth',4);
%     set (gcf,'Color',[1,1,1]);
%     title('rng14\_15','fontsize',16),
%     xlabel('Frame Number','fontsize',16),
%     ylabel('Weights','fontsize',16),
%     set(gca,'FontSize',16);
%     hleg1 = legend('W_{intensity}','W_{texture}','W_{motion}','Orientation','horizontal');
    
    
    % save data for OTB-13 benchmark
    results.type = 'rect';
    results.res = OTB_rect_positions;
    results.fps = num_frames/(elapsed_time - t_imread);
end

% Reimplementation of Hann window (in case signal processing toolbox is missing)
function H = myHann(X)
    H = .5*(1 - cos(2*pi*(0:X-1)'/(X-1)));
end

% We want odd regions so that the central pixel can be exact
function y = floor_odd(x)
    y = 2*floor((x-1) / 2) + 1;
end

function y = ensure_real(x)
    assert(norm(imag(x(:))) <= 1e-5 * norm(real(x(:))));
    y = real(x);
end
