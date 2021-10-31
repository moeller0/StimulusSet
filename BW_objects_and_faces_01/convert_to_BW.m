function [ output_args ] = convert_to_BW( input_args )
%CONVERT_TO_BW Summary of this function goes here
%   Detailed explanation goes here

timestamps.(mfilename).start = tic;
disp(['Starting: ', mfilename]);
dbstop if error
fq_mfilename = mfilename('fullpath');
mfilepath = fileparts(fq_mfilename);

% the objects
imgtype = '.png';
src_dir = fullfile('..');

% faces...
imgtype = '.jpg';
src_dir = fullfile('.');



dst_dir = pwd;

proto_img_list = dir(fullfile(src_dir, ['*', imgtype]));

for i_img = 1 : length(proto_img_list)
	cur_img_fqn = fullfile(src_dir, proto_img_list(i_img).name);
	%disp(cur_img_fqn);
	cur_img = imread(cur_img_fqn);
	if size(cur_img, 3) == 3
		cur_BW_img = rgb2gray(cur_img);
		imwrite(cur_BW_img, fullfile(dst_dir, proto_img_list(i_img).name));
	else
		disp(['Current image is not RGB, skipping: ', cur_img_fq]);
		imwrite(cur_img, fullfile(dst_dir, proto_img_list(i_img).name));
	end

end
	
timestamps.(mfilename).end = toc(timestamps.(mfilename).start);
disp([mfilename, ' took: ', num2str(timestamps.(mfilename).end), ' seconds. Done...']);
return

end

