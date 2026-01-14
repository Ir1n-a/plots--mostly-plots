using NativeFileDialog
using DataInterpolations
using CSV
using GLMakie
using DataFrames

function input_signals()
    F=pick_folder()
    df_uri=[]
    Frequency=[]
    Frequency_push=[]
    file_name=[]

    for file in readdir(F,join=true)
        df=CSV.read(file,DataFrame;delim= ";")
        push!(df_uri,df)

        Frequency=df."Frequency (Hz)"[1]
        #push!(Frequency_push,df."Frequency (Hz)"[1])
        push!(file_name,basename(file))
        

    end
   
    @show Frequency
    #@show file_name(index(Frequency))

end

input_signals()

pick_folder()