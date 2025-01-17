function [gt_imgs gt_cnt] = view_gt_segmentation(bsdsRoot,img,name,out_path,only_name,save_)

gt_imgs = readSegs(bsdsRoot,'color',name);
% save(sprintf('C:/Users/Benny/PycharmProjects/study/gt_segs/%d',name),'gt_imgs')
gt_path = fullfile(out_path, 'gt');
if ~exist(gt_path,"dir")
    mkdir(gt_path);
end

gt_cnt = [];
for i=1:size(gt_imgs,2), 
    if save_ == 1,
        [imgMasks,segOutline,imgMarkup]=segoutput(img,gt_imgs{i});
        imwrite(imgMarkup,fullfile(gt_path, [only_name, '_', int2str(i), '.bmp'])); 
    end;
    gt_cnt(i) = max(gt_imgs{i}(:));
end;
