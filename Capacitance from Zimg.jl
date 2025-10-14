using NativeFileDialog
using CSV
using DataFrames
using GLMakie
  
function pick_impedance_file()
    println("pick a Nyquist file")
    file=pick_file()

    df=CSV.read(file,DataFrame)
    filename=basename(file)

    frequency=df."Frequency (Hz)"
    Zr=df."Z' (Ω)"
    Zimg=df."-Z'' (Ω)"
    Z=df."Z (Ω)"

    return frequency,Zr,Zimg,Z,filename
end
    
function Capacitance_from_Zimg()
    frequency,Zr,Zimg,Z,filename=pick_impedance_file()

    C_img= 1 ./ (2*pi*frequency.*Zimg)

    lines(frequency,C_img,axis=(xscale=log10,))
    display(current_figure())
    DataInspector(current_figure())    
end

Capacitance_from_Zimg()