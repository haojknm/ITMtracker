%% demo

clear

sequence{1} = 'rng14_15';
sequence{2} = 'rng17_20';
sequence{3} = 'rng18_03';
sequence{4} = 'rng22_08';
sequence{5} = 'person1';
sequence{6} = 'person2';

% for i = 1:6
%     runTracker_FLIR(sequence{i});
% end


for i = 1:6
    seq = seqinfor(sequence{i}) ;
    seq.path = ['..\..\sequences\' sequence{i} '\imgs2\'];
    runTracker_FLIR(sequence{i});

% % %     results=run_IVT(seq, '.\', 0);
% % %     results.len = seq.len;
% % %     [perf.aveCoverage, perf.aveErrCenter, perf.errCoverage, perf.errCenter] = calcSeqErrRobust(results, seq.rect_anno);
% % %     mean(perf.errCenter)
% % %     save(['.\rlt\' sequence{i} '_rlt_IVT.mat'],'results','perf') ;
% % % 
% % %     results=run_L1APG(seq, '.\', 0);
% % %     results.len = seq.len;
% % %     [perf.aveCoverage, perf.aveErrCenter, perf.errCoverage, perf.errCenter] = calcSeqErrRobust(results, seq.rect_anno);
% % %     mean(perf.errCenter)
% % %     save(['.\rlt\' sequence{i} '_rlt_L1APG.mat'],'results','perf') ;
% % % 
% % %     results=run_SCM(seq, '.\', 0);
% % %     results.len = seq.len;
% % %     [perf.aveCoverage, perf.aveErrCenter, perf.errCoverage, perf.errCenter] = calcSeqErrRobust(results, seq.rect_anno);
% % %     mean(perf.errCenter)
% % %     save(['.\rlt\' sequence{i} '_rlt_SCM.mat'],'results','perf') ;
% % %     
% % %     
% % %     results=run_CSK(seq, '.\', 0);
% % %     results.len = seq.len;
% % %     [perf.aveCoverage, perf.aveErrCenter, perf.errCoverage, perf.errCenter] = calcSeqErrRobust(results, seq.rect_anno);
% % %     mean(perf.errCenter)
% % %     save(['.\rlt\' sequence{i} '_rlt_CSK.mat'],'results','perf') ;
    
%     results=run_CT(seq, '.\temp\', 0); 
%     results.len = seq.len;
%     [perf.aveCoverage, perf.aveErrCenter, perf.errCoverage, perf.errCenter] = calcSeqErrRobust(results, seq.rect_anno);
%     mean(perf.errCenter)
%     save(['.\rlt\' sequence{i} '_rlt_CT.mat'],'results','perf') ;
    
% % %     cd('.\trackers\MIL\')
% % %     results=run_MIL2(seq, '.\', 0);
% % %     results.len = seq.len;
% % %     [perf.aveCoverage, perf.aveErrCenter, perf.errCoverage, perf.errCenter] = calcSeqErrRobust(results, seq.rect_anno);
% % %     mean(perf.errCenter)
% % %     cd('..\..\')
% % %     save(['.\rlt\' sequence{i} '_rlt_MIL.mat'],'results','perf') ;
% % % 
% % % 
% % %     
% % %     runTracker_FLIR(sequence{i});

end