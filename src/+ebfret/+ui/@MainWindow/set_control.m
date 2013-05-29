function set_control(self, varargin)
    % initialize controls struct if necessary
    if isempty(self.controls)
        self.controls = struct();
    end
    controls = struct(varargin{:});
    control_names = fieldnames(controls);
    known_names = {'series', ...
                   'ensemble', ...
                   'redraw', ...
                   'colors', ...
                   'crop', ...
                   'exclude', ...
                   'min_states', ...
                   'max_states', ...
                   'init_restarts', ...
                   'all_restarts', ...
                   'gmm_restarts', ...
                   'run_analysis', ...
                   'run_all', ...
                   'run_precision', ...
                   'redraw_interval', ...
                   'scale_plots', ...
                   'crop_margin'};
    for c = 1:length(control_names)
        control = control_names{c};
        if ~any(strcmp(control, known_names))
            error('ebfret.ui.MainWindow:UnkownControl', ...
                  'Unknown control "%s"', control);
        end
        % update ui controls as required
        switch control
            case 'series'
                self.handles.seriesControl.set_prop(controls.series);
                if ~isfield(self.controls, 'series') ...
                    || (self.controls.series.value ~= self.handles.seriesControl.value)
                    self.controls.series.value = self.handles.seriesControl.value;
                    self.refresh('series');
                end
                self.controls.series.min = self.handles.seriesControl.min;
                self.controls.series.max = self.handles.seriesControl.max;
                if length(self.series) > 0
                    n = self.controls.series.value;
                    set(self.handles.cropMinEdit, ...
                        'string', sprintf('%d', self.series(n).crop.min));
                    set(self.handles.cropMaxEdit, ...
                        'string', sprintf('%d', self.series(n).crop.max));
                    set(self.handles.excludeCheck, ...
                        'value', self.series(n).exclude);
                end
            case 'ensemble'
                self.handles.ensembleControl.set_prop(controls.ensemble);
                if ~isfield(self.controls, 'ensemble') ...
                    || ~isfield(self.controls.ensemble, 'min') ...
                    || (self.controls.ensemble.min ~= self.handles.ensembleControl.min)
                    self.controls.ensemble.min = self.handles.ensembleControl.min;
                    self.set_control('min_states', self.controls.ensemble.min);
                end
                if ~isfield(self.controls, 'ensemble') ...
                    || ~isfield(self.controls.ensemble, 'max') ...
                    || (self.controls.ensemble.max ~= self.handles.ensembleControl.max)
                    self.controls.ensemble.max = self.handles.ensembleControl.max;
                    self.set_control('max_states', self.controls.ensemble.max);
                end
                if ~isfield(self.controls, 'ensemble') ...
                     || ~isfield(self.controls.ensemble, 'value') ...
                     || (self.controls.ensemble.value ~= self.handles.ensembleControl.value)
                    self.controls.ensemble.value = self.handles.ensembleControl.value;
                    self.refresh('ensemble');
                end
            case 'crop'
                if length(self.series) > 0
                    n = self.controls.series.value;
                    if ~isfield(controls.crop, 'min')
                        controls.crop.min = self.series(n).crop.min;
                    end
                    if ~isfield(controls.crop, 'max')
                        controls.crop.max = self.series(n).crop.max;
                    end
                    controls.crop.min = ...
                        max(1, controls.crop.min);
                    controls.crop.max = ...
                        max(controls.crop.min, ...
                            min(length(self.series(n).signal), ...
                                controls.crop.max));
                    set(self.handles.cropMinEdit, ...
                        'enable', 'on', ...
                        'string', sprintf('%d', ...
                                    round(controls.crop.min)));
                    set(self.handles.cropMaxEdit, ...
                        'enable', 'on', ...
                        'string', sprintf('%d', ...
                                    round(controls.crop.max)));
                    % if cropping values changed, then reset posterior
                    if (self.series(n).crop.min ~= controls.crop.min) ...
                       || (self.series(n).crop.max ~= controls.crop.max)
                        self.series(self.controls.series.value).crop = ...
                            controls.crop;
                        a = self.controls.min_states:self.controls.max_states;
                        self.reset_posterior(a, n);
                        self.refresh('series');
                    end
                else
                    % disable cropping control if we have no data
                    set(self.handles.minCropEdit, 'enable', 'off', 'string', '');
                    set(self.handles.maxCropEdit, 'enable', 'off', 'string', '');
                end
            case 'exclude'
                if length(self.series) > 0
                    set(self.handles.excludeCheck, ...
                        'enable', 'on', ...
                        'value', controls.exclude);
                    n = self.controls.series.value;
                    if (controls.exclude ~= self.series(n).exclude)
                        self.series(n).exclude = controls.exclude;
                        self.reset_posterior(self.controls.min_states:self.controls.max_states, n);
                        self.refresh('ensemble', 'series');
                    end
                else
                    % disable control if we have no data
                    set(self.handles.excludeCheck, 'enable', 'off');
                end
            case 'min_states'
                set(self.handles.minStatesEdit, ...
                    'string', sprintf('%d', round(controls.min_states)));
                % check if new analysis entries need to be populated
                if ~isfield(self.controls, 'min_states') ...
                    || (self.controls.min_states ~= controls.min_states)
                    self.controls.min_states = controls.min_states;
                    self.set_control('ensemble', struct('min', controls.min_states));
                    self.init_analysis();
                end
            case 'max_states'
                set(self.handles.maxStatesEdit, ...
                    'string', sprintf('%d', round(controls.max_states)));
                % check if new analysis entries need to be populated
                if ~isfield(self.controls, 'max_states') ...
                    || (self.controls.max_states ~= controls.max_states)
                    self.controls.max_states = controls.max_states;
                    self.set_control('ensemble', struct('max', controls.max_states));
                    self.init_analysis();
                end
            case 'init_restarts'
                self.controls.init_restarts = controls.init_restarts;
                set(self.handles.initRestartsEdit, ...
                    'string', sprintf('%d', round(controls.init_restarts)));
            case 'all_restarts'
                self.controls.all_restarts = controls.all_restarts;
                set(self.handles.allRestartsEdit, ...
                    'string', sprintf('%d', round(controls.all_restarts)));
            case 'gmm_restarts'
                self.controls.gmm_restarts = controls.gmm_restarts;
                set(self.handles.GmmRestartsCheck, ...
                    'value', controls.gmm_restarts);
            case 'run_analysis'
               if controls.run_analysis && (length(self.series) > 0)
                    set(self.handles.analysisRunButton, ...
                        'value', 1, 'enable', 'off');
                    set(self.handles.analysisStopButton, ...
                        'value', 0, 'enable', 'on');
                    set(self.handles.analysisResetButton, ...
                        'value', 0, 'enable', 'off');
                    if ~isfield(self.controls, 'run_analysis') ...
                       || ~self.controls.run_analysis
                        self.controls.run_analysis = controls.run_analysis;
                        self.run_ebayes();
                    end
                else
                    self.controls.run_analysis = false;
                    if (length(self.series) > 0)
                        set(self.handles.analysisRunButton, ...
                            'value', 0, 'enable', 'on');
                        set(self.handles.analysisResetButton, ...
                            'enable', 'on');
                    else
                        set(self.handles.analysisRunButton, ...
                            'value', 0, 'enable', 'off');
                        set(self.handles.analysisResetButton, ...
                            'enable', 'off');
                    end
                    set(self.handles.analysisStopButton, ...
                        'value', 1, 'enable', 'off');
                end
            case 'run_all'
                self.controls.run_all = controls.run_all;
                set(self.handles.analysisPopup, ...
                    'value', 2-controls.run_all);
            case 'run_precision'
                self.controls.run_precision = controls.run_precision;
                set(self.handles.analysisPrecisionEdit, ...
                    'string', sprintf('%.1e', self.controls.run_precision));
            case 'scale_plots'
                if ~isfield(self.controls, 'scale_plots') ...
                    || (self.controls.scale_plots ~= controls.scale_plots)
                    self.controls.scale_plots = controls.scale_plots;
                    self.refresh('ensemble', 'series');
                end
            otherwise
                % store control values 
                self.controls.(control) = controls.(control);
        end
    end