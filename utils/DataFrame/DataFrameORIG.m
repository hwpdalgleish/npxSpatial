classdef DataFrame < dynamicprops
    %DATAFRAME - an implementation of a DataFrame class for Matlab
    % DATAFRAME - inspired by Pandas and R DataFrame, this class wraps the
    %   Matlab table datatype as an object oriented alternative
    %
    %   Original author NickRoth (nick.roth@nou-systems.com), but
    %   extended by Henry Dalgleish (hwpdalgleish@gmail.com) 20200612
    %
    % SYNTAX:
    %   df = DataFrame( varargin )
    %
    % Description:
    %   df = DataFrame( varargin ) the DataFrame literally passes the input
    %   arguement on to the table during construction
    %
    % PROPERTIES:
    %   (dynamic) - the DataFrame properties will match the
    %   table.Properties.VariableNames
    %
    % INITIALIZATION:
    %   df = DataFrame(0, 0, 0, 0, 'VariableNames', ...
    %             {'test1', 'test2','test3','test4',})
    %   df.head()
    %
    % REFERENCING:
    %   e.g. for the below DataFrame:
    %
    %            df = 
    %                       Var1    Var2
    %                       ____    ____
    %
    %               0       0.5     0 
    %               5       1       1 
    %               10      0.1     2 
    %
    %   NB: this has two columns (Var1 and Var2) and three rows, with index
    %   labels [0 5 10]. These can be referenced in the below ways
    %
    %
    %   df([1 2 3],1) or df{[1 2 3],1}
    %
    %   -- standard matrix indexing (integer position along rows/columns).
    %   This will return rows 1, 2 and 3 and the first column. Note can use
    %   logical indexing as well. 
    %
    %   RETURNS: Using () will return a DataFrame, using {} will return a
    %   matrix. i.e. df{[1 2 3],1} will return a matrix.
    % 
    %   df([1 2 3],'Var1') or df{[1 2 3],'Var1'}
    %
    %   -- standard table indexing: returns rows 1, 2 and 3 and the column
    %   named 'Var1'. To return multiple columns use cell array of column
    %   names, e.g. {'Var1' 'Var2'}. 
    %
    %   RETURNS: Again Using () will return a DataFrame, using {} will
    %   return a matrix (see above for example)
    %
    %   df.loc([0 5 10],'Var1') or df.loc{[0 5 10],'Var1'}
    %
    %   -- using the .loc method: rows can be indexed either with logical
    %   indexing (as above) or accessed by their index label (as in this
    %   example). In this case rows 1, 2 and 3 are returned because they
    %   are referenced by their index labels 0, 5 and 10. Note that using
    %   integer row inputs with the .loc method will NEVER reference rows
    %   by their integer position along the index (as would be the case
    %   with standard matrix indexing).
    %
    %   RETURNS: Using () will return a DataFrame, using {} will return a
    %   matrix. i.e. df{[1 2 3],1} will return a matrix. All columns must
    %   be numeric.
    %
    % SEE ALSO: table
    %
    
    %% Properties
    properties
        Properties
    end
    
    properties (Access = private)
        data
    end
    
    %% Methods
    methods
        % DATAFRAME Constructor
        function self = DataFrame(varargin)
            if ~isempty(varargin)
                idxInput = find(strcmp(varargin,'Index'));
                idxPresent = ~isempty(idxInput);
                tblInput = cellfun(@(x) istable(x),varargin);
                isTable = any(tblInput);
                
                % Construct dataframe from table
                if isTable
                    tbl = varargin{tblInput};
                    if idxPresent
                        idx = varargin{idxInput+1};
                        if ischar(idx)
                            idxCol = tbl.(idx);
                            tbl.(idx) = [];
                        elseif isnumeric(idx)
                            idxCol = idx;
                        elseif iscell(idx)
                            idxCol = idx;
                        end
                    elseif ~isempty(tbl.Properties.RowNames)
                        idxCol = tbl.Properties.RowNames;
                    else
                        idxCol = 1:size(tbl,1);
                    end
                    
                    % Process inputs as if we are a Matlab table
                else
                    nameInput = find(strcmp(varargin,'VariableNames'))+1;
                    if idxPresent
                        idx = varargin{idxInput+1};
                        if ischar(idx)
                            idxColN = find(strcmp(varargin{nameInput},idx));
                            idxCol = varargin{idxColN};
                            varargin{nameInput}(idxColN) = [];
                            varargin([idxColN idxInput idxInput+1]) = [];
                        elseif isnumeric(idx)
                            idxCol = idx;
                            varargin([idxInput idxInput+1]) = [];
                        elseif iscell(idx)
                            idxCol = idx;
                            varargin([idxInput idxInput+1]) = [];
                        end
                    else
                        idxCol = 1:numel(varargin{1});
                    end
                    
                    if ~iscell(idxCol)
                        idxCol = cellfun(@(x) num2str(x),num2cell(idxCol),'UniformOutput',0);
                    end
                end
                
                % make sure index is cell of str
                if ~iscell(idxCol)
                    idxCol = cellfun(@(x) num2str(x),num2cell(idxCol),'UniformOutput',0);
                elseif iscell(idxCol)
                    idxCol = cellfun(@(x) num2str(x),idxCol,'UniformOutput',0);
                end
                
                % create final DataFrame incorporating the appropriate index
                if isTable
                    tbl.Properties.RowNames = idxCol;
                    self.data = tbl;
                else
                    self.data = table(varargin{:},'RowNames',idxCol);
                end
            else
                self.data = table();
            end
            self.update_props();
        end
        
        function out = dataTypes(self)
            out = varfun(@class,self.data);
            out.Properties.VariableNames = self.columns;
        end
             
        function toprows = head(self)
            %HEAD - implements the method that Pandas provides to see the
            %top rows of the table
            toprows = self.data(1:min(size(self.data,1),10), :);
            %disp(toprows);
        end
        
        function out = getTable(self)
            %GETTABLE - returns a Matlab table from DataFrame object
            
            out = self.data;
        end
        
        function details(self)
            %DETAILS - prints to console a detailed summary of the data
            %within the DataFrame
            
            builtin('disp', self);
            self.head();
            self.summary();
        end
        
        function bool = is_column(self, col)
            %IS_COLUMN - returns boolean value true if the given string is
            %a valid column
            
            bool = false;
            cols = self.data.Properties.VariableNames;
            if isempty(setdiff(col, cols))
                bool = true;
            end
        end
        
        function remove_cols(self, cols)
            %REMOVE_COLS - removes columns from the DataFrame, given a
            %single string, or a cell array of strings
            
            cols = cellstr(cols);
            for i = 1:length(cols)
                mp = findprop(self, cols{i});
                delete(mp);
            end
            self.data(:, cols) = [];
        end
        
        function out = columns(self)
            %COLUMNS - provides an alternative way to access the column
            %names of the DataFrame
            
            out = self.data.Properties.VariableNames;
        end
    end
    
    methods (Access = private)
        function update_props(self)
            %UDPATE_PROPS - adds the table variables to the class as
            %dynamic properties. This way we can make it look like the
            %DataFrame object is actually a table
            
            vars = self.data.Properties.VariableNames;
            for i = 1:length(vars)
                var = vars{i};
                self.addprop(var);
            end
        end

        function out = isNumericCol(self)
            out = varfun(@(x) isa(x,'numeric'),self.data,'OutputFormat','uniform');
        end
        
        function out = data_types(self)
            out = varfun(@class,self.data,'OutputFormat','cell');
        end
        
        function out = num2idx(self,idx)
            if isnumeric(idx)
                idx = cellfun(@(x) num2str(x),num2cell(idx),'UniformOutput',0);
            end
            self.data.Properties.RowNames = idx;
            out = self;
        end
        
        function S = proc_call(self,S)
            % this processes any reference/assignment calls
            % if a DataFrame method, S will pass through unchanged
            potentialMethods = cellfun(@(x) ischar(x),{S(:).subs});
            methods = cellfun(@(x) ismethod(self,x),{S(potentialMethods).subs});
            
            keyboard
            % for multi-level indexing (without a method)
            if numel(S)==2 && ~any(methods) %~ismethod(self, S(1).subs) && ~ismethod(self, S(2).subs) NB CHANGE THIS IF ISSUES
                col = strcmp({S(:).type},'.');
                S2.subs = [S(~col).subs S(col).subs];
                isLoc = strcmp(S2.subs,'loc');
                S2.subs(isLoc) = [];
                S2.type = S(~col).type;
                % if field notation
                if ~any(isLoc)
                    %S2.type = '()';
                    if (iscell(S2.subs) && all(cellfun(@(x) ischar(x),S2.subs))) && ~any(strcmp(S2.subs,':'))
                        S2.subs = {':' S2.subs};
                    end
                % if loc method
                else
                    %S2.type = '{}';
                    if numel(S2.subs)==1
                        % if only a single dimension is referenced and it isn't done using column names, throw error
                        if (isnumeric(S2.subs) || any(cellfun(@(x) isnumeric(x) | islogical(x),S2.subs)))
                            error('AssignError: single dimension indexing with loc can only take column names')
                        end
                    else
                        if ~strcmp(S2.subs{1},':')
                            S2.subs{1} = self.loc_idx(S2.subs{1});
                        end
                    end
                end
                S = S2;
                
            % for multi-level indexing (with a method)
            elseif numel(S)>1 && any(methods)
                keyboard
                thisMethod = find(potentialMethods);
                thisRef = find(~potentialMethods,1,'First');
                S2 = S(thisMethod:end);
                S2.ref = S(thisRef).subs;
                if iscell(S2.ref) && all(cellfun(@(x) ischar(x),S2.ref))
                    S2.ref = [{':'} S2.ref];
                end
                
            % for single-level indexing
            elseif strcmp(S.type,'.') && (iscell(S.subs) || (~iscell(S.subs) && ~ismethod(self, S.subs)))
                S.type = '()';
                if (iscell(S.subs) && all(cellfun(@(x) ischar(x),S.subs))) || ischar(S.subs)
                    S.subs = {':' S.subs};
                end
            end
        end
        
        function rowIdx = loc_idx(self,row)
            if isnumeric(row)
                rowIdx = ismember(cellfun(@(x) str2num(x),self.data.Row),row);
            elseif islogical(row)
                rowIdx = row;
            elseif strcmp(row,':')
                rowIdx = true(self.height,1);
                row = rowIdx;
            else
                error('KeyError: Key is of unrecognised type. Use index elements or logical array.')
            end
            if (islogical(row) && numel(row)~=size(self.data,1)) || (~islogical(row) && sum(rowIdx) ~= numel(row))
                error('KeyError: Key values do not match index')
            end
        end
        
        function out = idx2num(self)
            out = cellfun(@(x) str2num(x),self.Properties.RowNames);
        end
    end
    
    % Constructors
    methods (Static)
        function out = fromStruct(varargin)
            out = DataFrame(struct2table(varargin{:}));
        end
        
        function out = fromCSV(varargin)
            out = DataFrame(readtable(varargin{:}));
        end
        
        function out = fromArray(varargin)
            out = DataFrame(array2table(varargin{:}));
        end
        
        function out = fromCell(varargin)
            out = DataFrame(cell2table(varargin{:}));
        end
    end
    
    %% Pass Throughs
    methods
        function out = height(self)
            out = height(self.data);
        end
        
        function out = width(self)
            out = width(self.data);
        end
        
        function out = size(self,varargin)
            out = [height(self.data) width(self.data)];
            if nargin>1
                out = out(varargin{:});
            end
        end
        
        function summary(self)
            summary(self.data);
        end
        
        function out = toStruct(self)
            out = table2struct(self.data);
            for i = 1:size(self.data,1)
                out(i).DataFrameIdx = str2num(self.data.Properties.RowNames{i});
            end
        end
        
        function out = toCell(self)
            out = table2cell(self.data);
            out = [cellfun(@(x) str2num(x),self.data.Properties.RowNames,'UniformOutput',0) out];
        end
        
        function out = toArray(self)
            out = table2array(self.data);
            out = [cellfun(@(x) str2num(x),self.data.Properties.RowNames) out];
        end
        
        function writetable(self, varargin)
            writetable(self.data, varargin{:})
        end
        
        function out = get.Properties(self)
            out = self.data.Properties;
        end
        
        function out = set_index(self,idx)
            self.num2idx(idx);
            out = self;
        end
        
        function out = reset_index(self,varargin)
            drop = false;
            if nargin>1
                if strcmp(varargin{1},'drop')
                    drop = true;
                end
            end
            if ~drop
                self.data.index = self.idx2num();
            end
            self.set_index(cellfun(@(x) num2str(x),num2cell(1:self.height),'UniformOutput',0));
            out = self;
        end
        
        function out = index(self,varargin)
            if nargin==2
                out = cellfun(@(x) str2num(x),self.data.Properties.RowNames(varargin{1}));
            else
                out = cellfun(@(x) str2num(x),self.data.Properties.RowNames);
            end
        end
    end
    
    %% Static
    methods (Static)
        function [C,ia,ib] = intersect(A, B, varargin)
            [C,ia,ib] = intersect(A, B, varargin{:});
        end
        
        function [Lia, Locb] = ismember(A, B, varargin)
            [Lia, Locb] = ismember(A, B, varargin{:});
        end
        
        function out = rowfun(func, A, varargin)
            out = rowfun(func, A, varargin{:});
        end
        
        function out = varfun(func, A, varargin)
            out = varfun(func, A, varargin{:});
        end
    end
    
    %% Overrides
    methods
        
        function self = subsasgn(self, S, B)
            %SUBSASGN - overrides the builtin method so that we can
            %dynamically attach properties to the object when we are adding
            %new data to the DataFrame
            
            % If this column doesn't exist, add it to the object
            % Call builtin on the underlying Matlab table
            % check for loc assingment
            
            % check for row removal (i.e. [] assignment)
            assign = ~((isnumeric(B) | iscell(B)) & isempty(B));
            
            % Deal with multiple subscripted assignments. This can happen
            % either when we use field notation for column and ()/{} for
            % row, or with the loc method
            S = proc_call(self,S);
                      
            % process input (convert char to cell, force input type for
            % cells and force column)
            if ischar(B)
                B = {B};
            end
            if iscell(B) && ~strcmp(S.type,'.')
                S.type = '{}';
            end
            B = B(:);
            
            % assign: values, rows and columns
            if assign
                switch S.type
                    case '.'
                        valid_prop = setdiff(S.subs, {':'});
                        if length(valid_prop) == 1 && ~self.is_column(valid_prop)
                            self.addprop(valid_prop{:});
                        end
                        if numel(B)==1
                            if isnumeric(B) || iscell(B) || islogical(B)
                                B = repmat(B,size(self.data,1),1);
                            else
                                B = repmat({B},size(self.data,1),1);
                            end
                        end
                        self.data = builtin('subsasgn', self.data, S, B);
                        
                    case '()'
                        if numel(S.subs)==1
                            S.subs = [{':'} S.subs];
                        end
                        valid_prop = S.subs(~strcmp(S.subs,':'));
                        if length(valid_prop) == 1 && ~self.is_column(valid_prop)
                            self.addprop(valid_prop{:});
                        end
                        if ~iscell(B)
                            B = num2cell(B);
                        end
                        self.data = builtin('subsasgn', self.data, S, B);
                        
                    case '{}'
                        if numel(S.subs)==1
                            S.subs = [{':'} S.subs];
                        end
                        valid_prop = S.subs(~strcmp(S.subs,':'));
                        if length(valid_prop) == 1 && ~self.is_column(valid_prop)
                            self.addprop(valid_prop{:});
                        end
                        self.data = builtin('subsasgn', self.data, S, B);
                        
