using DataFrames
using CSV
using NativeFileDialog
using GLMakie
using Statistics
using NumericalIntegration
using ColorSchemes
using Colors

function overlay_graphs(mode,n,clr,scan_rate)

    Figure_EIS=Figure(size=(1500,500))
    Figure_CV=Figure(size=(1000,800))
    Figure_CD=Figure(size=(1000,800))
    Figure_CV_Cap=Figure(size=(1000,800))

    files_vector=[]

    Axis_EIS_Nyquist=Axis(Figure_EIS[1,1],title="Nyquist",
    xlabel="Zre (Ω)", ylabel="Zimg (Ω)")
    Axis_EIS_Bode_Phase=Axis(Figure_EIS[1,2],title="Phase difference",
    xlabel="Frequency",ylabel="Phase difference (deg)",xscale=log10)
    Axis_EIS_Bode_Module=Axis(Figure_EIS[1,3],title="Module",
    xlabel="Frequency",ylabel="Z (Ω)",xscale=log10)

    Axis_CV=Axis(Figure_CV[1,1],title="Cyclic Voltammetry",
    xlabel="Potential (V)",ylabel="Current (mA)",xticks=LinearTicks(10),
    yticks=LinearTicks(10))

    Axis_CV_Cap_Q1=Axis(Figure_CV_Cap[1,1],title="Q1 Capacitance",
    xlabel="Cycle iteration",ylabel="Capacitance (mF)",
    xticks=LinearTicks(9),yticks=LinearTicks(5))

    Axis_CV_Cap_Q2=Axis(Figure_CV_Cap[1,2],title="Q2 Capacitance",
    xlabel="Cycle iteration",ylabel="Capacitance (mF)",
    xticks=LinearTicks(9),yticks=LinearTicks(5))

    Axis_CV_Cap_Q3=Axis(Figure_CV_Cap[2,1],title="Q3 Capacitance",
    xlabel="Cycle iteration",ylabel="Capacitance (mF)",
    xticks=LinearTicks(9),yticks=LinearTicks(5))

    Axis_CV_Cap_Q4=Axis(Figure_CV_Cap[2,2],title="Q4 Capacitance",
    xlabel="Cycle iteration",ylabel="Capacitance (mF)",
    xticks=LinearTicks(9),yticks=LinearTicks(5))

    Axis_C=Axis(Figure_CD[1,1],title="Charge",
    xlabel="Time (s)",ylabel="Potential (V)")
    Axis_D=Axis(Figure_CD[1,2],title="Discharge",
    xlabel="Time (s)",ylabel="Potential (V)")

    Axis_C_Cap=Axis(Figure_CD[2,1],title="Charge Capacitance",
    xlabel="Cycle iteration",ylabel="Capacitance (mF)",xticks=LinearTicks(9),
    yticks=LinearTicks(5))
    Axis_D_Cap=Axis(Figure_CD[2,2],title="Discharge Capacitance",
    xlabel="Cycle iteration",ylabel="Capacitance (mF)",xticks=LinearTicks(9),
    yticks=LinearTicks(5))

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

        Figure_EIS[3,2]=Legend(Figure_EIS,Axis_EIS_Bode_Phase,orientation=:horizontal)
        Figure_EIS[2,2]=Legend(Figure_EIS,Axis_EIS_Nyquist,orientation=:horizontal)
        Figure_EIS[4,2]=Legend(Figure_EIS,Axis_EIS_Bode_Module,orientation=:horizontal)
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

            plot_CV=lines!(Axis_CV,Potential,Current*1000,
            label=basename(file),linewidth=2,color=color_i)

            idx_q1=(Potential .* Current .> 0) .&& (Potential .> 0)
            idx_q2=(Potential .* Current .< 0) .&& (Potential .> 0)
            idx_q3=(Potential .* Current .> 0) .&& (Potential .< 0)
            idx_q4=(Potential .* Current .< 0) .&& (Potential .< 0)
            
            Integral_Q1=integrate(Potential[idx_q1],Current[idx_q1])
            Capacitance_CV_Q1=Integral_Q1/(maximum(Potential[idx_q1])*scan_rate)
            
            Integral_Q2=integrate(Potential[idx_q2],Current[idx_q2])
            Capacitance_CV_Q2=Integral_Q2/(maximum(Potential[idx_q2])*scan_rate)
            
            Integral_Q3=integrate(Potential[idx_q3],Current[idx_q3])
            Capacitance_CV_Q3=Integral_Q3/(maximum(abs.(Potential[idx_q3]))*scan_rate)

            Integral_Q4=integrate(Potential[idx_q4],Current[idx_q4])
            Capacitance_CV_Q4=Integral_Q4/(maximum(abs.(Potential[idx_q4]))*scan_rate)

            q1=scatter!(Axis_CV_Cap_Q1,i,Capacitance_CV_Q1*1000,
            color=color_i,markersize=20,label=basename(file))
            q2=scatter!(Axis_CV_Cap_Q2,i,Capacitance_CV_Q2*1000,
            color=color_i,markersize=20,label=basename(file))
            q3=scatter!(Axis_CV_Cap_Q3,i,Capacitance_CV_Q3*1000,
            color=color_i,markersize=20,label=basename(file))
            q4=scatter!(Axis_CV_Cap_Q4,i,Capacitance_CV_Q4*1000,
            color=color_i,markersize=20,label=basename(file))

        end

        Figure_CV[2,1]=Legend(Figure_CV,Axis_CV,orientation=:horizontal,tellwidth=true)
        Figure_CV_Cap[3,1:2]=Legend(Figure_CV_Cap,Axis_CV_Cap_Q3,orientation=:horizontal)

        DataInspector(Figure_CV)
        DataInspector(Figure_CV_Cap)

        display(GLMakie.Screen(),Figure_CV)
        display(GLMakie.Screen(),Figure_CV_Cap)

        save_folder=pick_folder()

        save(joinpath(save_folder,basename(save_folder)*"_CV.png"),Figure_CV)
        save(joinpath(save_folder,basename(save_folder)*"CV_Cap.png"),Figure_CV_Cap)

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

            Charging_Current=df."WE(1).Current (A)"

            color_i=_cmap[i]

            plot_C=lines!(Axis_C,Time,Potential,
            label=basename(file),linewidth=2,color=color_i)

            Total_Charging_Time=maximum(Time)
            Integral_Charging_Potential=integrate(Time,Potential)
            Average_Charging_Current=mean(Charging_Current)
            Maximum_Charging_Potential=maximum(Potential)

            Capacitance_Charging=(2*abs(Average_Charging_Current)*Integral_Charging_Potential)/
            (Maximum_Charging_Potential^2)

            plot_C_Cap=scatter!(Axis_C_Cap,i,Capacitance_Charging*1000
            ,color=color_i,markersize=20)
        end

        println("pick the discharging files")

        for j in 1:n
            file=pick_file()
            push!(files_vector,file)
            df=CSV.read(file,DataFrame)

            Time=df."Corrected time (s)"
            Potential=df."WE(1).Potential (V)"

            Discharging_Current=df."WE(1).Current (A)"

            Integral_Discharging_Potential=integrate(Time,Potential)
            Average_Discharging_Current=mean(Discharging_Current)
            Maximum_Discharging_Potential=maximum(Potential)

            color_j=_cmap[j]

            plot_D=lines!(Axis_D,Time,Potential,
            label=basename(file),linewidth=2,color=color_j)

            Capacitance_Discharging=(2*abs(Average_Discharging_Current)*Integral_Discharging_Potential)/
            (Maximum_Discharging_Potential^2)

            plot_D_Cap=scatter!(Axis_D_Cap,j,Capacitance_Discharging*1000,
            color=color_j,markersize=20)

        end

        Figure_CD[3,1:2]=Legend(Figure_CD,Axis_C,orientation=:horizontal)

        DataInspector(Figure_CD)

        display(Figure_CD)

        save_folder=pick_folder()

        save(joinpath(save_folder,basename(save_folder)*"_CD.png"),Figure_CD)



    end
end

overlay_graphs("CV",8,:twilight,0.1)

nope .... it uses the default one only 
you need to make a vector of colors to iterate it, I suppose 

#also, smooth them a bit