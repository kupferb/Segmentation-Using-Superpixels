function A = prune_knn(W,nb)

% W - affinity matrix
% nb - the number of nearest neighbors 
% A - symmetric (weighted) knn graph

n = size(W,1);

% idxR = zeros(nb,size(W,2));
% for col = 1:size(W,2)
%     [~,idx] = sort(W(:,col),'descend');
%     idxR(:,col) = idx(1:nb);
% 
% end

[~,idx] = sort(W,'descend');
idxR = idx(1:nb,:);
idxC = ones(nb,1)*[1:n];
A = sparse(idxR(:),idxC(:),1,n,n);
A = double(A|A');
A = A.*W;

