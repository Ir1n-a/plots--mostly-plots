using DataFrames
using NativeFileDialog
using NumericalIntegration
using GLMakie
using DataInterpolations
using CSV
using Statistics

function input_files_overlay(n)
    println("input the files you want, well, overlayed")

    file_vector=[]
    df_uri=[]
    vector_of_identity=[]

    for i in 1:n
        file=pick_file()
        push!(file_vector,file)
        df=CSV.read(file,DataFrame)
        push!(df_uri,df)

        # EIS = 1 CV = 2 C =3 D = 4 I-V = 5

        if names(df)[2] == "Frequency (Hz)"
            push!(vector_of_identity,1)

            elseif names(df)[4] == "Scan"
            push!(vector_of_identity,2)
        
            elseif names(df)[2] == "WE(1).Potential (V)" && df[!,5][1] >0
            push!(vector_of_identity,3)

            elseif names(df)[2] == "WE(1).Potential (V)" && df[!,5][1] <0
            push!(vector_of_identity,4)

            elseif names(df)[4] == "Index" && names(df)[5] == "WE(1).Potential (V)"
            push!(vector_of_identity,5)

            else println(raw"this type of data is not supported by this program ¯\_(ツ)_/¯ ")
        end
    end

    return file_vector,df_uri, vector_of_identity
end

input_files_overlay(3)

function overlay_graphs(n)
    file_vector,df_uri,vector_of_identity=input_files_overlay(n)

    for i in 1:n 
        if vector_of_identity[i] != vector_of_identity[1]
            error("the files must be of the same type 😋")
        end
    end

    println(" pick a save folder")
    save_folder=pick_folder()

    for j in 1:n

        df=df_uri[j]

        if vector_of_identity[1] == 1

            idx_EIS=df."-Z'' (Ω)" .>0
            Zre=df."Z' (Ω)"[idx_EIS]
            Zimg=df."-Z'' (Ω)"[idx_EIS]
            Frequency=df."Frequency (Hz)"[idx_EIS]
            Z=df."Z (Ω)"[idx_EIS]
            Phase=df."-Phase (°)"[idx_EIS]

            plot_Nyquist=lines(Zre,Zimg,axis=(title=basename(file_vector[j])*"_Nyquist",xlabel="Zre (Ω)",
            ylabel="Zimg (Ω)"))
            DataInspector(plot_Nyquist)
            display(GLMakie.Screen(),plot_Nyquist)

            save(joinpath(save_folder,basename(save_folder)*"_Nyquist.png"),plot_Nyquist)

            elseif vector_of_identity[1] == 2
            
            idx_CV= df[!, :Scan] .==2
            Potential=df."WE(1).Potential (V)"[idx_CV]
            Current=df."WE(1).Current (A)"[idx_CV]
            push!(Potential,first(Potential))
            push!(Current,first(Current))

            #plot

            elseif (vector_of_identity[1] == 3) || (vector_of_identity[1] == 4)

            Time=df."Corrected time (s)"
            Potential=df."WE(1).Potential (V)"

            #plot

            elseif vector_of_identity[1] == 5

            Current=df."WE(1).Current (A)"
            Potential=df."WE(1).Potential (V)"
        end
    end
end

overlay_graphs(2)
        
# use linear interpolation and define an axis and a figure for overlaying, oh and don't forget the legends

function define_dfs()
