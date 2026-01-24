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
    Potential_vectors=[]
    Current_vectors=[]
    Time_vectors=[]
    Z=[]

    for file in readdir(F,join=true)
        if split(basename(file),".")[end] == "DS_Store"
            continue 
        else
            
            df=CSV.read(file,DataFrame)
            push!(df_uri,df)

            #Frequency=df."Frequency (Hz)"[1] I swear it worked, there was something weird here 😭
            push!(Frequency_push,df."Frequency (Hz)"[1])
            push!(file_name,basename(file))
            push!(Potential_vectors,df."Potential (AC) (V)")
            push!(Current_vectors,df."Current (AC) (A)")
            push!(Time_vectors,df."Time domain (s)")

        end

    end

    idx_p=sortperm(Frequency_push)

    #@show Frequency_push[idx_p]
    #@show file_name[idx_p]
    #@show Potential_vectors[80]

    Fig=Figure()

    Ax=Axis(Fig[1,1])
    Ax_tew=Axis(Fig[1,2])

    Potential_interpolation=LinearInterpolation(Potential_vectors[70],Time_vectors[70])
    Current_interpolation=LinearInterpolation(Current_vectors[70],Time_vectors[70])

    lines!(Ax,Potential_interpolation)
    lines!(Ax_tew,Current_interpolation)

    display(Fig)

    DataInspector(Fig)


    issorted(Frequency_push[idx_p])
    #@show Frequency_push[idx_p][34]
    @show Z

end

input_signals()

#try other interpolation methods
#calculate impedance
#use only one full cycle for each frequency, for the higher frequencies show many more cycles than the lower frequencies