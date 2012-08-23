function CompareMachines(machine, comp_machine)

CompareStructures(machine, comp_machine, 'machine');

end

function CompareStructures(in_struct, comp_struct, lead_str)

fn = fieldnames(in_struct);
cfn = fieldnames(comp_struct);
for i = 1:length(fn),
    if ~any(strcmp(fn{i}, cfn)),
        fprintf('%s.%s is not in the compared machine.\n', lead_str, fn{i});
        continue;
    end
    if isnumeric(in_struct.(fn{i})) | ischar(in_struct.(fn{i})),
        if (ndims(in_struct.(fn{i})) ~= ndims(comp_struct.(fn{i}))) | ...
            ~all(size(in_struct.(fn{i})) == size(comp_struct.(fn{i}))) | ...
                ~all(in_struct.(fn{i}) == comp_struct.(fn{i})),
            fprintf('ERROR: %s.%s doesn''t match.\n', lead_str, fn{i});
        else
            fprintf('%s.%s matches perfectly.\n', lead_str, fn{i});
        end
    elseif isstruct(in_struct.(fn{i})),
        if length(in_struct.(fn{i})) > 1,
            for j = 1:length(in_struct.(fn{i})),
                CompareStructures(in_struct.(fn{i})(j), comp_struct.(fn{i})(j), sprintf('%s.%s(%d)', lead_str, fn{i}, j));
            end
        else
            CompareStructures(in_struct.(fn{i}), comp_struct.(fn{i}), sprintf('%s.%s', lead_str, fn{i}));
        end
    end        
end
end