using DataFrames
using CSV
using NativeFileDialog
using GLMakie
using Statistics
using NumericalIntegration
using ColorSchemes

function overlay_graphs(mode,n,clr)

    Figure_EIS=Figure(size=(1500,500))
    Figure_CV=Figure(size=(600,400))
    Figure_CD=Figure(size=(600,400))

    files_vector=[]

    Axis_EIS_Nyquist=Axis(Figure_EIS[1,1],title="Nyquist",
    xlabel="Zre (Ω)", ylabel="Zimg (Ω)")
    Axis_EIS_Bode_Phase=Axis(Figure_EIS[1,2],title="Phase difference",
    xlabel="Frequency",ylabel="Phase difference (deg)",xscale=log10)
    Axis_EIS_Bode_Module=Axis(Figure_EIS[1,3],title="Module",
    xlabel="Frequency",ylabel="Z (Ω)",xscale=log10)

    Axis_CV=Axis(Figure_CV[1,1],title="_Cyclic Voltammetry",
    xlabel="Potential (V)",ylabel="Current (A)")

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

        axislegend(Axis_EIS_Nyquist,position=:rt)

        display(Figure_EIS)
        @show typeof(clr)
    end
end

overlay_graphs("EIS",9,:twilight)

nope .... it uses the default one only 
you need to make a vector of colors to iterate it, I suppose 

#also, smooth them a bit