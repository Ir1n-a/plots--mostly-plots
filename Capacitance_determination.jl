using NativeFileDialog
using CSV
using DataFrames
using GLMakie
using Statistics


function import_the_files()
    println("import said file, for a single Capacitor or series RCs")
    fl=pick_file()
    df=CSV.read(fl,DataFrame)
    
    f=df."Frequency (Hz)"
    Z=df."Z (Ω)"
    Zr=df."Z' (Ω)"
    Zimg=df."-Z'' (Ω)"
    filename=basename(fl)

    return f,Z,Zr,Zimg,filename
end

function determine_capacitance()
    f,Z,Zr,Zimg,filename=import_the_files()

    C_img= 1 ./ (2*pi*f.*Zimg)

    Fig=Figure()
    Ax=Axis(Fig[1,1])

    plot_capacitance=lines!(Ax,f,C_img)

   # axislegend("Capacitor",position=:lb)

    #axislegend(Axis,[plot_capacitance],[filename])

    println("pick a saving folder")
    folder=pick_folder()

    DataInspector(Fig)
    display(Fig)
    save(joinpath(folder,filename*"Capacitance_determination.png"),Fig)

    C_mean=mean(C_img)
    @show C_mean

end

determine_capacitance()
import_the_files()