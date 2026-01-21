using NativeFileDialog
using DataInterpolations
using CSV
using GLMakie
using DataFrames

function input_signals()
    F=pick_folder()
    df_uri=[]
    Frequency_sort=[]
    Frequency_push=[]
    file_name=[]

    for file in readdir(F,join=true)
        if split(basename(file),".")[end] == "DS_Store"
            continue 
        else
            
            df=CSV.read(file,DataFrame,delim=";")
            push!(df_uri,df)

            #Frequency=df."Frequency (Hz)"[1] I swear it worked, there was something weird here 😭
            push!(Frequency_push,df."Frequency (Hz)"[1])
            push!(file_name,basename(file))

        end

        
        
    end
    
    Frequency_sort=sort(Frequency_push)
    @show Frequency_sort
    #@show file_name(index(Frequency))

end

input_signals()

pick_folder()