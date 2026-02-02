using NativeFileDialog
using DataInterpolations
using CSV
using GLMakie
using DataFrames
using RegularizationTools

function input_signals(freq_idx)
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

            Period=1/df."Frequency (Hz)"[1]
            id=df."Time domain (s)" .<= Period

            push!(Potential_vectors,df."Potential (AC) (V)"[id])
            push!(Current_vectors,df."Current (AC) (A)"[id])
            push!(Time_vectors,df."Time domain (s)"[id])

        end

    end

    idx_p=sortperm(Frequency_push)


    #for i in eachindex()

    #@show Frequency_push[idx_p]
    #@show file_name[idx_p]
    #@show Potential_vectors[80]

    Fig=Figure()

    Ax=Axis(Fig[1,1])
    Ax_tew=Axis(Fig[1,2])

    Smooth_Potential=RegularizationSmooth(Potential_vectors[freq_idx],Time_vectors[freq_idx], alg= :gcv_svd)
    Smooth_Current=RegularizationSmooth(Current_vectors[freq_idx],Time_vectors[freq_idx], alg=:gcv_svd)

    Smooth_Potential(first(Time_vectors[freq_idx]))

    #=plot_Nyquist=lines(range(first(Zre),last(Zre),length= 10*length(Zre)),
    x->Smooth_Nyquist(x),axis=(xlabel="Zre (Ω)",ylabel="Zimg (Ω)",title=
    "Nyquist"))=#

    #Potential_interpolation=SmoothedConstantInterpolation(Potential_vectors[70],Time_vectors[70],d_max=10)
    #Current_interpolation=SmoothedConstantInterpolation(Current_vectors[70],Time_vectors[70],d_max=10)

    lines!(Ax,range(first(Time_vectors[freq_idx]),last(Time_vectors[freq_idx]),length=10*length(Time_vectors[freq_idx])),
    x->Smooth_Potential(x))
    lines!(Ax_tew,range(first(Time_vectors[freq_idx]),last(Time_vectors[freq_idx]),length=10*length(Time_vectors[freq_idx])),
    x->Smooth_Current(x))

    display(Fig)

    DataInspector(Fig)


    issorted(Frequency_push[idx_p])
    #@show Frequency_push[idx_p][34]
    @show Frequency_push[freq_idx]

end

input_signals(70)

#try other interpolation methods
#calculate impedance
#use only one full cycle for each frequency, for the higher frequencies show many more cycles than the lower frequencies