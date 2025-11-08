using DataFrames
using NativeFileDialog
using GLMakie
using DataInterpolations
using CSV
using RegularizationTools

function import_file()
    file=pick_file()
    df=CSV.read(file,DataFrame)

    Current=df."WE(1).Current (A)"
    Potential=df."WE(1).Potential (V)"

    return Current,Potential,file
end

function the_graphs(d,λ)

    Current,Potential,file=import_file()

    Smooth_IV=RegularizationSmooth(Current,Potential,
    d;λ, alg=:fixed)

    F=Figure(size=(1000,500))

    maximum_Potential=round(last(Potential))
    maximum_Current=round(maximum(Current),digits=2)


    Potential_ticks=[0,0.2*maximum_Potential,0.4*maximum_Potential,0.6*maximum_Potential,0.8*maximum_Potential,maximum_Potential]
    Current_ticks=[0,0.2*maximum_Current,0.4*maximum_Current,0.6*maximum_Current,0.8*maximum_Current,maximum_Current]


    Axis_IV=Axis(F[1,1],title="I-V characteristic",
    xlabel="Potential (V)", ylabel="Current (A)",xticks=LinearTicks(10),
    yticks=LinearTicks(10))

    plot_IV=lines!(Axis_IV,range(first(Potential),last(Potential),length= 10*length(Potential)),
    x->Smooth_IV(x))

    #scatter!(Axis_IV,Potential,Current)

    DataInspector(plot_IV)


    Potential_range=range(first(Potential),last(Potential),length=10*length(Potential))

    Deriv_IV=DataInterpolations.derivative.((Smooth_IV,),Potential_range,1)

    maximum_Deriv_IV=round(maximum(Deriv_IV),digits=2)

    Deriv_IV_ticks=[0,0.2*maximum_Deriv_IV,0.4*maximum_Deriv_IV,0.6*maximum_Deriv_IV,0.8*maximum_Deriv_IV,maximum_Deriv_IV]

    Axis_Deriv_IV=Axis(F[1,2],title="dI/dV",xlabel="Potential (V)",
    ylabel="dI/dV (S)",xticks=LinearTicks(10),yticks=LinearTicks(10))

    plot_Deriv_IV=lines!(Axis_Deriv_IV,Potential_range,Deriv_IV)

    DataInspector(plot_Deriv_IV)

    display(F)

    save_folder=pick_folder()

    save(joinpath(save_folder,basename(file)*"_I-V graphs.png"),F)

    #now another figure for the derivative, dI/dV
end

the_graphs(2,0.002)