% This code is to reproduce the experiments reported in paper
% "Segmentation Using Superpixels: A Bipartite Graph Partitioning Approach"
% Zhenguo Li, Xiao-Ming Wu, and Shih-Fu Chang, CVPR 2012
% {zgli, xmwu, sfchang}@ee.columbia.edu
function demo_SAS_BSDS(ind_)
% clc;clear all; close all;

addpath 'msseg'
addpath 'others'
addpath 'evals'
addpath 'algorithms';
addpath 'Graph_based_segment'

%%% set parameters for bipartite graph
para.alpha = 0.001; % affinity between pixels and superpixels
para.beta  =  20;   % scale factor in superpixel affinity
para.nb = 1; % number of neighbors for superpixels

% read numbers of segments used in the paper 
if strcmp(getenv('computername'),'BENNYK')
    bsdsRoot = 'C:\Users\Benny\MATLAB\Projects\AF-graph\BSD';
else
    bsdsRoot = 'D:\MATLAB\github\AF-graph\BSD';
end
fid = fopen(fullfile('results','BSDS300','Nsegs.txt'),'r');
Nimgs = 300; % number of images in BSDS300
[BSDS_INFO] = fscanf(fid,'%d %d \n',[2,Nimgs]);
fclose(fid);
run_type = "test";
if run_type == "test"
    Nimgs = 100;
    test_ims_map = "ims_map_test.txt";
    fid = fopen(test_ims_map);
    test_ims_map_data = cell2mat(textscan(fid,'%f %*s'));
    fclose(fid);
    %%
    BSDS_INFO = BSDS_INFO(:,ismember(BSDS_INFO(1,:),test_ims_map_data));

elseif run_type == "train"
    Nimgs = 200;
    train_ims_map = "ims_map_train.txt";
    fid = fopen(train_ims_map);
    test_ims_map_data = cell2mat(textscan(fid,'%f %*s'));
    fclose(fid);
    %%
    BSDS_INFO = BSDS_INFO(:,ismember(BSDS_INFO(1,:),test_ims_map_data));

else
    Nimgs = 300;
end

Nimgs_inds = 1:Nimgs;
Nimgs = length(Nimgs_inds);
PRI_all = zeros(Nimgs,1);
VoI_all = zeros(Nimgs,1);
GCE_all = zeros(Nimgs,1);
BDE_all = zeros(Nimgs,1);

for k_idxI = 1:Nimgs%64:Nimgs
    idxI = Nimgs_inds(k_idxI);
    % read number of segments
    Nseg = 4;min(3,BSDS_INFO(2,idxI));
    
    % locate image
    img_name = int2str(BSDS_INFO(1,idxI));
    img_loc = fullfile(bsdsRoot,'images','test',[img_name,'.jpg']);    
    if ~exist(img_loc,'file')
        img_loc = fullfile(bsdsRoot,'images','train',[img_name,'.jpg']);
    end
    img = im2double(imread(img_loc)); [X,Y,~] = size(img);
    out_path = fullfile('results','BSDS300',img_name);
    if ~exist(out_path ,"dir")
        mkdir(out_path);
    end
    % generate superpixels
    [para_MS, para_FH] = set_parameters_oversegmentation(img_loc);
    [seg,labels_img,seg_vals,seg_lab_vals,seg_edges,seg_img,seg_img_lab] = make_superpixels(img_loc,para_MS,para_FH);
%     ind_ = 1;
    seg = seg(ind_);
    labels_img = labels_img(ind_);
    seg_vals = seg_vals(ind_);
    seg_edges = seg_edges(ind_);
    seg_lab_vals = seg_lab_vals(ind_); 
    seg_img = seg_img(ind_);
    seg_img_lab = seg_img_lab(ind_);
    
    % save over-segmentations
%     view_oversegmentation(labels_img,seg_img,out_path,img_name);
%     clear labels_img seg_img;

    % build bipartite graph
    [B,W_Y] = build_bipartite_graph(img_loc,para,seg,seg_lab_vals,seg_edges); 
%     clear seg seg_lab_vals seg_edges; 
    
    % Transfer Cut
    [label_img ,Ncut_evec]= Tcut(B, Nseg,[X,Y]); clear B;
%     label_img = Tcut_sp(B, W_Y,Nseg,[X,Y]); clear B;

    % save segmentation
%     view_segmentation(img,label_img(:),out_path,img_name,0);
    
    % evaluate segmentation
    [gt_imgs gt_cnt] = view_gt_segmentation(bsdsRoot,img,BSDS_INFO(1,idxI),out_path,img_name,0); clear img;
    out_vals = eval_segmentation(label_img,gt_imgs); clear label_img gt_imgs;
    fprintf('%6s: %2d %9.6f, %9.6f, %9.6f, %9.6f %d\n', img_name, Nseg, out_vals.PRI, out_vals.VoI, out_vals.GCE, out_vals.BDE, para_FH.K);
    
    PRI_all(k_idxI) = out_vals.PRI;
    VoI_all(k_idxI) = out_vals.VoI;
    GCE_all(k_idxI) = out_vals.GCE;
    BDE_all(k_idxI) = out_vals.BDE;
end
fprintf('Mean: %14.6f, %9.6f, %9.6f, %9.6f \n', mean(PRI_all), mean(VoI_all), mean(GCE_all), mean(BDE_all));

fid_out = fopen(fullfile('results','BSDS300','evaluation.txt'),'w');
for idxI=1:Nimgs
    fprintf(fid_out,'%6d %9.6f, %9.6f, %9.6f, %9.6f \n', BSDS_INFO(1,idxI), PRI_all(idxI), VoI_all(idxI), GCE_all(idxI), BDE_all(idxI));
end
fprintf(fid_out,'Mean: %10.6f, %9.6f, %9.6f, %9.6f \n', mean(PRI_all), mean(VoI_all), mean(GCE_all), mean(BDE_all));
fclose(fid_out);
