using NativeFileDialog
using DataInterpolations
using CSV
using GLMakie
using DataFrames
using RegularizationTools

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

function get_parameters()
    #working parameters
    Potential_vectors,Current_vectors,Time_vectors,Frequencies_vector,
    Potential_amplitude_vector,Current_amplitude_vector,file_name_vector=input_files()

    #plots axes
    Fig=Figure()
    Axis_Potential=Axis(Fig[1,1],title="Potential_data",xlabel="Time (s)",
    ylabel="Potential (V)")
    Axis_Current=Axis(Fig[1,2],title="Current_data",xlabel="Time (s)",
    ylabel="Current (A)")

    for i in eachindex(Frequencies_vector)

        lines!(Axis_Potential,Time_vectors[i],Potential_vectors[i])
        lines!(Axis_Current,Time_vectors[i],Current_vectors[i])
    end

    display(Fig)
end

get_parameters()