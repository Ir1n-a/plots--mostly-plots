using DataFrames
using CSV
using NativeFileDialog
using GLMakie
using NumericalIntegration
using Statistics


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

function charge_N_discharge(clr_c,clr_d)

    file=[]
    df=[]
    file_vector=[]
    filename_vector=[]

    println("these files are in a pair, so don't get lost when counting them")
    for i in 1:2 
        file=pick_file()
        push!(file_vector,file)
        push!(df,CSV.read(file,DataFrame))
        push!(filename_vector,basename(file))
    end

    #charging parameters from df
    
    Charging_Time=df[1]."Corrected time (s)"
    Charging_Potential=df[1]."WE(1).Potential (V)"
    Charging_Current=df[1]."WE(1).Current (A)"

    #charging parameters for capacitance calculation 

    Total_Charging_Time=maximum(Charging_Time)
    Integral_Charging_Potential=integrate(Charging_Time,Charging_Potential)
    Average_Charging_Current=mean(Charging_Current)
    Maximum_Charging_Potential=maximum(Charging_Potential)

    #capacitance calculation from the charging curve

    Capacitance_Charging=(2*abs(Average_Charging_Current)*Integral_Charging_Potential)/
    (Maximum_Charging_Potential^2)

    #discharging parameters from df

    Discharging_Time=df[2]."Corrected time (s)"
    Discharging_Potential=df[2]."WE(1).Potential (V)"
    Discharging_Current=df[2]."WE(1).Current (A)"

    #discharging parameters for capacitance calculation

    Total_Discharging_Time=maximum(Discharging_Time)
    Integral_Discharging_Potential=integrate(Discharging_Time,Discharging_Potential)
    Average_Discharging_Current=mean(Discharging_Current)
    Maximum_Discharging_Potential=maximum(Discharging_Potential)

    #capacitance calculation from the discharging curve

    Capacitance_Discharging=(2*abs(Average_Discharging_Current)*Integral_Discharging_Potential)/
    (Maximum_Discharging_Potential^2)

    Capacitance_Ratio=Capacitance_Charging/Capacitance_Discharging
    Capacitance_Difference=Capacitance_Charging - Capacitance_Discharging  

    CD_Figure=Figure(size=(600,400))
    
    Axis_CD=Axis(CD_Figure[1,1],title="Charge and Discharge",
    xlabel="Time (s)",ylabel="Potential (V)")

    plot_C=lines!(Axis_CD,Charging_Time,Charging_Potential,
    label=basename(filename_vector[1]),color=clr_c)

    DataInspector(plot_C)

   Discharging_Time_Plots=Discharging_Time .+ maximum(Charging_Time)

    plot_D=lines!(Axis_CD,Discharging_Time_Plots,Discharging_Potential,
    label=basename(filename_vector[2]),color=clr_d)

    DataInspector(plot_D)
    
    axislegend(position=:rt)

    display(GLMakie.Screen(),CD_Figure)

    println("pick a save folder")
    save_folder=pick_folder()

    save(joinpath(save_folder,basename(filename_vector[1])*"_"*
    basename(filename_vector[2])*"_CD.png"),CD_Figure)
    
end

charge_N_discharge(:darkred,:mediumpurple4)




single_plot(:mediumorchid4)

# I need to make a separate step for charge and discharge at the same time
# either the two files are in the same figure or the two files are in the same graph or both

#fidget with the legend (me :laughing emoji) and try to iterate it, but make it a package first 

# now for the overlay I could do a brute force thing and
#just iterate the single version, but I'm not gonna do that....maybe :d
#I need the graph label though, so I probably shoud write a separate version
#with permutations which check whether it's the single option or the multiple version