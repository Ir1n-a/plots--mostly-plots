using DataFrames
using CSV
using NativeFileDialog
using GLMakie
using Statistics
using NumericalIntegration
using ColorSchemes
using Colors

function overlay_graphs(mode,n,clr)

    Figure_EIS=Figure(size=(1500,500))
    Figure_CV=Figure(size=(1000,800))
    Figure_CD=Figure(size=(1000,500))

    files_vector=[]

    Axis_EIS_Nyquist=Axis(Figure_EIS[1,1],title="Nyquist",
    xlabel="Zre (Ω)", ylabel="Zimg (Ω)")
    Axis_EIS_Bode_Phase=Axis(Figure_EIS[1,2],title="Phase difference",
    xlabel="Frequency",ylabel="Phase difference (deg)",xscale=log10)
    Axis_EIS_Bode_Module=Axis(Figure_EIS[1,3],title="Module",
    xlabel="Frequency",ylabel="Z (Ω)",xscale=log10)

    Axis_CV=Axis(Figure_CV[1,1],title="_Cyclic Voltammetry",
    xlabel="Potential (V)",ylabel="Current (A)",xticks=LinearTicks(10),
    yticks=LinearTicks(10))

    Axis_C=Axis(Figure_CD[1,1],title="Charge",
    xlabel="Time (s)",ylabel="Potential (V)")
    Axis_D=Axis(Figure_CD[1,2],title="Discharge",
    xlabel="Time (s)",ylabel="Potential (V)")

    cmap=cgrad(clr, n+3; categorical=true,rev=true)
    _cmap=collect(cmap)
    deleteat!(_cmap, 5)
    deleteat!(_cmap,6)


    println("pick the files you want, preferably of the same measurement")
        
    if mode == "EIS"
        for i in 1:n
            file=pick_file()
            push!(files_vector,file)
            df=CSV.read(file,DataFrame)

            idx_EIS=df."-Z'' (Ω)" .>0
            Zre=df."Z' (Ω)"[idx_EIS]
            Zimg=df."-Z'' (Ω)"[idx_EIS]
            Frequency=df."Frequency (Hz)"[idx_EIS]
            Z=df."Z (Ω)"[idx_EIS]
            Phase=df."-Phase (°)"[idx_EIS]

            color_i=_cmap[i]

            plot_Nyquist=lines!(Axis_EIS_Nyquist,Zre,Zimg,
            label=basename(file),linewidth=3,color=color_i)
            plot_Bode_Phase=lines!(Axis_EIS_Bode_Phase,Frequency,Phase,
            label=basename(file),linewidth=3,color=color_i)
            plot_Bode_Module=lines!(Axis_EIS_Bode_Module,Frequency,Z,
            label=basename(file),linewidth=3,color=color_i)

            
        end

        Figure_EIS[2,2]=Legend(Figure_EIS,Axis_EIS_Nyquist,orientation=:horizontal)
        #f[1, 2] = Legend(f, ax, "Trig Functions", framevisible = false)

        #axislegend(Axis_EIS_Nyquist,position=:ct,orientation=:horizontal)

        DataInspector(Figure_EIS)

        display(Figure_EIS)

        save_folder=pick_folder()
        save(joinpath(save_folder,basename(save_folder)*"_EIS.png"),Figure_EIS)

    elseif mode == "CV"
        for i in 1:n
            file=pick_file()
            push!(files_vector,file)
            df=CSV.read(file,DataFrame)

            idx_CV= df[!, :Scan] .==2
            Potential=df."WE(1).Potential (V)"[idx_CV]
            Current=df."WE(1).Current (A)"[idx_CV]
            push!(Potential,first(Potential))
            push!(Current,first(Current))

            color_i=_cmap[i]

            plot_CV=lines!(Axis_CV,Potential,Current,
            label=basename(file),linewidth=2,color=color_i)
        end

        Figure_CV[2,1]=Legend(Figure_CV,Axis_CV,orientation=:horizontal,tailwidth=true)

        DataInspector(Figure_CV)

        display(Figure_CV)

        save_folder=pick_folder()

        save(joinpath(save_folder,basename(save_folder)*"_CV.png"),Figure_CV)

    elseif mode == "C" || mode == "D"

        #remember, this does both C and D, if you want them separate (you as in me), wait for the other program
        #as in work on the other program, me, I mean, you are working on it, but you know what I (you) mean

        println("pick the charging files")

        for i in 1:n 
            file=pick_file()
            push!(files_vector,file)
            df=CSV.read(file,DataFrame)

            Time=df."Corrected time (s)"
            Potential=df."WE(1).Potential (V)"

            color_i=_cmap[i]

            plot_C=lines!(Axis_C,Time,Potential,
            label=basename(file),linewidth=2,color=color_i)
        end

        println("pick the discharging files")

        for j in 1:n
            file=pick_file()
            push!(files_vector,file)
            df=CSV.read(file,DataFrame)

            Time=df."Corrected time (s)"
            Potential=df."WE(1).Potential (V)"

            color_j=_cmap[j]

            plot_D=lines!(Axis_D,Time,Potential,
            label=basename(file),linewidth=2,color=color_j)

        end

        Figure_CD[2,1:2]=Legend(Figure_CD,Axis_C,orientation=:horizontal)

        DataInspector(Figure_CD)

        display(Figure_CD)

        save_folder=pick_folder()

        save(joinpath(save_folder,basename(save_folder)*"_CD.png"),Figure_CD)



    end
end

overlay_graphs("C",9,:twilight)

nope .... it uses the default one only 
you need to make a vector of colors to iterate it, I suppose 

#also, smooth them a bit