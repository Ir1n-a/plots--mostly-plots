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
    
        if split(basename(file),".")[end] == "DS_Store"
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

    idx_EIS=df."-Z'' (Ω)" .>0
    Zre_NB=df."Z' (Ω)"[idx_EIS]
    Zimg_NB=df."-Z'' (Ω)"[idx_EIS]
    Frequency_NB=df."Frequency (Hz)"[idx_EIS]
    Z_NB=df."Z (Ω)"[idx_EIS]
    Phase_NB=df."-Phase (°)"[idx_EIS]

    return Zre_NB,Zimg_NB,Frequency_NB,Z_NB,Phase_NB
end


function actual_get_index(n,specific_value)
    specific_index=[]
    for i in eachindex(n)
        if n[i] == specific_value
            push!(specific_index,i)
        end
    end
    
    return specific_index
end

function get_parameters()
    #working parameters
    Potential_vectors,Current_vectors,Time_vectors,Frequencies_vector,
    Potential_amplitude_vector,Current_amplitude_vector,file_name_vector=input_files()

    #variables/vectors for checking the dc offset and for finding the phase difference
    offset=[]
    average_potential=[]
    time_delay=[]
    phase_difference=[]

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
        push!(phase_difference,2*π*only(Frequencies_vector[i])*only(time_delay[i]))
    end
    
    DataInspector(Fig)

    axislegend(position=:rt)

    display(Fig)
    @show offset 
    @show average_potential
    @show time_delay
    @show rad2deg.(phase_difference)
    @show Frequencies_vector
end

get_parameters()