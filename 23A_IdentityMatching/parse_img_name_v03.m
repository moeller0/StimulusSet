function [prop_struct] = parse_img_name_v03(img_name_string)
% this rather simple mindedly, just parses the name string assung prior
% information about the name structure
% v02 completely changes the returned structure
%	but tries to keep the smarts of the older version
%	attribute separators are '-'
%	attribute names are followed by '_'

%disp(['Parsing: ', img_name_string]);
prop_struct = [];
missing_value_marker = 99999999;	% needed?

% example names
%ID_BT_120129_2_LK_120131-TRF_tweened_000.0pct-EXP_None-ORI_A-45_E010.jpg
%stretched_h100pct_w020pct.ID_001_CIT_nonfamiliar_faces-homo_sapiens-ORI_A000-001_A00_E00.jpg

% generel information about the input name
prop_struct.image.full_name = img_name_string;
% chop off and store the file extension
[dummy, img_name_string, cur_ext] = fileparts(img_name_string);
prop_struct.image.base_name = img_name_string;
prop_struct.image.type = cur_ext(2:end);

% for stretched_h100pct_w020pct.ID_001_CIT_nonfamiliar_faces-homo_sapiens-ORI_A000-001_A00_E00.jpg
% style names change into:
% %TRF-stretched_h100pct_w020pct_ID_001_CIT_nonfamiliar_faces-homo_sapiens-ORI_A000-001_A00_E00.jpg
% and process further below
transform_descriptor_end_idx = strfind(img_name_string, '.ID_');
if ~isempty(transform_descriptor_end_idx)
	img_name_string(transform_descriptor_end_idx(1)) = '-';
	img_name_string = ['TRF_', img_name_string];
end

n_chars_in_name =length(img_name_string);
% now find start and end indices for all known name components
% known name components
component_list = {'ID_', 'ORI_', 'TRF_', 'EXP_', 'BG_'};
comp_idx_list = zeros(size(component_list));
% find the offset of each component
for i_comp = 1 : length(component_list)
	cur_idx = strfind(img_name_string, component_list{i_comp});
	if ~isempty(cur_idx)
		comp_idx_list(i_comp) = cur_idx(1);
	end
end
% allow for missing components
component_list = component_list(find(comp_idx_list));
sorted_component_string_list = cell(size(component_list));
comp_idx_list = comp_idx_list(find(comp_idx_list));

[sorted_comp_idx, sorted_comp_idx2] = sort(comp_idx_list);
sorted_comp_end_idx = [sorted_comp_idx(2:end), length(img_name_string) + 1] - 1;	% get rid of the separator
sorted_component_list = component_list(sorted_comp_idx2);
% get all the individual component strings
for i_comp = 1 : length(sorted_component_list)
	cur_sorted_component = sorted_component_list{i_comp};
	component_data_offset = length(cur_sorted_component);	% where does the payload start
	sorted_component_string_list{i_comp} = img_name_string(sorted_comp_idx(i_comp) + component_data_offset : sorted_comp_end_idx(i_comp));
end

% now do something with the extracted component
for i_comp = 1 : length(sorted_component_string_list)
	cur_comp_data_string = sorted_component_string_list{i_comp};
	% chomp of the field separator - if it follows the field
	if ((i_comp < length(sorted_component_string_list)) & (strcmp(cur_comp_data_string(end), '-')))
		cur_comp_data_string = cur_comp_data_string(1:end-1);
	end
	cur_comp_type = sorted_component_list{i_comp}(1:end - 1);
	%disp(cur_comp_type); disp(cur_comp_data_string);
	% move component parsing to sub functions if complexity requires it
	switch cur_comp_type
		case 'ID'
			% identity: might contain the name of the source collection
			prop_struct.attr.(cur_comp_type) = parse_ID_string(cur_comp_data_string, img_name_string);
		case 'ORI'
			% orientation: the ORI string might be followed by an unlabelled shortID (without source collection) AZI ELE component
			prop_struct.attr.(cur_comp_type) = parse_ORI_string(cur_comp_data_string, img_name_string);
			prop_struct.attr.(cur_comp_type).string = cur_comp_data_string;
		case 'EXP'
			% expression
			prop_struct.attr.(cur_comp_type).string = cur_comp_data_string;
		case 'TRF'
			% transform: seems to work
			prop_struct.attr.(cur_comp_type) = parse_TRF_string(cur_comp_data_string);
		case 'BG'
			% background:
			prop_struct.attr.(cur_comp_type).string = cur_comp_data_string;
		otherwise
			prop_struct.(cur_comp_type).string = cur_comp_data_string;
			error(['Component type: ', cur_comp_type, ' not handeled yet']);
	end
end

%for tweened identities both source IDs and the tween percentage are
% required...
if isfield(prop_struct.attr, 'TRF')
	if isfield(prop_struct.attr.TRF, 'tweened')
		prop_struct.attr.ID.identity = [prop_struct.attr.ID.identity, prop_struct.attr.TRF.string];
	end
