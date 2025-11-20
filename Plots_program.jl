using DataFrames
using CSV
using NativeFileDialog
using GLMakie
using NumericalIntegration


function single_plot_mode_selection()
    println("pick data file")
    single_file=pick_file()
    df=CSV.read(single_file,DataFrame)

    if names(df)[2] == "Frequency (Hz)"
        println("this is EIS")
        mode = "EIS"
    elseif names(df)[4] == "Scan"
        println("this is CV")
        mode = "CV"
    elseif names(df)[2] == "WE(1).Potential (V)" && df[!,5][1] >0
        println("this is C")
        mode = "C"
    elseif names(df)[2] == "WE(1).Potential (V)" && df[!,5][1] <0
        println("this is D")
        mode = "D"
    elseif names(df)[4] == "Index" && names(df)[5] == "WE(1).Potential (V)"
        println("this is I-V")
        mode = "I-V"
    else println("this type of data is not supported by this program *shrug emoji*")
    end
    return mode,single_file,df
end

single_plot_mode_selection()

function single_plot(clr)
    mode,single_file,df=single_plot_mode_selection()
    println("pick save folder")
    save_folder=pick_folder()

    Fig=Figure(size=(1500,500))

    if mode == "EIS"

        Axis_Nyquist=Axis(Fig[1,1],title="Nyquist",
        xlabel="Zre (Ω)", ylabel="Zimg (Ω)")

        Axis_Bode_Phase=Axis(Fig[1,2],title="Phase difference",
        xlabel="Frequency",ylabel="Phase difference (deg)",xscale=log10)

        Axis_Bode_Module=Axis(Fig[1,3],title="Module",
        xlabel="Frequency",ylabel="Z (Ω)",xscale=log10)


        idx_EIS=df."-Z'' (Ω)" .>0
        Zre=df."Z' (Ω)"[idx_EIS]
        Zimg=df."-Z'' (Ω)"[idx_EIS]
        Frequency=df."Frequency (Hz)"[idx_EIS]
        Z=df."Z (Ω)"[idx_EIS]
        Phase=df."-Phase (°)"[idx_EIS]

        plot_Nyquist=lines!(Axis_Nyquist,Zre,Zimg,
        label=basename(single_file),color=clr)

        DataInspector(plot_Nyquist)

        plot_Bode_Phase=lines!(Axis_Bode_Phase,Frequency,Phase,
        label=basename(single_file),color=clr)

        DataInspector(plot_Bode_Phase)

        plot_Bode_Module=lines!(Axis_Bode_Module,Frequency,Z,
        label=basename(single_file),color=clr)

        DataInspector(plot_Bode_Module)

        axislegend(position=:rt)

        display(GLMakie.Screen(),Fig)

        save(joinpath(save_folder,basename(single_file)*"_EIS.png"),Fig)
        
        #println(basename(single_file))
    elseif mode == "CV"

        idx_CV= df[!, :Scan] .==2
        Potential=df."WE(1).Potential (V)"[idx_CV]
        Current=df."WE(1).Current (A)"[idx_CV]
        push!(Potential,first(Potential))
        push!(Current,first(Current))

        Axis_CV=Axis(Fig[1,1],title=basename(single_file)*"_Cyclic Voltammetry",
        xlabel="Potential (V)",ylabel="Current (A)")

        plot_CV=lines!(Axis_CV,Potential,Current,
        label=basename(single_file),color=clr)

        axislegend(position=:rb)

        DataInspector(plot_CV)
        display(GLMakie.Screen(),Fig)

        save(joinpath(save_folder,basename(single_file)*"_CV.png"),Fig)

    elseif mode == "I-V"
        Current=df."WE(1).Current (A)"
        Potential=df."WE(1).Potential (V)"

        Axis_IV=Axis(Fig[1,1],title=basename(single_file)*"_I-V",
        xlabel="Potential (V)",ylabel="Current (A)")

        plot_IV=lines!(Axis_IV,Potential,Current,
        label=basename(single_file),color=clr)

        axislegend(position=:rb)

        DataInspector(plot_IV)
        display(GLMakie.Screen(),Fig)

        save(joinpath(save_folder,basename(single_file)*"_I-V.png"),Fig)

    elseif mode =="C" || mode =="D"
        Time=df."Corrected time (s)"
        Potential=df."WE(1).Potential (V)"

        if mode == "C"
            Axis_C=Axis(Fig[1,1],title=basename(single_file)*"_Charge",
            xlabel="Time (s)",ylabel="Potential (V)")

            plot_C=lines!(Axis_C,Time,Potential,
            label=basename(file),color=clr)
            
            axislegend(position=:rb)

            DataInspector(plot_C)
            display(GLMakie.Screen(),Fig)

        save(joinpath(save_folder,basename(single_file)*"_C.png"),Fig)
        
        elseif mode == "D"
            Axis_D=Axis(Fig[1,1],title=basename(single_file)*"_Discharge",
            xlabel="Time (s)",ylabel="Potential (V)")

            plot_D=lines!(Axis_D,Time,Potential,
            label=basename(single_file),color=clr)

            axislegend(potision=:rb)

            DataInspector(plot_D)
            display(GLMakie.Screen(),Fig)

        save(joinpath(save_folder,basename(single_file)*"_D.png"),Fig)
        end
    end
end

single_plot(:mediumorchid4)

# I need to make a separate step for charge and discharge at the same time
# either the two files are in the same figure or the two files are in the same graph or both

#fidget with the legend (me :laughing emoji) and try to iterate it, but make it a package first 

# now for the overlay I could do a brute force thing and
#just iterate the single version, but I'm not gonna do that....maybe :d
#I need the graph label though, so I probably shoud write a separate version
#with permutations which check whether it's the single option or the multiple version