%                     case 'loc'
%                         S.type = '{}';
%                         valid_prop = S.subs(~strcmp(S.subs,':'));
%                         if length(valid_prop) == 1 && ~self.is_column(valid_prop)
%                             self.addprop(valid_prop{:});
%                         end
%                         self.data = builtin('subsasgn', self.data, S, B);
                        
                end
            % remove: rows and columns (NB cannot remove values)
            else
                switch S.type
                    case '.'
                        self.data(:,S.subs) = [];
                    case {'()' '{}' 'loc'}
                        if numel(S.subs)==1
                            self.data(:,S.subs{1}) = [];
                        else
                            if strcmp(S.subs{1},':')
                                self.data(:,S.subs{2}) = [];
                            elseif strcmp(S.subs{2},':')
                                self.data(S.subs{1},:) = [];
                            else
                                error('RemoveError: only complete rows/columns can be removed')
                            end
                        end
                end
            end
        end
        
        function [varargout] = subsref(self, S, varargin)
            %SUBSREF - overrides the subscript reference method, which
            %provides the way for us to wrap the built in table type
            
            keyboard
            
            varargout{1} = [];
            %Catch the subscript behavior so that we can pass through table
            %calls directly to it, and methods/class properties to the
            %DataFrame class
            
            % check if loc call has been used
            S = proc_call(self,S);
