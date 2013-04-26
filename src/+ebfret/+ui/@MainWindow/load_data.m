function load_data(self)
    [fname, fpath, findex] = ...
        uigetfile({'*.mat', 'ebFRET saved session (.mat)';});
        % uigetfile({'*.mat', 'ebFRET saved session (.mat)';, ...
        %            '*.mat', 'vbFRET saved session (.mat)';, ... 
        %            '*.mat;*.smd', 'Single-molecule Data Format (.smd,.mat)';, ... 
        %            '*.tsv', 'SF-Tracer donor-acceptor time series (.tsv)'; ...
        %            '*.dat', 'Raw donor-acceptor time series (.dat)'});
    switch findex
        case 1
            session = load(sprintf('%s/%s', fpath, fname));
            set(self, ...
                'series', session.series, ...
                'analysis', session.analysis, ...
                'plots', session.plots, ...
                'status', session.status);
            set_limits(self.handles.seriesControl, length(self.series));
            set_limits(self.handles.ensembleControl, length(self.analysis));
            refresh_ensemble(self, session.status.cur_analysis);
    end
end