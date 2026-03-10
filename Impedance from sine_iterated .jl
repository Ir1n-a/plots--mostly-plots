using NativeFileDialog
using DataInterpolations
using CSV
using GLMakie
using DataFrames
using RegularizationTools
using Statistics

function input_files()
    F=pick_folder()
    file_name_vector=[]

    #data vectors
    Potential_vectors=[]
    Current_vectors=[]
    Time_vectors=[]
    df_uri=[]
    
    #vectors for sine formula
    Frequencies_vector=[]
    Potential_amplitude_vector=[]
    Current_amplitude_vector=[]

    for file in readdir(F,join=true)
    
        if split(basename(file),".")[end] == "DS_Store" || basename(file) == "EIS"
            continue 
        else

        df=CSV.read(file,DataFrame)
            push!(df_uri,df)

        #Period_index
        Period=1/df."Frequency (Hz)"[1]
        id=df."Time domain (s)" .<= Period

        #data vectors
        push!(Potential_vectors,df."Potential (AC) (V)"[id])
        push!(Current_vectors,df."Current (AC) (A)"[id])
        push!(Time_vectors,df."Time domain (s)"[id])
        push!(file_name_vector,basename(file))

        #vectors for sine formula
        push!(Frequencies_vector,df."Frequency (Hz)"[1])
        push!(Potential_amplitude_vector,maximum(df."Potential (AC) (V)"[id]))
        push!(Current_amplitude_vector,maximum(df."Current (AC) (A)"[id]))
        #also the Time_vector, remember that 

        end
    end

    
    return Potential_vectors,Current_vectors,Time_vectors,Frequencies_vector,
    Potential_amplitude_vector,Current_amplitude_vector,file_name_vector
end

input_files()

#stage for inputing the impedance files given by the apparatus 

function input_NyquistBode_files()
    file_Nyquist=pick_file()
    df=CSV.read(file_Nyquist,DataFrame)

    idx=df."Index"

    for i in 1:length(idx)-1
        if df."-Z'' (Ω)"[i] <0 || (df."Z' (Ω)"[i] > df."Z' (Ω)"[i+1])
            deleteat!(idx,i)
        end
    end

    Zre_NB=df."Z' (Ω)"[idx]
    Zimg_NB=df."-Z'' (Ω)"[idx]
    Frequency_NB=df."Frequency (Hz)"[idx]
    Z_NB=df."Z (Ω)"[idx]
    Phase_NB=df."-Phase (°)"[idx]
    filename_EIS=basename(file_Nyquist)

    println(df)

    return Zre_NB,Zimg_NB,Frequency_NB,Z_NB,Phase_NB,filename_EIS
end

#function for finding the index of a set value in a vector

function actual_get_index(n,specific_value)
    specific_index=[]
    for i in eachindex(n)
        if n[i] == specific_value
            push!(specific_index,i)
        end
    end
    
    return specific_index
end

function get_parameters(EIS_too)
    #working parameters
    Potential_vectors,Current_vectors,Time_vectors,Frequencies_vector,
    Potential_amplitude_vector,Current_amplitude_vector,file_name_vector=input_files()

    #variables/vectors for checking the dc offset and for finding the phase difference
    offset=[]
    average_potential=[]
    time_delay=[]
    phase_difference=[]
    ϕ=[]

    #plots axes
    Fig=Figure()
    Axis_Potential=Axis(Fig[1,1],title="Potential_data",xlabel="Time (s)",
    ylabel="Potential (V)")
    Axis_Current=Axis(Fig[1,2],title="Current_data",xlabel="Time (s)",
    ylabel="Current (A)")

    for i in eachindex(Frequencies_vector)

        lines!(Axis_Potential,Time_vectors[i],Potential_vectors[i],
        label=string(Frequencies_vector[i])*" Hz")

        lines!(Axis_Current,Time_vectors[i],Current_vectors[i],
        label=string(Frequencies_vector[i])*" Hz")

        push!(offset,maximum(Potential_vectors[i])+minimum(Potential_vectors[i]))
        push!(average_potential,mean(Potential_vectors[i]))

        idx_maximum_current=actual_get_index(Current_vectors[i],maximum(Current_vectors[i]))
        idx_maximum_potential=actual_get_index(Potential_vectors[i],maximum(Potential_vectors[i]))
        
        push!(time_delay,Time_vectors[i][idx_maximum_potential]-Time_vectors[i][idx_maximum_current])
        push!(phase_difference,rad2deg(2*π*only(Frequencies_vector[i])*only(time_delay[i])))
    end

    for i in eachindex(phase_difference)
        if phase_difference[i] < -180
            phase_difference[i]=phase_difference[i] + 360
        elseif phase_difference[i] > 180 
            phase_difference[i]=phase_difference[i] - 360
        else continue
        end
    end
    
    DataInspector(Fig)

    axislegend(position=:rt)

    
    V_t=[]
    I_t=[]
    
    for i in eachindex(Potential_amplitude_vector)
        V=Potential_amplitude_vector[i]  .* sin.(2*π.*Frequencies_vector[i] .*Time_vectors[i])
        
        I=Current_amplitude_vector[i] .* sin.(2*π.*Frequencies_vector[i] .*Time_vectors[i] .+ phase_difference[i])
        
        push!(V_t,V)
        push!(I_t,I)

        lines!(Axis_Potential,Time_vectors[i],V_t[i])
        lines!(Axis_Current,Time_vectors[i],I_t[i])
    end

    display(Fig)
    @show V_t

    if (EIS_too)
        Zre_NB,Zimg_NB,Frequency_NB,Z_NB,Phase_NB,filename_EIS=input_NyquistBode_files()
    end

#plot axes for Nyquist and Bode plots

Fig_NB=Figure()
Axis_Nyquist=Axis(Fig_NB[1,1],title="Nyquist",
xlabel="Zre (Ω)",ylabel="Zimg (Ω)")
Axis_Bode_Phase=Axis(Fig_NB[1,2],title="Phase difference",
xlabel="Freqency (Hz)",ylabel="Phase difference (deg)",xscale=log10)
Axis_Bode_Module=Axis(Fig_NB[1,3],title="Module",
xlabel="Frequency (Hz)",ylabel="Z (Ω)",xscale=log10)

plot_Nyquist=lines!(Axis_Nyquist,Zre_NB,Zimg_NB,label=filename_EIS)
plot_Bode_Phase=lines!(Axis_Bode_Phase,Frequency_NB,Phase_NB)
plot_Bode_Module=lines!(Axis_Bode_Module,Frequency_NB,Z_NB)

DataInspector(plot_Nyquist)
DataInspector(plot_Bode_Phase)
DataInspector(plot_Bode_Module)


display(Fig_NB)
end

get_parameters(true)


#phase difference close, but not quite exactly, to be determined if an averaging is needed, if the difference is troublesome enough 