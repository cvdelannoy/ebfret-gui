function remove_bleaching(self, method, thresholds)
    if length(self.series) > 0
        if nargin < 2
            [method, thresholds] = ebfret.ui.remove_bleaching_dlg();
        end
        switch method
            case 1
                % remove photobleaching using auto-detected bleaching point
                for n = 1:length(self.series)
                    if ~isempty(self.series(n).donor) && ~isempty(self.series(n).acceptor)
                        id = ebfret.data.fret.photobleach_index(self.series(n).donor);
                        ia = ebfret.data.fret.photobleach_index(self.series(n).acceptor);

                        % % sanity check: donor bleaching should result in acceptor bleaching
                        % % but we'll allow a few time points tolerance
                        % tol = 5;
                        % if (ia < (id + tol));
                        %     self.series(n).crop.max = min(ia, id);
                        % else
                           %     self.series(n).exclude = true;
                        % end
                        % self.series(n).crop_max = min(id, ia);
                        % if self.series(n).crop_max == self.series(n).crop_min
                        %      self.series(n).exclude = true;
                        % end
                    end
                end
            case 2 
                % remove photobleaching using manual thresholds
                W = 7;
                W0 = floor(W/2);
                kernel = ebfret.analysis.normalize(exp(-linspace(-1.5,1.5,W).^2));
                for n = 1:length(self.series)
                    crop_max = length(self.series(n).signal) - self.series(n).crop.min;
                    if ~isnan(thresholds.fret)
                        signal = conv(self.series(n).signal(self.series(n).crop.min:end), kernel, 'valid');
                        crop_max = ...
                            min(min(crop_max, ...
                                [find(signal < thresholds.fret, 1, 'first') + W0, inf]));
                    end
                    if ~isnan(thresholds.acc) || ~isnan(thresholds.sum)
                        acceptor = conv(self.series(n).acceptor(self.series(n).crop.min:end), kernel, 'valid');
                        crop_max = ...
                            min(min(crop_max, ...
                                [find(acceptor < thresholds.acc, 1, 'first') + W0, inf]));
                    end
                    if ~isnan(thresholds.don) || ~isnan(thresholds.sum)
                        donor = conv(self.series(n).donor(self.series(n).crop.min:end), kernel, 'valid');
                        crop_max = ...
                            min(min(crop_max, ...
                                [find(donor < thresholds.don, 1, 'first') + W0, inf]));
                    end
                    if ~isnan(thresholds.sum)
                        crop_max = ...
                            min(min(crop_max, ...
                                [find(donor+acceptor < thresholds.sum, 1, 'first') + W0, inf]));
                    end
                    if ~isnan(thresholds.pad)
                        crop_max = ...
                            crop_max - thresholds.pad;
                    end
                    if crop_max > 0
                        self.series(n).crop.max = crop_max + self.series(n).crop.min;
                        self.series(n).exclude = false;
                    else
                        self.series(n).exclude = true;
                    end
                end
            otherwise
                return
        end
        self.reset_posterior(self.controls.min_states:self.controls.max_states);
        self.set_control('crop', struct('max', self.series(self.controls.series.value).crop.max));
        self.refresh('ensemble', 'series');
    end
end