end
return
end


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ prop_struct_attr_TRF ] = parse_TRF_string(cur_comp_data_string)
% examples: stretched_h100pct_w020pct, tweened_000.0pct

prop_struct_attr_TRF.string = cur_comp_data_string;	% was .descriptor
% split by _
sep_idx = strfind(cur_comp_data_string, '_');
trf_type = prop_struct_attr_TRF.string(1 : sep_idx(1) - 1);
prop_struct_attr_TRF.(trf_type).name = trf_type;	% the name of the current transform

trf_value_string = cur_comp_data_string(sep_idx(1) : end);
unit_suffix = '';
% create unions for all unit types
before_pct_idx = strfind(trf_value_string, 'pct');	% so far we only have percent...
if ~isempty(before_pct_idx)
	unit_suffix = '_pct';
end
before_unit_idx = before_pct_idx;

% special case specific transforms
switch trf_type
	case 'stretched'
		% special case, requires both _h and _w, needs fixing for
		% stretched_h100pct_w020pct.ID_001_CIT_nonfamiliar_faces-homo_sapiens-ORI_A000-001_A00_E00.jpg
		h_start_tmp = strfind(trf_value_string, '_h');
		h_start = h_start_tmp + 2;
		w_start_tmp = strfind(trf_value_string, '_w');
		w_start = w_start_tmp + 2;
		prop_struct_attr_TRF.(trf_type).([trf_type, '_h', unit_suffix]) = str2double(trf_value_string(h_start:before_unit_idx(1) - 1));
		prop_struct_attr_TRF.(trf_type).([trf_type, '_w', unit_suffix]) = str2double(trf_value_string(w_start:before_unit_idx(2) - 1));
	otherwise
		% test for simple name_value_unit constructs and parse those, error
		% out otherwise...
		if length(before_unit_idx) == 1
			name_unit = [trf_type, unit_suffix];
			prop_struct_attr_TRF.(trf_type).(name_unit) = str2double(trf_value_string(2:before_unit_idx(1) - 1));
		else
			error(['Multi value transformation ', trf_type, ' not handeled yet, exiting']);
		end
end

return
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ prop_struct_attr_ID ] = parse_ID_string(cur_comp_data_string, img_name_string)
% examples: BT_120129_2_LK_120131, 001_CIT_nonfamiliar_faces-homo_sapiens

prop_struct_attr_ID.string = cur_comp_data_string;	% this is the fullidentity incuding potential source
% for tweened IDs we have two source IDs
if ~isempty(strfind(img_name_string, 'TRF_tweened'))
	tween_sep_string = '_2_';
	tween_sep_idx = strfind(cur_comp_data_string, tween_sep_string);
	if ~isempty(tween_sep_idx)
		% recursively fill
%		prop_struct_attr_ID.srcID1.string = cur_comp_data_string(1 : tween_sep_idx(1) - 1);
%		prop_struct_attr_ID.srcID2.string = cur_comp_data_string(tween_sep_idx(1) + length(tween_sep_string):end);
		prop_struct_attr_ID.tweenedID1 = parse_ID_string(cur_comp_data_string(1 : tween_sep_idx(1) - 1), img_name_string);
		prop_struct_attr_ID.tweenedID2 = parse_ID_string(cur_comp_data_string(tween_sep_idx(1) + length(tween_sep_string):end), img_name_string);
	end
end

% get the pure identity string for all data bases
ID_end_idx = max([ strfind(cur_comp_data_string, '_CIT_familiar') ...
	strfind(cur_comp_data_string, '_CIT_nonfamiliar') ...
	strfind(cur_comp_data_string, '_MultiPIE') ...
	strfind(cur_comp_data_string, 'tweened_')]) - 1;
if isempty(ID_end_idx)
	ID_end_idx = length(cur_comp_data_string);
end
prop_struct_attr_ID.identity = cur_comp_data_string(1 : ID_end_idx);


if (~isempty(strfind(cur_comp_data_string, 'homo_sapiens')))
	prop_struct_attr_ID.TYPE = 'human';
end
if (~isempty(strfind(cur_comp_data_string, 'macacca_mulatta')))
	prop_struct_attr_ID.TYPE = 'macacca';
end
if (~isempty(strfind(cur_comp_data_string, 'objects-none')))
	prop_struct_attr_ID.TYPE = 'object';
end

if ~isempty(strfind(cur_comp_data_string, '_CIT_familiar'))
	prop_struct_attr_ID.SOURCE = 'CIT';
	prop_struct_attr_ID.FAMILIARITY = 'familiar';
elseif ~isempty(strfind(cur_comp_data_string, '_CIT_EE'))
	prop_struct_attr_ID.SOURCE = 'CIT';
	prop_struct_attr_ID.FAMILIARITY = 'familiar';
