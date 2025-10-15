using PrettyTables

column_labels=(["Column1","Column2","Column3"])

data=[1 2 3]

pretty_table(data;column_labels)

save_folder="C:/Users/Batcomputr/Documents/GitHub/plots, mostly plots"

open(joinpath(save_folder,"test-table.txt"), write=true) do io
        pretty_table(io,data;column_labels)
    end

#oopsie