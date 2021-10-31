function [ output_args ] = create_touch_forced_choice_mediasection_fam_humans_masked_01( input_args )
%CREATE_FORCED_CHOICE_PARAD Summary of this function goes here
%   Detailed explanation goes here
% the idea is to create a Forced_choice paradigm file from a list of images
% TODO simplify and unify the creation of target entries
%	 since this will be needed some time clean up thiss mess
%	implement 'masking' of the distractor images to make target more
%	salient... (better implement inside the kofiko paradigm)

% NEW this only writes the image part of Shay's new XML configuration
% files for touchforcedchoice...
%  <Image Name = "face1-0" FileName =
%  "\\KOFIKO-USER-23A\StimulusSet\AM_familiarity_02\face1_0.jpg" Attr = "IdentityMatching_Exp1;Face1"> </Image>

[cur_mfiledir, cur_mfile_name] = fileparts(mfilename('fullpath'));
%addpath(fullfile(pwd, 'combinator'));
tic

% read in the images in the image directory
transform_type = 'masked';	% masked or											stretched
transform_instance = 'phase_scramble'; % randomdot, randomdot_lp, phase_scramble;	stretched
attribute_set = 'ID-TF'; % ID, ID-TF, view, all
subset = 'familiar-humans_';

touchforcedchoice_xml_image_section = ['touchforcedchoice_xml_image_section_', subset, transform_type, '_', transform_instance, '_', attribute_set,'_attributes_01.txt'];	% the name of the image list

% where to collect the images from relative to this script
relative_target_img_dir = fullfile('..' , ['AM_familiarity_02_', transform_type], transform_instance);	% where to find the potential target images, relative to this script's directory