elseif ~isempty(strfind(cur_comp_data_string, '_CIT_nonfamiliar'))
	prop_struct_attr_ID.SOURCE = 'CIT';
	prop_struct_attr_ID.FAMILIARITY = 'nonfamiliar';
elseif ~isempty(strfind(cur_comp_data_string, '_MultiPIE'))
	prop_struct_attr_ID.SOURCE = 'PIE';
	prop_struct_attr_ID.FAMILIARITY = 'nonfamiliar';
end

return
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ prop_struct_attr_ORI ] = parse_ORI_string(cur_comp_data_string, img_name_string)
% examples: A-45_E010, A000-001_A00_E00
prop_struct_attr_ORI.azi = 99999999;
prop_struct_attr_ORI.ele = 99999999;
extract_ori_harder = 0;

prop_struct_attr_ORI.string = cur_comp_data_string;
switch cur_comp_data_string(1)
	case 'A'
		azi_start_idx = 2;
		ele_descriptor_idx = strfind(cur_comp_data_string, '_E');
		if ~isempty(ele_descriptor_idx);
			proto_azi = str2double(cur_comp_data_string(azi_start_idx : ele_descriptor_idx(1) - 1));
			if ~isnan(proto_azi)
				prop_struct_attr_ORI.azi = proto_azi;
				% now get ele_end_idx
				ele_start_idx = ele_descriptor_idx(1) + 2;	% the search string is 2 chars wide...
				% the ele string might be followed by hyphen short ID (e.g.
				% '-bowl') so handle this gracefully
				ele_end_idx = min((strfind(cur_comp_data_string(ele_start_idx + 2: end), '-') + ele_start_idx + 0), length(cur_comp_data_string));				
				proto_ele = str2double(cur_comp_data_string(ele_start_idx : ele_end_idx));
				if ~isnan(proto_ele)
					prop_struct_attr_ORI.ele = proto_ele;
					prop_struct_attr_ORI.string = cur_comp_data_string(1 : ele_end_idx); % delete the short ID trailer
				else
					%2nd ORI string type, A000-001_A00_E00
					extract_ori_harder = 1;
				end
			else
				%2nd ORI string type, A000-001_A00_E00
				extract_ori_harder = 1;
			end
		end
	case 'E'
		ele_start_idx = 2;
		azi_descriptor_idx = strfind(cur_comp_data_string, '_A');
		if ~isempty(azi_descriptor_idx);
			proto_ele = str2double(cur_comp_data_string(ele_start_idx : azi_descriptor_idx(1) - 1));
			if ~isnan(proto_ele)
				prop_struct_attr_ORI.ele = proto_ele;
				% now get azi_end_idx
				azi_start_idx = azi_descriptor_idx(1) + 2;
				azi_end_idx = min((strfind(cur_comp_data_string(azi_start_idx + 2: end), '-') + azi_start_idx + 0), length(cur_comp_data_string));				

				proto_azi = str2double(cur_comp_data_string(azi_start_idx : azi_end_idx));
				if ~isnan(proto_azi)
					prop_struct_attr_ORI.azi = proto_azi;
					prop_struct_attr_ORI.string = cur_comp_data_string(1 : azi_end_idx); % delete the short ID trailer
				else
					%2nd ORI string type, A000-001_A00_E00
					extract_ori_harder = 1;
				end
			else
				%2nd ORI string type, A000-001_A00_E00
				extract_ori_harder = 1;
			end
		end

	otherwise
		error(['ORI string start ', cur_comp_data_string(1), ' not handeled yet']);
end

if (extract_ori_harder)
	azi_start_idx = strfind(cur_comp_data_string, '_A');
	ele_start_idx = strfind(cur_comp_data_string, '_E');
	proto_azi = str2double(cur_comp_data_string(azi_start_idx + 2 : ele_start_idx - 1));
	if ~isnan(proto_azi) & (prop_struct_attr_ORI.azi == 99999999)
		prop_struct_attr_ORI.azi = proto_azi;
	end
	proto_ele = str2double(cur_comp_data_string(ele_start_idx + 2 :end));
	if ~isnan(proto_ele) & (prop_struct_attr_ORI.ele == 99999999)
		prop_struct_attr_ORI.ele = proto_ele;
	end

end

% ORI_string = img_name_string(ORI_start: ORI_end);
% short_ID_AZI_string_start = strfind(ORI_string(7:end), '-');
% short_ID_AZI_string = ORI_string(short_ID_AZI_string_start(1) + 7: strfind(ORI_string, '.') - 1);
% field_sep_idx = strfind(short_ID_AZI_string, '_');
%
% prop_struct.ID_AZI_ELE = short_ID_AZI_string;
% prop_struct.ID = short_ID_AZI_string(1:field_sep_idx(1) - 1);

return
end