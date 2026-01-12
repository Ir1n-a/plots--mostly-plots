using DataFrames
using GLMakie
using Statistics
using CSV
using NativeFileDialog

function import_the_file()
    file=pick_file()
    df=CSV.read(file,DataFrame)

    idx_EIS=df."-Z'' (Ω)" .>0
    Zre=df."Z' (Ω)"[idx_EIS]
    Zimg=df."-Z'' (Ω)"[idx_EIS]
    Frequency=df."Frequency (Hz)"[idx_EIS]
    Z=df."Z (Ω)"[idx_EIS]
    Phase=df."-Phase (°)"[idx_EIS]

    return Zre,Zimg,Frequency,Z,Phase
end

#basically what I'm trying to test with this program is if the engineer strategy can lead to an encompassing circuit model 
#and what I mean by that if there are common parameter values if every single point is treated as one single resistance 
#and one single capacitor, yeah, it's clear enough, right ? me? 😅

function try_parameters_out(n)

    Zre_=[]
    Zimg_=[]
    Frequency_=[]
    Z_=[]
    Phase_=[]
    C=[]
    R=[]

    Fig=Figure(size=(600,400))

    Axis_Bode_Phase=Axis(Fig[1,1],title="Phase difference",
    xlabel="Frequency (Hz)",ylabel="Phase difference (deg)",xscale=log10)

    Axis_C=Axis(Fig[1,2],title="Capacitor",
    xlabel="Frequency (Hz)",ylabel="Capacitance",xscale=log10)

    Axis_R=Axis(Fig[1,3],title="Resistor",
    xlabel="Frequency (Hz)",ylabel="Resistance",xscale=log10)

    for i in 1:n
        Zre,Zimg,Frequency,Z,Phase=import_the_file()
        push!(Zre_,Zre)
        push!(Zimg_,Zimg)
        push!(Frequency_,Frequency)
        push!(Z_,Z)
        push!(Phase_,Phase)

        plot_Bode=lines!(Axis_Bode_Phase,Frequency,Phase)

        C= 1 ./ (2*pi*Frequency.*Zimg)
        R=Zre
        @show C 
        @show R

        plot_C=lines!(Axis_C,Frequency,C)
        plot_R=lines!(Axis_R,Frequency,R)

    end

    DataInspector(Fig)

    display(GLMakie.Screen(),Fig)

    @show Phase_
end


try_parameters_out(2)

#noise still needs removed no matter what