% what should end up in the xml file, ATTENTION windows pathnames
% recommended
kofiko_system = 'KOFIKO-USER-23A';
abs_img_path_4_kofiko = ['\\', kofiko_system, '\', 'StimulusSet', '\', ['AM_familiarity_02_', transform_type], '\', transform_instance];
main_exp_name_string = 'humans';	% just a convenient way to include an arbitrary attribute for the whole list


%ID_selection = {'MS', 'SN', 'ME', 'OS', 'maurice', 'bert', 'feivel', 'julien'};
ID_selection = {'MS', 'SN', 'ME', 'OS', 'TD', 'BT'};	% this affects both targets and same cat distractors
ID_selection = {};
fixed_target_ids = {}; %{'MS'};			% select a subset of IDs to use as target
fixed_distractor_stems = {}; %{'MS'};		% select a subset of stems to use as distractor(s)
max_IDs = 8;	% if not zero restrict the number of IDs to the minimum of max_IDs and existing IDs

% helper variables
tab = char(9);


% target same cat images
[img_list, img_properties] = get_names_and_props_from_dir_and_wildcard(fullfile(cur_mfiledir, relative_target_img_dir), '*.jpg');
n_same_cat_imgs = length(img_list);

% collect the properties in cel arrays to allow selection of subsets
for i_img = 1 : n_same_cat_imgs
	% <Image Name = "face1-0" FileName =
	%  "\\KOFIKO-USER-23A\StimulusSet\AM_familiarity_02\face1_0.jpg" Attr =
	%  "IdentityMatching_Exp1;Face1"> </Image>
	cur_img_idx = i_img;
	
	ID_AZI_ELE_list{i_img} = img_properties{cur_img_idx}.ID_AZI_ELE;
	ID_list{i_img} = img_properties{cur_img_idx}.ID;
	AZI_list(i_img) = img_properties{cur_img_idx}.AZI;
	%ELE_list(i_img) = img_properties{cur_img_idx}.ELE;
	SOURCE_list{i_img} = img_properties{cur_img_idx}.SOURCE;
	TYPE_list{i_img} = img_properties{cur_img_idx}.TYPE;
	FAMILIARITY_list{i_img} = img_properties{cur_img_idx}.FAMILIARITY;
	TRANSFORMATION_list{i_img} = img_properties{cur_img_idx}.transform.descriptor;
	
	% construct the values for each image to put in the media section of
	% the xml file
	FileName_list{cur_img_idx} = [abs_img_path_4_kofiko, '\', img_list{cur_img_idx}];	% WINDOWS UNC PATH
	% this is just an identifier???
	Image_Name_list{i_img} = ['ID-', img_properties{cur_img_idx}.ID, '_ORI-A', num2str(img_properties{cur_img_idx}.AZI, '%03d'), '_TRF-', TRANSFORMATION_list{i_img}];
	
	switch attribute_set
		case 'all'
			% full attribute list
			Attr_list{i_img} = [main_exp_name_string, ';', ['ID_', img_properties{cur_img_idx}.ID], ';', ['AZI_', num2str(img_properties{cur_img_idx}.AZI, '%03d')], ';', TYPE_list{i_img}, ';', FAMILIARITY_list{i_img}, ';', SOURCE_list{i_img}, ';', TRANSFORMATION_list{i_img}];
		case 'ID'
			% ID attribute list
			Attr_list{i_img} = [main_exp_name_string, ';', ['ID_', img_properties{cur_img_idx}.ID]];
		case 'ID-TF'
			% ID attribute list
			Attr_list{i_img} = [main_exp_name_string, ';', ['ID_', img_properties{cur_img_idx}.ID], ';', TRANSFORMATION_list{i_img}];

		case 'view'
			% view attribute list
			Attr_list{i_img} = [main_exp_name_string, ';', ['AZI_', num2str(img_properties{cur_img_idx}.AZI, '%03d')]];
		otherwise
			error(['Unknown attibute_set encountered: ', attribute_set, ' is not handle]ed yet.']);		
	end
end

% TODO collect relevant subset
img_selection_list = 1:1:n_same_cat_imgs;	% ALL images
FAMILIAR_img_idx = find(ismember(FAMILIARITY_list, 'familiar'));
NONFAMILIAR_img_idx = find(ismember(FAMILIARITY_list, 'nonfamiliar'));
HUMAN_img_idx = find(ismember(TYPE_list, 'human'));
MONKEY_img_idx = find(ismember(TYPE_list, 'macacca'));
OBJECT_img_idx = find(ismember(TYPE_list, 'object'));
FRONTAL_idx = find(ismember(AZI_list, 0));
PROFILE_idx = find(ismember(AZI_list, [-90, 90]));



% no objects
img_selection_list = setdiff(FAMILIAR_img_idx, MONKEY_img_idx);
img_selection_list = setdiff(img_selection_list, OBJECT_img_idx);
img_selection_list = setdiff(img_selection_list, PROFILE_idx);

% max_IDs = 0 means take all you can find
if (max_IDs > 0)
	IDs_in_subset_list = unique(ID_list(img_selection_list));
	if (max_IDs < length(IDs_in_subset_list))
		SELECTED_IDs_idx = find(ismember(ID_list, IDs_in_subset_list(1:max_IDs)));
		img_selection_list = intersect(img_selection_list, SELECTED_IDs_idx);
	end
end


% now each image might be presented at different positions
disp('Creating the image section');
% % create the position list and the name suffix
% [position_list, position_name_list] = create_choice_positions_and_names(choice);


% now write the media section to the file
fcd_fh = fopen(fullfile(cur_mfiledir, touchforcedchoice_xml_image_section), 'w+');
if (fcd_fh == -1)
	error(['Could not open ', fullfile(cur_mfiledir, touchforcedchoice_xml_image_section), ' for writing, aborting...']);
end

% xml section start
fprintf(fcd_fh, ' <Media>\r\n');

% TODO include the masking level as attribute
for i_img = 1 : length(img_selection_list)
	% <Image Name = "face1-0" FileName =
	%  "\\KOFIKO-USER-23A\StimulusSet\AM_familiarity_02\face1_0.jpg" Attr =
	%  "IdentityMatching_Exp1;Face1"> </Image>
	real_img_idx = img_selection_list(i_img);
	fprintf(fcd_fh, ' <Image Name = \"%s\" FileName = \"%s\" Attr = \"%s\"> </Image>\r\n', Image_Name_list{real_img_idx}, FileName_list{real_img_idx}, Attr_list{real_img_idx});
end

% xml section stop
fprintf(fcd_fh, ' </Media>\r\n');
% clean-up
fclose(fcd_fh);

disp(['Done... (', cur_mfile_name, ')']);
toc
return
end







function [prop_struct] = parse_img_name(img_name_string)
% this rather simple mindedly, just parses the name string assung prior
% information about the name structure
disp(['Parsing: ', img_name_string]);
prop_struct = [];

orig_img_name_string = img_name_string;
% chop off the transform descriptor up to the first dot
dot_idx = strfind(orig_img_name_string, '.');
if length(dot_idx) >= 2
	% okay name contains transfom descriptor, parse it and chop it off
	img_name_string = orig_img_name_string(dot_idx(1) + 1 : end);
	prop_struct.transform.descriptor = orig_img_name_string(1 : dot_idx(1) - 1);
	sep_idx = strfind(prop_struct.transform.descriptor, '_');
	% the next is a string
	prop_struct.transform.name = prop_struct.transform.descriptor(1 : sep_idx(1) - 1);
	% might contain multiple values, so take as string for the time being
	prop_struct.transform.value = prop_struct.transform.descriptor(sep_idx(1) + 1 : end);
	before_pct_idx = strfind(prop_struct.transform.value, 'pct') - 1;
	switch prop_struct.transform.name
		case 'masked'
			prop_struct.transform.mask_pct = str2double(prop_struct.transform.value(1:before_pct_idx(1)));
		case 'stretched'
			% stretched_h100pct_w020pct.ID_001_CIT_nonfamiliar_faces-homo_sapiens-ORI_A000-001_A00_E00.jpg
			h_start_tmp = strfind(prop_struct.transform.value, '_h');
			h_start = h_start_tmp + 2;
			w_start_tmp = strfind(prop_struct.transform.value, '_w');
			w_start = w_start_tmp + 2;					
			prop_struct.transform.stretch_h_pct = str2double(prop_struct.transform.value(h_start:before_pct_idx));
			prop_struct.transform.stretch_w_pct = str2double(prop_struct.transform.value(w_start:before_pct_idx));
		otherwise
			error(['Transformation ', prop_struct.transform.name, ' not handeled yet, exiting']);
	end
	
end


n_chars_in_name =length(img_name_string);

ID_start = strfind(img_name_string, 'ID');
ORI_start = strfind(img_name_string, 'ORI');

if ID_start < ORI_start
	ID_end = ORI_start;
	ORI_end = n_chars_in_name;
else
	ID_end = n_chars_in_name;
	ORI_end = ID_start;
end

ORI_string = img_name_string(ORI_start: ORI_end);
short_ID_AZI_string_start = strfind(ORI_string(7:end), '-');
short_ID_AZI_string = ORI_string(short_ID_AZI_string_start(1) + 7: strfind(ORI_string, '.') - 1);
field_sep_idx = strfind(short_ID_AZI_string, '_');

prop_struct.ID_AZI_ELE = short_ID_AZI_string;
prop_struct.ID = short_ID_AZI_string(1:field_sep_idx(1) - 1);
if (length(field_sep_idx) > 1)
	prop_struct.AZI = str2num(short_ID_AZI_string(field_sep_idx(1) + 2: field_sep_idx(2) - 1));
	prop_struct.ELE = str2num(short_ID_AZI_string(field_sep_idx(2) + 2: end));
else
	% for objects we set everything to out of bounds
	prop_struct.ID = short_ID_AZI_string;
	prop_struct.AZI = 99999999;
	prop_struct.ELE = 99999999;
end

% get the identity string
ID_start_idx = strfind(img_name_string, 'ID_') + 3;
% cover all data base
ID_end_idx = max([ strfind(img_name_string, '_CIT_familiar') ...
	strfind(img_name_string, '_CIT_nonfamiliar') ...
	strfind(img_name_string, '_MultiPIE')]) - 1;
prop_struct.identity = img_name_string(ID_start_idx: ID_end_idx);

if (~isempty(strfind(img_name_string, 'homo_sapiens')))
	prop_struct.TYPE = 'human';
end
if (~isempty(strfind(img_name_string, 'macacca_mulatta')))
	prop_struct.TYPE = 'macacca';
end
if (~isempty(strfind(img_name_string, 'objects-none')))
	prop_struct.TYPE = 'object';
end

if ~isempty(strfind(img_name_string, '_CIT_familiar'))
	prop_struct.SOURCE = 'CIT';
	prop_struct.FAMILIARITY = 'familiar';
elseif ~isempty(strfind(img_name_string, '_CIT_nonfamiliar'))
	prop_struct.SOURCE = 'CIT';
	prop_struct.FAMILIARITY = 'nonfamiliar';
elseif ~isempty(strfind(img_name_string, '_MultiPIE'))
	prop_struct.SOURCE = 'PIE';
	prop_struct.FAMILIARITY = 'nonfamiliar';
end

return
end

function [position_list, position_name_list] = create_choice_positions_and_names(choice)
% create a list of choice positions (as 2D coordinates relative to center)
% and a list of matching position names

position_list = zeros([2, choice.n_pos]);
position_name_list = [];

angle_per_pos_deg = (360 / choice.n_pos);
angle_per_pos_rad = deg2rad(angle_per_pos_deg);


% special case angles unless overridden
switch choice.n_pos
	case 2
		if isempty(choice.offset_angle_deg)
			choice.offset_angle_deg = 0;
		end
		if isempty(position_name_list)
			position_name_list = {'right_middle', 'left_middle'};
		end
	case 4
		if isempty(choice.offset_angle_deg)
			choice.offset_angle_deg = -45;
		end
		if isempty(position_name_list)
			position_name_list = {'right_up', 'right_down', 'left_down', 'left_up'};
		end
end
choice.offset_angle_rad = deg2rad(choice.offset_angle_deg);
% if nothing was specified mark each position name as empty
if isempty(position_name_list)
	position_name_list = cell([1 choice.n_pos]);
end

for i_pos = 1 : choice.n_pos;
	[X, Y] = pol2cart(((i_pos - 1) * angle_per_pos_rad + choice.offset_angle_rad), choice.excentricity_radius_pix);
	disp(['X: ', num2str(X), ' Y: ', num2str(Y)]);
	position_list(:, i_pos) = [round(X); round(Y)];
	% create position names as rounded angles oin degree
	if isempty(position_name_list{i_pos})
		[THETA_rad, RHO] = cart2pol(X, Y);
		THETA_deg = rad2deg(THETA_rad);
		position_name_list{i_pos} = num2str(round(THETA_deg), '%03d');
	end
end

return
end

function [file_list, file_properties] = get_names_and_props_from_dir_and_wildcard(file_src_dir, wildcard_string)
% return a cell array of all files that match the wildcard, plus a cell
% array with the properties of those files (will only work with proper file names)

proto_file_list = dir(fullfile(file_src_dir, wildcard_string));
n_matching_files = length(proto_file_list);

% pre allocate...
file_list = cell([1, n_matching_files]);
file_properties = cell([1, n_matching_files]);

for i_matching_file = 1 : n_matching_files
	% 	cur_file_name = proto_file_list(i_matching_file).name;
	% 	img_list{i_matching_file} = cur_file_name;
	% 	cur_img_properties = parse_img_name(cur_img_name);
	% 	file_properties{i_matching_file} = cur_img_properties;
	file_list{i_matching_file} = proto_file_list(i_matching_file).name;
	file_properties{i_matching_file} = parse_img_name(proto_file_list(i_matching_file).name);
end

return
end

function [ cur_remaining_pos ] = shuffle_and_draw_remaning_pos(remaining_pos, n_distractor_pos)
if (n_distractor_pos < length(remaining_pos))
	shuffeled_remaining_pos_idx = randperm(length(remaining_pos));
	cur_remaining_pos = remaining_pos(shuffeled_remaining_pos_idx(1:n_distractor_pos));
else
	cur_remaining_pos = remaining_pos;
end
return
end