%             fcnCallCheck = strcmp({S(:).type},'.');
%             if any(fcnCallCheck)
%                 if any(strcmp(S(fcnCallCheck).subs,'loc'))
%                     S = S(~fcnCallCheck);
%                     if numel(S.subs)==1
%                         % if only a single dimension is referenced and it isn't done using column names, throw error
%                         if (isnumeric(S.subs) || any(cellfun(@(x) isnumeric(x) | islogical(x),S.subs)))
%                             error('AssignError: single dimension indexing with loc can only take column names')
%                         % otherwise replace missing dimension with :
%                         else
%                             S.subs = [{':'} S.subs];
%                         end
%                     end
%                     % convert index to row
%                     S.subs{1} = self.loc_idx(S.subs{1});
%                 end
%             end        
% 
%             if strcmp(S.type,'.') && iscell(S.subs)
%                 if all(cellfun(@(x) ischar(x),S.subs))
%                     S.type = '()';
%                     S.subs = {':' S.subs};
%                 end
%             end
            
            call_type = S.type;
            var = S.subs;
            
            switch call_type
                case '.'
                    if ismethod(self, var)
                        % check for method outputs
                        mc = metaclass(self);
                        ml = mc.MethodList;
                        meth = findobj(ml, 'Name', var);
                        
                        if isempty(meth.OutputNames)
                            % method calls without outputs
                            builtin('subsref', self, S);
                        else
                            varargout{1} = builtin('subsref', self, S);
                        end
                    else
                        %Pass through properties call
                        varargout{1} = builtin('subsref', self.data, S);
                    end
                case '()'
                    % Process the '()' subscripting directly on table
                    tbl = self.data;
                    if numel(S.subs)==1
                        S.subs = {':' S.subs{1}};
                    end
                    tbl = builtin('subsref', tbl, S);
                    varargout{1} = DataFrame(tbl,'Index',tbl.Properties.RowNames);
                case '{}'
                    % Process the '{}' subscripting directly on table
                    tbl = self.data;
                    if numel(S.subs)==1
                        S.subs = {':' S.subs{1}};
                    end
                    varargout{1} = builtin('subsref', tbl, S);
            end
        end
        
        function disp(self)
            %DISP - overrides the default disp method, which makes our
            %DataFrame look like a typical table

            disp(self.data);
        end
        
        function out = vertcat(varargin)
            try
                out = [];
                for i = 1:numel(varargin)
                    out = [out ; varargin{i}.data];
                end
                out = DataFrame(out);
            catch ME
                if strcmp(ME.identifier,'MATLAB:table:ExtractDataIncompatibleTypeError')
                end
            end
        end
        
        function out = horzcat(varargin)
            out = [];
            for i = 1:numel(varargin)
                out = [out varargin{i}.data];
            end
            out = DataFrame(out);
        end
        
        function out = numel(~, varargin)
            %NUMEL - override the default numel method. It is critical that
            %both the first arguement and second arguement, "varargin"
            %exists, since this directly affects when Matlab will call the
            %method. Otherwise, '{}' subscripting breaks.
            
            out = 1;
        end
    end
end

